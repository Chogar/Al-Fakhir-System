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
exports.TablesService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const enums_1 = require("../common/enums");
const dining_table_entity_1 = require("../database/entities/dining-table.entity");
const reservation_entity_1 = require("../database/entities/reservation.entity");
let TablesService = class TablesService {
    tablesRepo;
    reservationsRepo;
    constructor(tablesRepo, reservationsRepo) {
        this.tablesRepo = tablesRepo;
        this.reservationsRepo = reservationsRepo;
    }
    findAll() {
        return this.tablesRepo.find({
            order: { number: 'ASC' },
        });
    }
    async findOne(id) {
        const row = await this.tablesRepo.findOne({ where: { id } });
        if (!row)
            throw new common_1.NotFoundException('Table introuvable');
        return row;
    }
    async create(dto) {
        const taken = await this.tablesRepo.exist({
            where: { number: dto.number },
        });
        if (taken) {
            throw new common_1.ConflictException('Numéro de table déjà utilisé');
        }
        const entity = this.tablesRepo.create({
            number: dto.number,
            capacity: dto.capacity,
            tableType: dto.tableType,
            status: dto.status,
        });
        return this.tablesRepo.save(entity);
    }
    async update(id, dto) {
        const row = await this.findOne(id);
        if (dto.number !== undefined && dto.number !== row.number) {
            const clash = await this.tablesRepo.findOne({
                where: { number: dto.number },
            });
            if (clash && clash.id !== id) {
                throw new common_1.ConflictException('Numéro de table déjà utilisé');
            }
            row.number = dto.number;
        }
        if (dto.capacity !== undefined)
            row.capacity = dto.capacity;
        if (dto.tableType !== undefined)
            row.tableType = dto.tableType;
        if (dto.status !== undefined)
            row.status = dto.status;
        return this.tablesRepo.save(row);
    }
    async remove(id) {
        await this.findOne(id);
        const activeReservations = await this.reservationsRepo.count({
            where: {
                diningTable: { id },
                status: (0, typeorm_2.Not)(enums_1.ReservationStatus.CANCELLED),
            },
        });
        if (activeReservations > 0) {
            throw new common_1.ConflictException('Impossible de supprimer : réservations actives sur cette table');
        }
        await this.tablesRepo.delete(id);
    }
};
exports.TablesService = TablesService;
exports.TablesService = TablesService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(dining_table_entity_1.DiningTable)),
    __param(1, (0, typeorm_1.InjectRepository)(reservation_entity_1.Reservation)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], TablesService);
//# sourceMappingURL=tables.service.js.map