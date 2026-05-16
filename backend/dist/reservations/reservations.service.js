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
exports.ReservationsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const customer_entity_1 = require("../database/entities/customer.entity");
const dining_table_entity_1 = require("../database/entities/dining-table.entity");
const reservation_entity_1 = require("../database/entities/reservation.entity");
let ReservationsService = class ReservationsService {
    reservationsRepo;
    tablesRepo;
    customersRepo;
    constructor(reservationsRepo, tablesRepo, customersRepo) {
        this.reservationsRepo = reservationsRepo;
        this.tablesRepo = tablesRepo;
        this.customersRepo = customersRepo;
    }
    async findAll(filters) {
        const qb = this.reservationsRepo
            .createQueryBuilder('r')
            .leftJoinAndSelect('r.diningTable', 'dt')
            .leftJoinAndSelect('r.customer', 'c')
            .orderBy('r.reservationAt', 'ASC');
        if (filters.status) {
            qb.andWhere('r.status = :status', { status: filters.status });
        }
        if (filters.dateFrom) {
            qb.andWhere('r.reservationAt >= :df', { df: new Date(filters.dateFrom) });
        }
        if (filters.dateTo) {
            const end = new Date(filters.dateTo);
            end.setHours(23, 59, 59, 999);
            qb.andWhere('r.reservationAt <= :dt', { dt: end });
        }
        return qb.getMany();
    }
    async findOne(id) {
        const row = await this.reservationsRepo.findOne({
            where: { id },
            relations: { diningTable: true, customer: true },
        });
        if (!row)
            throw new common_1.NotFoundException('Réservation introuvable');
        return row;
    }
    async create(dto) {
        let diningTable = null;
        if (dto.diningTableId) {
            diningTable = await this.tablesRepo.findOne({
                where: { id: dto.diningTableId },
            });
            if (!diningTable) {
                throw new common_1.NotFoundException('Table introuvable');
            }
        }
        let customer = null;
        if (dto.customerId) {
            customer = await this.customersRepo.findOne({
                where: { id: dto.customerId },
            });
            if (!customer) {
                throw new common_1.NotFoundException('Client introuvable');
            }
        }
        const at = new Date(dto.reservationAt);
        if (Number.isNaN(at.getTime())) {
            throw new common_1.BadRequestException('Date ou heure invalides');
        }
        const entity = this.reservationsRepo.create({
            guestName: dto.guestName,
            guestPhone: dto.guestPhone,
            reservationAt: at,
            partySize: dto.partySize,
            ...(diningTable ? { diningTable } : {}),
            ...(customer ? { customer } : {}),
        });
        return this.reservationsRepo.save(entity);
    }
    async update(id, dto) {
        const row = await this.findOne(id);
        if (dto.guestName !== undefined)
            row.guestName = dto.guestName;
        if (dto.guestPhone !== undefined)
            row.guestPhone = dto.guestPhone;
        if (dto.partySize !== undefined)
            row.partySize = dto.partySize;
        if (dto.status !== undefined)
            row.status = dto.status;
        if (dto.reservationAt !== undefined) {
            const at = new Date(dto.reservationAt);
            if (Number.isNaN(at.getTime())) {
                throw new common_1.BadRequestException('Date ou heure invalides');
            }
            row.reservationAt = at;
        }
        if (dto.diningTableId !== undefined) {
            const table = await this.tablesRepo.findOne({
                where: { id: dto.diningTableId },
            });
            if (!table)
                throw new common_1.NotFoundException('Table introuvable');
            row.diningTable = table;
        }
        return this.reservationsRepo.save(row);
    }
};
exports.ReservationsService = ReservationsService;
exports.ReservationsService = ReservationsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(reservation_entity_1.Reservation)),
    __param(1, (0, typeorm_1.InjectRepository)(dining_table_entity_1.DiningTable)),
    __param(2, (0, typeorm_1.InjectRepository)(customer_entity_1.Customer)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], ReservationsService);
//# sourceMappingURL=reservations.service.js.map