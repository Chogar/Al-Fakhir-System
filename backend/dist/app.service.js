"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppService = void 0;
const common_1 = require("@nestjs/common");
let AppService = class AppService {
    root() {
        return {
            service: 'al-fakhir-api',
            message: 'API Al-Fakhir — utilisez les routes sous /api/…',
            endpoints: {
                health: '/api/health',
                login: 'POST /api/auth/login',
                categories: 'GET /api/categories',
                products: 'GET /api/products',
                orders: 'GET/POST /api/orders · encaissement POST /api/orders/:id/payments',
            },
        };
    }
    health() {
        return {
            service: 'al-fakhir-api',
            status: 'ok',
        };
    }
};
exports.AppService = AppService;
exports.AppService = AppService = __decorate([
    (0, common_1.Injectable)()
], AppService);
//# sourceMappingURL=app.service.js.map