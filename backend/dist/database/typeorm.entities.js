"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.typeOrmEntities = void 0;
const category_entity_1 = require("./entities/category.entity");
const customer_entity_1 = require("./entities/customer.entity");
const dining_table_entity_1 = require("./entities/dining-table.entity");
const expense_entity_1 = require("./entities/expense.entity");
const inventory_entity_1 = require("./entities/inventory.entity");
const order_item_entity_1 = require("./entities/order-item.entity");
const payment_entity_1 = require("./entities/payment.entity");
const product_entity_1 = require("./entities/product.entity");
const reservation_entity_1 = require("./entities/reservation.entity");
const restaurant_order_entity_1 = require("./entities/restaurant-order.entity");
const role_entity_1 = require("./entities/role.entity");
const user_entity_1 = require("./entities/user.entity");
exports.typeOrmEntities = [
    role_entity_1.Role,
    user_entity_1.User,
    dining_table_entity_1.DiningTable,
    customer_entity_1.Customer,
    category_entity_1.Category,
    product_entity_1.Product,
    restaurant_order_entity_1.RestaurantOrder,
    order_item_entity_1.OrderItem,
    payment_entity_1.Payment,
    reservation_entity_1.Reservation,
    inventory_entity_1.InventoryItem,
    expense_entity_1.Expense,
];
//# sourceMappingURL=typeorm.entities.js.map