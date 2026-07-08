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
exports.ProductsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const category_entity_1 = require("../database/entities/category.entity");
const order_item_entity_1 = require("../database/entities/order-item.entity");
const product_entity_1 = require("../database/entities/product.entity");
let ProductsService = class ProductsService {
    products;
    categories;
    orderItems;
    constructor(products, categories, orderItems) {
        this.products = products;
        this.categories = categories;
        this.orderItems = orderItems;
    }
    async onModuleInit() {
        await this.backfillProductNumbers();
    }
    async backfillProductNumbers() {
        const missing = await this.products.find({
            where: { productNumber: (0, typeorm_2.IsNull)() },
            order: { name: 'ASC', createdAt: 'ASC' },
        });
        if (missing.length === 0)
            return;
        let next = await this.nextProductNumber();
        for (const row of missing) {
            row.productNumber = next;
            next += 1;
        }
        await this.products.save(missing);
    }
    async nextProductNumber() {
        const raw = await this.products
            .createQueryBuilder('p')
            .select('MAX(p.productNumber)', 'max')
            .getRawOne();
        const max = Number(raw?.max ?? 0);
        return Number.isFinite(max) && max > 0 ? max + 1 : 1;
    }
    async salesQuantityByProductId() {
        const rows = await this.orderItems
            .createQueryBuilder('oi')
            .innerJoin('oi.product', 'p')
            .select('p.id', 'productId')
            .addSelect('SUM(oi.quantity)', 'qty')
            .groupBy('p.id')
            .getRawMany();
        const map = new Map();
        for (const row of rows) {
            map.set(row.productId, Number(row.qty) || 0);
        }
        return map;
    }
    sortProductsAlpha(rows) {
        return [...rows].sort((a, b) => {
            const byName = a.name.localeCompare(b.name, 'fr', {
                sensitivity: 'base',
            });
            if (byName !== 0)
                return byName;
            const na = a.productNumber ?? 0;
            const nb = b.productNumber ?? 0;
            return na - nb;
        });
    }
    sortProductsBySales(rows, salesMap) {
        return [...rows].sort((a, b) => {
            const sa = salesMap.get(a.id) ?? 0;
            const sb = salesMap.get(b.id) ?? 0;
            if (sb !== sa)
                return sb - sa;
            const byName = a.name.localeCompare(b.name, 'fr', {
                sensitivity: 'base',
            });
            if (byName !== 0)
                return byName;
            return (a.productNumber ?? 0) - (b.productNumber ?? 0);
        });
    }
    sortProductsByCategory(rows) {
        return [...rows].sort((a, b) => {
            const ca = a.category?.sortOrder ?? 9999;
            const cb = b.category?.sortOrder ?? 9999;
            if (ca !== cb)
                return ca - cb;
            const byCat = (a.category?.labelFr ?? '').localeCompare(b.category?.labelFr ?? '', 'fr', { sensitivity: 'base' });
            if (byCat !== 0)
                return byCat;
            const byName = a.name.localeCompare(b.name, 'fr', { sensitivity: 'base' });
            if (byName !== 0)
                return byName;
            return (a.productNumber ?? 0) - (b.productNumber ?? 0);
        });
    }
    async findAll(categoryId, sort = 'alpha') {
        const where = categoryId ? { category: { id: categoryId } } : {};
        const rows = await this.products.find({
            where,
            relations: { category: true },
        });
        if (sort === 'bestseller') {
            const salesMap = await this.salesQuantityByProductId();
            return this.sortProductsBySales(rows, salesMap);
        }
        if (sort === 'category') {
            return this.sortProductsByCategory(rows);
        }
        return this.sortProductsAlpha(rows);
    }
    async findOne(id) {
        const row = await this.products.findOne({
            where: { id },
            relations: { category: true },
        });
        if (!row)
            throw new common_1.NotFoundException('Produit introuvable');
        return row;
    }
    async create(dto) {
        const category = await this.categories.findOne({
            where: { id: dto.categoryId },
        });
        if (!category)
            throw new common_1.NotFoundException('Catégorie introuvable');
        const entity = this.products.create({
            category,
            name: dto.name,
            nameAr: dto.nameAr?.trim() ? dto.nameAr.trim() : null,
            price: Number(dto.price).toFixed(2),
            imageUrl: dto.imageUrl ?? '',
            description: dto.description ?? '',
            isAvailable: dto.isAvailable ?? true,
            stockQuantity: dto.stockQuantity === undefined ? null : dto.stockQuantity,
            stockAlertThreshold: dto.stockAlertThreshold ?? 0,
            productNumber: await this.nextProductNumber(),
        });
        return this.products.save(entity);
    }
    async update(id, dto) {
        const row = await this.findOne(id);
        if (dto.categoryId !== undefined) {
            const category = await this.categories.findOne({
                where: { id: dto.categoryId },
            });
            if (!category)
                throw new common_1.NotFoundException('Catégorie introuvable');
            row.category = category;
        }
        if (dto.name !== undefined)
            row.name = dto.name;
        if (dto.nameAr !== undefined) {
            row.nameAr = dto.nameAr?.trim() ? dto.nameAr.trim() : null;
        }
        if (dto.price !== undefined)
            row.price = Number(dto.price).toFixed(2);
        if (dto.imageUrl !== undefined)
            row.imageUrl = dto.imageUrl;
        if (dto.description !== undefined)
            row.description = dto.description;
        if (dto.isAvailable !== undefined)
            row.isAvailable = dto.isAvailable;
        if (dto.stockQuantity !== undefined) {
            row.stockQuantity = dto.stockQuantity;
        }
        if (dto.stockAlertThreshold !== undefined) {
            row.stockAlertThreshold = dto.stockAlertThreshold;
        }
        return this.products.save(row);
    }
    async remove(id) {
        const row = await this.findOne(id);
        const used = await this.orderItems.count({
            where: { product: { id } },
        });
        if (used > 0) {
            // Plat déjà vendu : désactivation (soft-delete) pour qu'il quitte la caisse.
            row.isAvailable = false;
            await this.products.save(row);
            return {
                id: row.id,
                softDeleted: true,
                message: 'Plat désactivé (déjà vendu) — retiré de la caisse',
            };
        }
        await this.products.delete(id);
        return { id, softDeleted: false };
    }
    async adjustStock(id, delta, reason) {
        void reason;
        if (!Number.isInteger(delta) || delta === 0) {
            throw new common_1.BadRequestException('Delta invalide (entier non nul attendu)');
        }
        const row = await this.findOne(id);
        if (row.stockQuantity === null || row.stockQuantity === undefined) {
            if (delta < 0) {
                throw new common_1.BadRequestException('Stock non suivi : initialisez d’abord une quantité positive.');
            }
            row.stockQuantity = delta;
        }
        else {
            row.stockQuantity = row.stockQuantity + delta;
        }
        return this.products.save(row);
    }
    async findLowStock() {
        return this.products
            .createQueryBuilder('p')
            .leftJoinAndSelect('p.category', 'cat')
            .where('p.stockQuantity IS NOT NULL')
            .andWhere('p.stockQuantity <= p.stockAlertThreshold')
            .orderBy('p.stockQuantity', 'ASC')
            .addOrderBy('p.name', 'ASC')
            .getMany();
    }
    async consumeStockForOrder(lines) {
        if (!lines || lines.length === 0)
            return;
        const ids = lines.map((l) => l.productId);
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
            p.stockQuantity = p.stockQuantity - line.quantity;
            updates.push(p);
        }
        if (updates.length > 0) {
            await this.products.save(updates);
        }
    }
    async restoreStockForOrder(lines) {
        if (!lines || lines.length === 0)
            return;
        await this.consumeStockForOrder(lines.map((l) => ({ productId: l.productId, quantity: -l.quantity })));
    }
};
exports.ProductsService = ProductsService;
exports.ProductsService = ProductsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(product_entity_1.Product)),
    __param(1, (0, typeorm_1.InjectRepository)(category_entity_1.Category)),
    __param(2, (0, typeorm_1.InjectRepository)(order_item_entity_1.OrderItem)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], ProductsService);
//# sourceMappingURL=products.service.js.map