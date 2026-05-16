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
Object.defineProperty(exports, "__esModule", { value: true });
exports.DiningTable = void 0;
const typeorm_1 = require("typeorm");
const enums_1 = require("../../common/enums");
const reservation_entity_1 = require("./reservation.entity");
const restaurant_order_entity_1 = require("./restaurant-order.entity");
let DiningTable = class DiningTable {
    id;
    number;
    capacity;
    status;
    tableType;
    reservations;
    orders;
    createdAt;
    updatedAt;
};
exports.DiningTable = DiningTable;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], DiningTable.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ unique: true }),
    __metadata("design:type", Number)
], DiningTable.prototype, "number", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 4 }),
    __metadata("design:type", Number)
], DiningTable.prototype, "capacity", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: enums_1.TableStatus,
        default: enums_1.TableStatus.FREE,
    }),
    __metadata("design:type", String)
], DiningTable.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: enums_1.TableCategory,
        default: enums_1.TableCategory.STANDARD,
    }),
    __metadata("design:type", String)
], DiningTable.prototype, "tableType", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => reservation_entity_1.Reservation, (r) => r.diningTable),
    __metadata("design:type", Array)
], DiningTable.prototype, "reservations", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => restaurant_order_entity_1.RestaurantOrder, (o) => o.diningTable),
    __metadata("design:type", Array)
], DiningTable.prototype, "orders", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], DiningTable.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], DiningTable.prototype, "updatedAt", void 0);
exports.DiningTable = DiningTable = __decorate([
    (0, typeorm_1.Entity)('dining_tables')
], DiningTable);
//# sourceMappingURL=dining-table.entity.js.map