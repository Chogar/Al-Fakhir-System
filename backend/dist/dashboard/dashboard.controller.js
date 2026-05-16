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
exports.DashboardController = void 0;
const common_1 = require("@nestjs/common");
const permissions_decorator_1 = require("../auth/decorators/permissions.decorator");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const permissions_guard_1 = require("../auth/guards/permissions.guard");
const dashboard_service_1 = require("./dashboard.service");
let DashboardController = class DashboardController {
    dashboard;
    constructor(dashboard) {
        this.dashboard = dashboard;
    }
    financeSummary(period, from, to) {
        return this.dashboard.getFinanceSummary(period, from, to);
    }
    overview() {
        return this.dashboard.getOverview();
    }
    salesBreakdown(period, from, to, limit) {
        const n = limit ? Number(limit) : 8;
        const safe = Number.isFinite(n) && n > 0 && n <= 50 ? n : 8;
        return this.dashboard.getSalesBreakdown(period, from, to, safe);
    }
    salesByUser(period, from, to) {
        return this.dashboard.getSalesByUser(period, from, to);
    }
};
exports.DashboardController = DashboardController;
__decorate([
    (0, common_1.Get)('finance-summary'),
    (0, permissions_decorator_1.Permissions)('finance.view'),
    __param(0, (0, common_1.Query)('period')),
    __param(1, (0, common_1.Query)('from')),
    __param(2, (0, common_1.Query)('to')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", void 0)
], DashboardController.prototype, "financeSummary", null);
__decorate([
    (0, common_1.Get)('overview'),
    (0, permissions_decorator_1.Permissions)('dashboard.view'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], DashboardController.prototype, "overview", null);
__decorate([
    (0, common_1.Get)('sales-breakdown'),
    (0, permissions_decorator_1.Permissions)('finance.view'),
    __param(0, (0, common_1.Query)('period')),
    __param(1, (0, common_1.Query)('from')),
    __param(2, (0, common_1.Query)('to')),
    __param(3, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", void 0)
], DashboardController.prototype, "salesBreakdown", null);
__decorate([
    (0, common_1.Get)('sales-by-user'),
    (0, permissions_decorator_1.Permissions)('finance.view'),
    __param(0, (0, common_1.Query)('period')),
    __param(1, (0, common_1.Query)('from')),
    __param(2, (0, common_1.Query)('to')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", void 0)
], DashboardController.prototype, "salesByUser", null);
exports.DashboardController = DashboardController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, permissions_guard_1.PermissionsGuard),
    (0, common_1.Controller)('dashboard'),
    __metadata("design:paramtypes", [dashboard_service_1.DashboardService])
], DashboardController);
//# sourceMappingURL=dashboard.controller.js.map