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
exports.CustomersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const enums_1 = require("../common/enums");
const customer_entity_1 = require("../database/entities/customer.entity");
const payment_entity_1 = require("../database/entities/payment.entity");
const restaurant_order_entity_1 = require("../database/entities/restaurant-order.entity");
let CustomersService = class CustomersService {
    customers;
    orders;
    payments;
    constructor(customers, orders, payments) {
        this.customers = customers;
        this.orders = orders;
        this.payments = payments;
    }
    async findAll(search) {
        const qb = this.customers.createQueryBuilder('c').orderBy('c.name', 'ASC');
        const term = (search ?? '').trim();
        if (term.length > 0) {
            const like = `%${term.toLowerCase()}%`;
            qb.where('LOWER(c.name) LIKE :q', { q: like }).orWhere('c.phone LIKE :q2', { q2: `%${term}%` });
        }
        return qb.getMany();
    }
    async findOne(id) {
        const row = await this.customers.findOne({ where: { id } });
        if (!row)
            throw new common_1.NotFoundException('Client introuvable');
        return row;
    }
    async create(dto) {
        const row = this.customers.create({
            name: dto.name.trim(),
            phone: dto.phone?.trim() ? dto.phone.trim() : null,
            loyaltyPoints: dto.loyaltyPoints ?? 0,
            isVip: dto.isVip ?? false,
            discountPercent: dto.discountPercent !== undefined
                ? Number(dto.discountPercent).toFixed(2)
                : '0',
        });
        return this.customers.save(row);
    }
    async update(id, dto) {
        const row = await this.findOne(id);
        if (dto.name !== undefined)
            row.name = dto.name.trim();
        if (dto.phone !== undefined) {
            row.phone = dto.phone.trim().length ? dto.phone.trim() : null;
        }
        if (dto.loyaltyPoints !== undefined)
            row.loyaltyPoints = dto.loyaltyPoints;
        if (dto.isVip !== undefined)
            row.isVip = dto.isVip;
        if (dto.discountPercent !== undefined) {
            row.discountPercent = Number(dto.discountPercent).toFixed(2);
        }
        return this.customers.save(row);
    }
    async remove(id) {
        await this.findOne(id);
        await this.customers.delete(id);
    }
    async getStats(id) {
        await this.findOne(id);
        const [totalOrders, paidOrders, paidSumRaw, lastRow] = await Promise.all([
            this.orders.count({ where: { customer: { id } } }),
            this.orders.count({
                where: { customer: { id }, status: enums_1.OrderWorkflowStatus.PAID },
            }),
            this.payments
                .createQueryBuilder('pay')
                .select('COALESCE(SUM(pay.amount), 0)', 'total')
                .innerJoin('pay.order', 'ord')
                .where('ord.customer_id = :id', { id })
                .andWhere('ord.status = :paid', {
                paid: enums_1.OrderWorkflowStatus.PAID,
            })
                .getRawOne(),
            this.orders.findOne({
                where: { customer: { id } },
                order: { createdAt: 'DESC' },
            }),
        ]);
        const totalSpent = Number(paidSumRaw?.total ?? 0);
        const avg = paidOrders > 0 ? totalSpent / paidOrders : 0;
        return {
            totalOrders,
            paidOrders,
            totalSpentFcfa: totalSpent.toFixed(2),
            averageBasketFcfa: avg.toFixed(2),
            lastOrderAt: lastRow ? lastRow.createdAt.toISOString() : null,
        };
    }
    async findOrders(id, limit = 50) {
        await this.findOne(id);
        return this.orders.find({
            where: { customer: { id } },
            relations: {
                diningTable: true,
                customer: true,
                items: { product: true },
                payments: true,
            },
            order: { createdAt: 'DESC' },
            take: limit > 0 && limit <= 500 ? limit : 50,
        });
    }
};
exports.CustomersService = CustomersService;
exports.CustomersService = CustomersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(customer_entity_1.Customer)),
    __param(1, (0, typeorm_1.InjectRepository)(restaurant_order_entity_1.RestaurantOrder)),
    __param(2, (0, typeorm_1.InjectRepository)(payment_entity_1.Payment)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], CustomersService);
//# sourceMappingURL=customers.service.js.map