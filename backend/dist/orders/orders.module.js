"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrdersModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const auth_module_1 = require("../auth/auth.module");
const customer_entity_1 = require("../database/entities/customer.entity");
const dining_table_entity_1 = require("../database/entities/dining-table.entity");
const order_item_entity_1 = require("../database/entities/order-item.entity");
const payment_entity_1 = require("../database/entities/payment.entity");
const product_entity_1 = require("../database/entities/product.entity");
const restaurant_order_entity_1 = require("../database/entities/restaurant-order.entity");
const user_entity_1 = require("../database/entities/user.entity");
const orders_controller_1 = require("./orders.controller");
const orders_service_1 = require("./orders.service");
let OrdersModule = class OrdersModule {
};
exports.OrdersModule = OrdersModule;
exports.OrdersModule = OrdersModule = __decorate([
    (0, common_1.Module)({
        imports: [
            auth_module_1.AuthModule,
            typeorm_1.TypeOrmModule.forFeature([
                restaurant_order_entity_1.RestaurantOrder,
                order_item_entity_1.OrderItem,
                payment_entity_1.Payment,
                product_entity_1.Product,
                dining_table_entity_1.DiningTable,
                customer_entity_1.Customer,
                user_entity_1.User,
            ]),
        ],
        controllers: [orders_controller_1.OrdersController],
        providers: [orders_service_1.OrdersService],
        exports: [orders_service_1.OrdersService],
    })
], OrdersModule);
//# sourceMappingURL=orders.module.js.map