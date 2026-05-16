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
exports.CategoriesService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const category_entity_1 = require("../database/entities/category.entity");
const product_entity_1 = require("../database/entities/product.entity");
let CategoriesService = class CategoriesService {
    categories;
    products;
    constructor(categories, products) {
        this.categories = categories;
        this.products = products;
    }
    findAll() {
        return this.categories.find({
            order: { sortOrder: 'ASC', labelFr: 'ASC' },
        });
    }
    async findAllWithCounts() {
        const rows = await this.findAll();
        const counts = await this.products
            .createQueryBuilder('p')
            .innerJoin('p.category', 'cat')
            .select('cat.id', 'categoryId')
            .addSelect('COUNT(p.id)', 'count')
            .groupBy('cat.id')
            .getRawMany();
        const map = new Map();
        for (const r of counts) {
            map.set(r.categoryId, Number(r.count) || 0);
        }
        return rows.map((c) => Object.assign(c, { productCount: map.get(c.id) ?? 0 }));
    }
    async findOne(id) {
        const row = await this.categories.findOne({ where: { id } });
        if (!row)
            throw new common_1.NotFoundException('Catégorie introuvable');
        return row;
    }
    normalizeSlug(raw) {
        const s = raw
            .trim()
            .toUpperCase()
            .replace(/[^A-Z0-9]+/g, '_')
            .replace(/^_+|_+$/g, '');
        return s.slice(0, 80);
    }
    async create(dto) {
        const slug = this.normalizeSlug(dto.slug);
        if (!slug.length) {
            throw new common_1.BadRequestException('Slug invalide');
        }
        const clash = await this.categories.findOne({ where: { slug } });
        if (clash) {
            throw new common_1.ConflictException('Ce slug existe déjà');
        }
        const row = this.categories.create({
            slug,
            labelFr: dto.labelFr.trim(),
            labelAr: dto.labelAr?.trim() ? dto.labelAr.trim() : null,
            sortOrder: dto.sortOrder ?? 0,
        });
        return this.categories.save(row);
    }
    async update(id, dto) {
        const row = await this.findOne(id);
        if (dto.slug !== undefined) {
            const slug = this.normalizeSlug(dto.slug);
            if (!slug.length) {
                throw new common_1.BadRequestException('Slug invalide');
            }
            const clash = await this.categories.findOne({ where: { slug } });
            if (clash && clash.id !== id) {
                throw new common_1.ConflictException('Ce slug existe déjà');
            }
            row.slug = slug;
        }
        if (dto.labelFr !== undefined)
            row.labelFr = dto.labelFr.trim();
        if (dto.labelAr !== undefined) {
            row.labelAr = dto.labelAr?.trim() ? dto.labelAr.trim() : null;
        }
        if (dto.sortOrder !== undefined)
            row.sortOrder = dto.sortOrder;
        return this.categories.save(row);
    }
    async remove(id) {
        await this.findOne(id);
        const count = await this.products.count({
            where: { category: { id } },
        });
        if (count > 0) {
            throw new common_1.ConflictException(`Impossible de supprimer : ${count} produit(s) utilisent cette catégorie`);
        }
        await this.categories.delete(id);
    }
    async mergeInto(sourceId, targetId) {
        if (sourceId === targetId) {
            throw new common_1.BadRequestException('La catégorie source et la cible doivent être différentes');
        }
        const source = await this.categories.findOne({ where: { id: sourceId } });
        if (!source)
            throw new common_1.NotFoundException('Catégorie source introuvable');
        const target = await this.categories.findOne({ where: { id: targetId } });
        if (!target)
            throw new common_1.NotFoundException('Catégorie cible introuvable');
        const result = await this.products
            .createQueryBuilder()
            .update()
            .set({ category: { id: targetId } })
            .where('categoryId = :sid', { sid: sourceId })
            .execute();
        await this.categories.delete(sourceId);
        return {
            movedCount: result.affected ?? 0,
            targetId,
        };
    }
    normalizeLabelKey(label) {
        return label
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .toLowerCase()
            .replace(/\s+/g, ' ')
            .trim();
    }
    async findDuplicates() {
        const all = await this.findAllWithCounts();
        const groups = new Map();
        for (const c of all) {
            const key = this.normalizeLabelKey(c.labelFr);
            if (!key)
                continue;
            const arr = groups.get(key) ?? [];
            arr.push(c);
            groups.set(key, arr);
        }
        const uuidSuffix = /-[0-9a-f]{6,}(-[0-9a-f]+)*$/i;
        const out = [];
        for (const [key, items] of groups.entries()) {
            if (items.length < 2)
                continue;
            const ranked = [...items].sort((a, b) => {
                const aClean = uuidSuffix.test(a.slug) ? 1 : 0;
                const bClean = uuidSuffix.test(b.slug) ? 1 : 0;
                if (aClean !== bClean)
                    return aClean - bClean;
                if (a.productCount !== b.productCount) {
                    return b.productCount - a.productCount;
                }
                if (a.sortOrder !== b.sortOrder)
                    return a.sortOrder - b.sortOrder;
                return a.slug.length - b.slug.length;
            });
            const [target, ...sources] = ranked;
            const totalProducts = items.reduce((s, x) => s + x.productCount, 0);
            out.push({ key, target, sources, totalProducts });
        }
        out.sort((a, b) => a.target.labelFr.localeCompare(b.target.labelFr, 'fr'));
        return out;
    }
    async mergeBulk(pairs) {
        if (!Array.isArray(pairs) || pairs.length === 0) {
            throw new common_1.BadRequestException('Liste de fusions vide');
        }
        let appliedCount = 0;
        let movedProducts = 0;
        const errors = [];
        for (const { sourceId, targetId } of pairs) {
            try {
                const r = await this.mergeInto(sourceId, targetId);
                appliedCount += 1;
                movedProducts += r.movedCount;
            }
            catch (e) {
                const message = e instanceof Error ? e.message : String(e);
                errors.push({ sourceId, targetId, message });
            }
        }
        return { appliedCount, movedProducts, errors };
    }
};
exports.CategoriesService = CategoriesService;
exports.CategoriesService = CategoriesService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(category_entity_1.Category)),
    __param(1, (0, typeorm_1.InjectRepository)(product_entity_1.Product)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], CategoriesService);
//# sourceMappingURL=categories.service.js.map