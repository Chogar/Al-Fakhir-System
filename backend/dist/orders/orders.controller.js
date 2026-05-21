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
exports.OrdersController = void 0;
const common_1 = require("@nestjs/common");
const permissions_decorator_1 = require("../auth/decorators/permissions.decorator");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const permissions_guard_1 = require("../auth/guards/permissions.guard");
const add_payment_dto_1 = require("./dto/add-payment.dto");
const create_order_dto_1 = require("./dto/create-order.dto");
const replace_order_items_dto_1 = require("./dto/replace-order-items.dto");
const update_order_dto_1 = require("./dto/update-order.dto");
const orders_service_1 = require("./orders.service");
let OrdersController = class OrdersController {
    orders;
    constructor(orders) {
        this.orders = orders;
    }
    list(openOnly, kitchen, req) {
        const kitchenMode = kitchen === 'true' || kitchen === '1';
        const scopeUserId = this.resolveOrderScopeUserId(req, kitchenMode);
        return this.orders.findAll({
            openOnly: openOnly === 'true' || openOnly === '1',
            kitchen: kitchenMode,
            scopeUserId,
        });
    }
    history(from, to, req) {
        const scopeUserId = this.resolveOrderScopeUserId(req, false);
        return this.orders.findHistory({ from, to, scopeUserId });
    }
    decaissement(from, req) {
        const scopeUserId = this.resolveOrderScopeUserId(req, false);
        return this.orders.performDecaissement({ from, scopeUserId });
    }
    resolveOrderScopeUserId(req, kitchenMode) {
        if (kitchenMode)
            return undefined;
        const perms = req.user?.permissions ?? [];
        if (perms.includes('finance.view'))
            return undefined;
        return req.user?.id;
    }
    create(dto, req) {
        return this.orders.create(dto, req.user?.id);
    }
    getOne(id, req) {
        const scopeUserId = this.resolveOrderScopeUserId(req, false);
        return this.orders.findOne(id, scopeUserId);
    }
    update(id, dto, req) {
        const scopeUserId = this.resolveOrderScopeUserId(req, false);
        return this.orders.update(id, dto, scopeUserId);
    }
    replaceItems(id, dto, req) {
        const scopeUserId = this.resolveOrderScopeUserId(req, false);
        return this.orders.replaceItems(id, dto, scopeUserId);
    }
    addPayment(id, dto, req) {
        const scopeUserId = this.resolveOrderScopeUserId(req, false);
        return this.orders.addPayment(id, dto, req.user?.id, scopeUserId);
    }
};
exports.OrdersController = OrdersController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Query)('openOnly')),
    __param(1, (0, common_1.Query)('kitchen')),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", void 0)
], OrdersController.prototype, "list", null);
__decorate([
    (0, common_1.Get)('history'),
    __param(0, (0, common_1.Query)('from')),
    __param(1, (0, common_1.Query)('to')),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", void 0)
], OrdersController.prototype, "history", null);
__decorate([
    (0, common_1.Post)('decaissement'),
    __param(0, (0, common_1.Query)('from')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], OrdersController.prototype, "decaissement", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_order_dto_1.CreateOrderDto, Object]),
    __metadata("design:returntype", void 0)
], OrdersController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], OrdersController.prototype, "getOne", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_order_dto_1.UpdateOrderDto, Object]),
    __metadata("design:returntype", void 0)
], OrdersController.prototype, "update", null);
__decorate([
    (0, common_1.Put)(':id/items'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, replace_order_items_dto_1.ReplaceOrderItemsDto, Object]),
    __metadata("design:returntype", void 0)
], OrdersController.prototype, "replaceItems", null);
__decorate([
    (0, common_1.Post)(':id/payments'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, add_payment_dto_1.AddPaymentDto, Object]),
    __metadata("design:returntype", void 0)
], OrdersController.prototype, "addPayment", null);
exports.OrdersController = OrdersController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, permissions_guard_1.PermissionsGuard),
    (0, permissions_decorator_1.Permissions)('pos.access'),
    (0, common_1.Controller)('orders'),
    __metadata("design:paramtypes", [orders_service_1.OrdersService])
], OrdersController);
//# sourceMappingURL=orders.controller.js.map