"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrdersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const enums_1 = require("../common/enums");
const customer_entity_1 = require("../database/entities/customer.entity");
const dining_table_entity_1 = require("../database/entities/dining-table.entity");
const order_item_entity_1 = require("../database/entities/order-item.entity");
const payment_entity_1 = require("../database/entities/payment.entity");
const product_entity_1 = require("../database/entities/product.entity");
const restaurant_order_entity_1 = require("../database/entities/restaurant-order.entity");
const user_entity_1 = require("../database/entities/user.entity");
const ACTIVE_STATUSES = [
    enums_1.OrderWorkflowStatus.PLACED,
    enums_1.OrderWorkflowStatus.PREPARING,
    enums_1.OrderWorkflowStatus.READY,
    enums_1.OrderWorkflowStatus.SERVED,
];
const KITCHEN_STATUSES = [
    enums_1.OrderWorkflowStatus.PLACED,
    enums_1.OrderWorkflowStatus.PREPARING,
    enums_1.OrderWorkflowStatus.READY,
];
const TERMINAL_STATUSES = [
    enums_1.OrderWorkflowStatus.PAID,
    enums_1.OrderWorkflowStatus.CANCELLED,
];
let OrdersService = class OrdersService {
    orders;
    orderItems;
    payments;
    products;
    tables;
    customers;
    users;
    constructor(orders, orderItems, payments, products, tables, customers, users) {
        this.orders = orders;
        this.orderItems = orderItems;
        this.payments = payments;
        this.products = products;
        this.tables = tables;
        this.customers = customers;
        this.users = users;
    }
    assertOrderAccess(order, scopeUserId) {
        if (!scopeUserId)
            return;
        const creatorId = order.createdBy?.id;
        if (!creatorId || creatorId !== scopeUserId) {
            throw new common_1.NotFoundException('Commande introuvable');
        }
    }
    computeTotals(order) {
        const items = order.items ?? [];
        const pays = order.payments ?? [];
        let subtotal = 0;
        for (const line of items) {
            subtotal += Number(line.quantity) * Number(line.unitPrice);
        }
        let paid = 0;
        for (const p of pays) {
            paid += Number(p.amount);
        }
        const due = Math.max(0, Math.round((subtotal - paid) * 100) / 100);
        return { subtotal, paid, due };
    }
    serialize(order) {
        const { subtotal, paid, due } = this.computeTotals(order);
        return {
            id: order.id,
            orderNumber: order.orderNumber,
            serviceType: order.serviceType,
            status: order.status,
            notes: order.notes,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt,
            diningTable: order.diningTable
                ? { id: order.diningTable.id, number: order.diningTable.number }
                : null,
            customer: order.customer
                ? {
                    id: order.customer.id,
                    name: order.customer.name,
                    phone: order.customer.phone ?? '',
                }
                : null,
            items: (order.items ?? []).map((line) => ({
                id: line.id,
                quantity: line.quantity,
                unitPrice: line.unitPrice,
                productNameSnapshot: line.productNameSnapshot,
                product: line.product
                    ? {
                        id: line.product.id,
                        name: line.product.name,
                        nameAr: line.product.nameAr ?? null,
                        price: line.product.price,
                    }
                    : null,
            })),
            payments: (order.payments ?? []).map((p) => ({
                id: p.id,
                amount: p.amount,
                method: p.method,
                reference: p.reference,
                createdAt: p.createdAt,
            })),
            totals: {
                subtotal: subtotal.toFixed(2),
                paid: paid.toFixed(2),
                due: due.toFixed(2),
            },
        };
    }
    async refreshTableStatus(tableId) {
        if (!tableId)
            return;
        const activeCount = await this.orders.count({
            where: {
                diningTable: { id: tableId },
                status: (0, typeorm_2.In)(ACTIVE_STATUSES),
            },
        });
        const table = await this.tables.findOne({ where: { id: tableId } });
        if (!table)
            return;
        table.status = activeCount > 0 ? enums_1.TableStatus.OCCUPIED : enums_1.TableStatus.FREE;
        await this.tables.save(table);
    }
    async buildLinesFromInput(inputs) {
        const merged = new Map();
        for (const row of inputs) {
            merged.set(row.productId, (merged.get(row.productId) ?? 0) + row.quantity);
        }
        const lines = [];
        for (const [productId, quantity] of merged.entries()) {
            const product = await this.products.findOne({
                where: { id: productId },
            });
            if (!product) {
                throw new common_1.NotFoundException(`Produit introuvable (${productId})`);
            }
            if (!product.isAvailable) {
                throw new common_1.BadRequestException(`Produit indisponible : ${product.name}`);
            }
            const unit = Number(product.price).toFixed(2);
            lines.push(this.orderItems.create({
                product,
                quantity,
                unitPrice: unit,
                productNameSnapshot: product.name,
            }));
        }
        return lines;
    }
    async applyStockDelta(lines, direction) {
        if (!lines || lines.length === 0)
            return;
        const ids = Array.from(new Set(lines.map((l) => l.productId)));
        if (ids.length === 0)
            return;
        const rows = await this.products
            .createQueryBuilder('p')
            .where('p.id IN (:...ids)', { ids })
            .getMany();
        const byId = new Map(rows.map((r) => [r.id, r]));
        const updates = [];
        for (const line of lines) {
            const p = byId.get(line.productId);
            if (!p)
                continue;
            if (p.stockQuantity === null || p.stockQuantity === undefined)
                continue;
            const sign = direction === 'consume' ? -1 : +1;
            p.stockQuantity = p.stockQuantity + sign * line.quantity;
            updates.push(p);
        }
        if (updates.length > 0) {
            await this.products.save(updates);
        }
    }
    async create(dto, createdById) {
        let diningTable = null;
        if (dto.diningTableId) {
            diningTable = await this.tables.findOne({
                where: { id: dto.diningTableId },
            });
            if (!diningTable)
                throw new common_1.NotFoundException('Table introuvable');
        }
        let customer = null;
        if (dto.customerId) {
            customer = await this.customers.findOne({
                where: { id: dto.customerId },
            });
            if (!customer)
                throw new common_1.NotFoundException('Client introuvable');
        }
        let createdBy = null;
        if (createdById) {
            createdBy = await this.users.findOne({ where: { id: createdById } });
        }
        const items = await this.buildLinesFromInput(dto.items);
        const order = this.orders.create({
            serviceType: dto.serviceType,
            notes: dto.notes ?? undefined,
            diningTable: diningTable ?? undefined,
            customer: customer ?? undefined,
            createdBy: createdBy ?? undefined,
            status: enums_1.OrderWorkflowStatus.PLACED,
            items,
        });
        await this.orders.save(order);
        await this.applyStockDelta(items.map((l) => ({
            productId: l.product.id,
            quantity: l.quantity,
        })), 'consume');
        await this.refreshTableStatus(order.diningTable?.id);
        const full = await this.findOneEntity(order.id);
        return this.serialize(full);
    }
    async findHistory(opts) {
        const now = new Date();
        let end = opts?.to ? new Date(opts.to) : new Date(now);
        if (Number.isNaN(end.getTime()))
            end = new Date(now);
        end.setHours(23, 59, 59, 999);
        const fallbackStart = new Date(now);
        fallbackStart.setFullYear(fallbackStart.getFullYear() - 1);
        fallbackStart.setHours(0, 0, 0, 0);
        let start = opts?.from ? new Date(opts.from) : new Date(fallbackStart);
        if (Number.isNaN(start.getTime()))
            start = new Date(fallbackStart);
        start.setHours(0, 0, 0, 0);
        const where = {
            status: (0, typeorm_2.In)([enums_1.OrderWorkflowStatus.PAID, enums_1.OrderWorkflowStatus.CANCELLED]),
            createdAt: (0, typeorm_2.Between)(start, end),
        };
        if (opts?.scopeUserId) {
            where.createdBy = { id: opts.scopeUserId };
        }
        const rows = await this.orders.find({
            where,
            relations: {
                diningTable: true,
                customer: true,
                createdBy: true,
                items: { product: true },
                payments: true,
            },
            order: { createdAt: 'DESC' },
            take: 500,
        });
        return rows.map((r) => this.serialize(r));
    }
    async findAll(opts) {
        let where = {};
        if (opts?.kitchen) {
            where = { status: (0, typeorm_2.In)(KITCHEN_STATUSES) };
        }
        else if (opts?.openOnly) {
            where = { status: (0, typeorm_2.In)(ACTIVE_STATUSES) };
        }
        if (opts?.scopeUserId) {
            where = { ...where, createdBy: { id: opts.scopeUserId } };
        }
        const rows = await this.orders.find({
            where,
            relations: {
                diningTable: true,
                customer: true,
                createdBy: true,
                items: { product: true },
                payments: true,
            },
            order: { createdAt: opts?.kitchen ? 'ASC' : 'DESC' },
        });
        return rows.map((r) => this.serialize(r));
    }
    async findOneEntity(id) {
        const row = await this.orders.findOne({
            where: { id },
            relations: {
                diningTable: true,
                customer: true,
                createdBy: true,
                items: { product: true },
                payments: true,
            },
        });
        if (!row)
            throw new common_1.NotFoundException('Commande introuvable');
        return row;
    }
    async findOne(id, scopeUserId) {
        const row = await this.findOneEntity(id);
        this.assertOrderAccess(row, scopeUserId);
        return this.serialize(row);
    }
    async update(id, dto, scopeUserId) {
        const row = await this.findOneEntity(id);
        this.assertOrderAccess(row, scopeUserId);
        const prevTableId = row.diningTable?.id ?? null;
        const prevStatus = row.status;
        if (dto.status !== undefined) {
            if (row.status === enums_1.OrderWorkflowStatus.PAID &&
                dto.status !== enums_1.OrderWorkflowStatus.PAID) {
                throw new common_1.BadRequestException('Impossible de modifier le statut d’une commande déjà payée');
            }
            row.status = dto.status;
        }
        if (dto.serviceType !== undefined) {
            row.serviceType = dto.serviceType;
        }
        if (dto.notes !== undefined) {
            row.notes = dto.notes === null || dto.notes === '' ? null : dto.notes;
        }
        if (dto.diningTableId !== undefined) {
            if (dto.diningTableId === null) {
                row.diningTable = null;
            }
            else {
                const t = await this.tables.findOne({
                    where: { id: dto.diningTableId },
                });
                if (!t)
                    throw new common_1.NotFoundException('Table introuvable');
                row.diningTable = t;
            }
        }
        if (dto.customerId !== undefined) {
            if (dto.customerId === null) {
                row.customer = null;
            }
            else {
                const c = await this.customers.findOne({
                    where: { id: dto.customerId },
                });
                if (!c)
                    throw new common_1.NotFoundException('Client introuvable');
                row.customer = c;
            }
        }
        await this.orders.save(row);
        if (dto.status === enums_1.OrderWorkflowStatus.CANCELLED &&
            prevStatus !== enums_1.OrderWorkflowStatus.CANCELLED &&
            prevStatus !== enums_1.OrderWorkflowStatus.PAID) {
            const lines = (row.items ?? [])
                .map((l) => ({
                productId: l.product?.id ?? '',
                quantity: l.quantity,
            }))
                .filter((l) => l.productId.length > 0);
            await this.applyStockDelta(lines, 'restore');
        }
        await this.refreshTableStatus(prevTableId);
        await this.refreshTableStatus(row.diningTable?.id ?? null);
        return this.serialize(await this.findOneEntity(id));
    }
    async replaceItems(id, dto, scopeUserId) {
        const row = await this.findOneEntity(id);
        this.assertOrderAccess(row, scopeUserId);
        if (TERMINAL_STATUSES.includes(row.status)) {
            throw new common_1.BadRequestException('Impossible de modifier les lignes (commande terminée)');
        }
        const previousLines = (row.items ?? [])
            .map((l) => ({
            productId: l.product?.id ?? '',
            quantity: l.quantity,
        }))
            .filter((l) => l.productId.length > 0);
        await this.orderItems
            .createQueryBuilder()
            .delete()
            .where('order_id = :id', { id })
            .execute();
        const lines = await this.buildLinesFromInput(dto.items);
        for (const line of lines) {
            line.order = row;
        }
        await this.orderItems.save(lines);
        await this.applyStockDelta(previousLines, 'restore');
        await this.applyStockDelta(lines.map((l) => ({
            productId: l.product.id,
            quantity: l.quantity,
        })), 'consume');
        return this.serialize(await this.findOneEntity(id));
    }
    async addPayment(id, dto, recordedById, scopeUserId) {
        const row = await this.findOneEntity(id);
        this.assertOrderAccess(row, scopeUserId);
        if (row.status === enums_1.OrderWorkflowStatus.CANCELLED) {
            throw new common_1.BadRequestException('Commande annulée');
        }
        if (row.status === enums_1.OrderWorkflowStatus.PAID) {
            throw new common_1.BadRequestException('Commande déjà soldée');
        }
        const { due } = this.computeTotals(row);
        if (dto.amount - due > 0.009) {
            throw new common_1.BadRequestException(`Montant trop élevé (reste à payer ${due.toFixed(2)})`);
        }
        let recordedBy = null;
        if (recordedById) {
            recordedBy = await this.users.findOne({ where: { id: recordedById } });
        }
        const payment = this.payments.create({
            order: row,
            amount: dto.amount.toFixed(2),
            method: dto.method,
            reference: dto.reference,
            recordedBy: recordedBy ?? undefined,
        });
        await this.payments.save(payment);
        const refreshed = await this.findOneEntity(id);
        const after = this.computeTotals(refreshed);
        if (after.due <= 0.009) {
            refreshed.status = enums_1.OrderWorkflowStatus.PAID;
            await this.orders.save(refreshed);
            await this.refreshTableStatus(refreshed.diningTable?.id ?? null);
        }
        return this.serialize(await this.findOneEntity(id));
    }
};
exports.OrdersService = OrdersService;
exports.OrdersService = OrdersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(restaurant_order_entity_1.RestaurantOrder)),
    __param(1, (0, typeorm_1.InjectRepository)(order_item_entity_1.OrderItem)),
    __param(2, (0, typeorm_1.InjectRepository)(payment_entity_1.Payment)),
    __param(3, (0, typeorm_1.InjectRepository)(product_entity_1.Product)),
    __param(4, (0, typeorm_1.InjectRepository)(dining_table_entity_1.DiningTable)),
    __param(5, (0, typeorm_1.InjectRepository)(customer_entity_1.Customer)),
    __param(6, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], OrdersService);
//# sourceMappingURL=orders.service.js.map