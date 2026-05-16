"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MenuModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const auth_module_1 = require("../auth/auth.module");
const category_entity_1 = require("../database/entities/category.entity");
const order_item_entity_1 = require("../database/entities/order-item.entity");
const product_entity_1 = require("../database/entities/product.entity");
const categories_controller_1 = require("./categories.controller");
const categories_service_1 = require("./categories.service");
const products_controller_1 = require("./products.controller");
const products_service_1 = require("./products.service");
let MenuModule = class MenuModule {
};
exports.MenuModule = MenuModule;
exports.MenuModule = MenuModule = __decorate([
    (0, common_1.Module)({
        imports: [
            auth_module_1.AuthModule,
            typeorm_1.TypeOrmModule.forFeature([category_entity_1.Category, product_entity_1.Product, order_item_entity_1.OrderItem]),
        ],
        controllers: [categories_controller_1.CategoriesController, products_controller_1.ProductsController],
        providers: [categories_service_1.CategoriesService, products_service_1.ProductsService],
    })
], MenuModule);
//# sourceMappingURL=menu.module.js.map