"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const app_controller_1 = require("./app.controller");
const app_service_1 = require("./app.service");
const auth_module_1 = require("./auth/auth.module");
const customers_module_1 = require("./customers/customers.module");
const dashboard_module_1 = require("./dashboard/dashboard.module");
const expenses_module_1 = require("./expenses/expenses.module");
const typeorm_entities_1 = require("./database/typeorm.entities");
const menu_module_1 = require("./menu/menu.module");
const orders_module_1 = require("./orders/orders.module");
const reservations_module_1 = require("./reservations/reservations.module");
const seed_module_1 = require("./seed/seed.module");
const tables_module_1 = require("./tables/tables.module");
const users_module_1 = require("./users/users.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
            }),
            typeorm_1.TypeOrmModule.forRootAsync({
                imports: [config_1.ConfigModule],
                inject: [config_1.ConfigService],
                useFactory: (config) => ({
                    type: 'postgres',
                    host: config.get('DATABASE_HOST', 'localhost'),
                    port: +config.get('DATABASE_PORT', '5432'),
                    username: config.get('DATABASE_USER', 'postgres'),
                    password: config.get('DATABASE_PASSWORD', 'postgres'),
                    database: config.get('DATABASE_NAME', 'alfakhir'),
                    entities: typeorm_entities_1.typeOrmEntities,
                    synchronize: config.get('TYPEORM_SYNC', 'true') === 'true',
                    logging: config.get('TYPEORM_LOG', 'false') === 'true',
                }),
            }),
            users_module_1.UsersModule,
            auth_module_1.AuthModule,
            seed_module_1.SeedModule,
            tables_module_1.TablesModule,
            reservations_module_1.ReservationsModule,
            orders_module_1.OrdersModule,
            customers_module_1.CustomersModule,
            expenses_module_1.ExpensesModule,
            dashboard_module_1.DashboardModule,
            menu_module_1.MenuModule,
        ],
        controllers: [app_controller_1.AppController],
        providers: [app_service_1.AppService],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map