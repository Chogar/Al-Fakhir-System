"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReservationStatus = exports.PaymentMethod = exports.OrderWorkflowStatus = exports.OrderServiceType = exports.MenuCategorySlug = exports.TableCategory = exports.TableStatus = exports.RoleName = void 0;
var RoleName;
(function (RoleName) {
    RoleName["ADMIN"] = "ADMIN";
    RoleName["RECEPTIONIST"] = "RECEPTIONIST";
    RoleName["SERVER"] = "SERVER";
    RoleName["CASHIER"] = "CASHIER";
    RoleName["MANAGER"] = "MANAGER";
})(RoleName || (exports.RoleName = RoleName = {}));
var TableStatus;
(function (TableStatus) {
    TableStatus["FREE"] = "FREE";
    TableStatus["OCCUPIED"] = "OCCUPIED";
    TableStatus["RESERVED"] = "RESERVED";
    TableStatus["CLEANING"] = "CLEANING";
})(TableStatus || (exports.TableStatus = TableStatus = {}));
var TableCategory;
(function (TableCategory) {
    TableCategory["STANDARD"] = "STANDARD";
    TableCategory["VIP"] = "VIP";
    TableCategory["FAMILY"] = "FAMILY";
})(TableCategory || (exports.TableCategory = TableCategory = {}));
var MenuCategorySlug;
(function (MenuCategorySlug) {
    MenuCategorySlug["PLATS"] = "PLATS";
    MenuCategorySlug["BOISSONS"] = "BOISSONS";
    MenuCategorySlug["DESSERTS"] = "DESSERTS";
    MenuCategorySlug["GRILLADES"] = "GRILLADES";
})(MenuCategorySlug || (exports.MenuCategorySlug = MenuCategorySlug = {}));
var OrderServiceType;
(function (OrderServiceType) {
    OrderServiceType["DINE_IN"] = "DINE_IN";
    OrderServiceType["TAKEAWAY"] = "TAKEAWAY";
    OrderServiceType["DELIVERY"] = "DELIVERY";
})(OrderServiceType || (exports.OrderServiceType = OrderServiceType = {}));
var OrderWorkflowStatus;
(function (OrderWorkflowStatus) {
    OrderWorkflowStatus["PLACED"] = "PLACED";
    OrderWorkflowStatus["PREPARING"] = "PREPARING";
    OrderWorkflowStatus["READY"] = "READY";
    OrderWorkflowStatus["SERVED"] = "SERVED";
    OrderWorkflowStatus["PAID"] = "PAID";
    OrderWorkflowStatus["CANCELLED"] = "CANCELLED";
})(OrderWorkflowStatus || (exports.OrderWorkflowStatus = OrderWorkflowStatus = {}));
var PaymentMethod;
(function (PaymentMethod) {
    PaymentMethod["CASH"] = "CASH";
    PaymentMethod["MOBILE_MONEY"] = "MOBILE_MONEY";
    PaymentMethod["BANK_CARD"] = "BANK_CARD";
})(PaymentMethod || (exports.PaymentMethod = PaymentMethod = {}));
var ReservationStatus;
(function (ReservationStatus) {
    ReservationStatus["PENDING"] = "PENDING";
    ReservationStatus["CONFIRMED"] = "CONFIRMED";
    ReservationStatus["CANCELLED"] = "CANCELLED";
    ReservationStatus["SEATED"] = "SEATED";
})(ReservationStatus || (exports.ReservationStatus = ReservationStatus = {}));
//# sourceMappingURL=enums.js.map