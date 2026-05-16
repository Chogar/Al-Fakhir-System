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
exports.RestaurantOrder = void 0;
const typeorm_1 = require("typeorm");
const enums_1 = require("../../common/enums");
const customer_entity_1 = require("./customer.entity");
const dining_table_entity_1 = require("./dining-table.entity");
const order_item_entity_1 = require("./order-item.entity");
const payment_entity_1 = require("./payment.entity");
const user_entity_1 = require("./user.entity");
let RestaurantOrder = class RestaurantOrder {
    id;
    orderNumber;
    serviceType;
    status;
    diningTable;
    customer;
    createdBy;
    notes;
    items;
    payments;
    createdAt;
    updatedAt;
};
exports.RestaurantOrder = RestaurantOrder;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], RestaurantOrder.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Generated)('increment'),
    (0, typeorm_1.Column)({ type: 'int', unique: true }),
    __metadata("design:type", Number)
], RestaurantOrder.prototype, "orderNumber", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'enum', enum: enums_1.OrderServiceType }),
    __metadata("design:type", String)
], RestaurantOrder.prototype, "serviceType", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: enums_1.OrderWorkflowStatus,
        default: enums_1.OrderWorkflowStatus.PLACED,
    }),
    __metadata("design:type", String)
], RestaurantOrder.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => dining_table_entity_1.DiningTable, (table) => table.orders, { nullable: true }),
    (0, typeorm_1.JoinColumn)({ name: 'dining_table_id' }),
    __metadata("design:type", dining_table_entity_1.DiningTable)
], RestaurantOrder.prototype, "diningTable", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => customer_entity_1.Customer, (customer) => customer.orders, {
        nullable: true,
    }),
    (0, typeorm_1.JoinColumn)({ name: 'customer_id' }),
    __metadata("design:type", customer_entity_1.Customer)
], RestaurantOrder.prototype, "customer", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, { nullable: true }),
    (0, typeorm_1.JoinColumn)({ name: 'created_by_id' }),
    __metadata("design:type", user_entity_1.User)
], RestaurantOrder.prototype, "createdBy", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", Object)
], RestaurantOrder.prototype, "notes", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => order_item_entity_1.OrderItem, (item) => item.order, { cascade: true }),
    __metadata("design:type", Array)
], RestaurantOrder.prototype, "items", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => payment_entity_1.Payment, (payment) => payment.order),
    __metadata("design:type", Array)
], RestaurantOrder.prototype, "payments", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], RestaurantOrder.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], RestaurantOrder.prototype, "updatedAt", void 0);
exports.RestaurantOrder = RestaurantOrder = __decorate([
    (0, typeorm_1.Entity)('orders')
], RestaurantOrder);
//# sourceMappingURL=restaurant-order.entity.js.map