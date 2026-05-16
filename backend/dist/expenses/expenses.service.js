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
exports.ExpensesService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const expense_entity_1 = require("../database/entities/expense.entity");
let ExpensesService = class ExpensesService {
    expenses;
    constructor(expenses) {
        this.expenses = expenses;
    }
    findAll(opts) {
        const qb = this.expenses
            .createQueryBuilder('e')
            .orderBy('e.spentOn', 'DESC')
            .addOrderBy('e.createdAt', 'DESC');
        let fromVal;
        let toVal;
        if (opts?.spentOnFrom) {
            const d = new Date(opts.spentOnFrom);
            if (!Number.isNaN(d.getTime()))
                fromVal = d;
        }
        if (opts?.spentOnTo) {
            const d = new Date(opts.spentOnTo);
            if (!Number.isNaN(d.getTime())) {
                d.setHours(23, 59, 59, 999);
                toVal = d;
            }
        }
        if (fromVal && toVal) {
            qb.andWhere('e.spentOn BETWEEN :a AND :b', { a: fromVal, b: toVal });
        }
        else if (fromVal) {
            qb.andWhere('e.spentOn >= :a', { a: fromVal });
        }
        else if (toVal) {
            qb.andWhere('e.spentOn <= :b', { b: toVal });
        }
        return qb.getMany();
    }
    async findOne(id) {
        const row = await this.expenses.findOne({ where: { id } });
        if (!row)
            throw new common_1.NotFoundException('Dépense introuvable');
        return row;
    }
    async create(dto) {
        const spentOn = new Date(dto.spentOn);
        if (Number.isNaN(spentOn.getTime())) {
            throw new common_1.BadRequestException('Date invalide');
        }
        const row = this.expenses.create({
            label: dto.label.trim(),
            amount: dto.amount.toFixed(2),
            spentOn,
            category: dto.category?.trim() ? dto.category.trim() : null,
        });
        return this.expenses.save(row);
    }
    async update(id, dto) {
        const row = await this.findOne(id);
        if (dto.label !== undefined)
            row.label = dto.label.trim();
        if (dto.amount !== undefined)
            row.amount = dto.amount.toFixed(2);
        if (dto.spentOn !== undefined) {
            const spentOn = new Date(dto.spentOn);
            if (Number.isNaN(spentOn.getTime())) {
                throw new common_1.BadRequestException('Date invalide');
            }
            row.spentOn = spentOn;
        }
        if (dto.category !== undefined) {
            const raw = dto.category;
            row.category =
                raw === null || raw === undefined
                    ? null
                    : String(raw).trim()
                        ? String(raw).trim()
                        : null;
        }
        return this.expenses.save(row);
    }
    async remove(id) {
        await this.findOne(id);
        await this.expenses.delete(id);
    }
    async listDistinctCategories() {
        const rows = await this.expenses
            .createQueryBuilder('e')
            .select('e.category', 'category')
            .addSelect('COUNT(e.id)', 'count')
            .where('e.category IS NOT NULL')
            .andWhere("TRIM(e.category) <> ''")
            .groupBy('e.category')
            .orderBy('count', 'DESC')
            .addOrderBy('e.category', 'ASC')
            .getRawMany();
        return rows.map((r) => ({
            category: r.category,
            usageCount: Number(r.count) || 0,
        }));
    }
};
exports.ExpensesService = ExpensesService;
exports.ExpensesService = ExpensesService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(expense_entity_1.Expense)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], ExpensesService);
//# sourceMappingURL=expenses.service.js.map