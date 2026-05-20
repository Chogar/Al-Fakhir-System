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
exports.DashboardService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const enums_1 = require("../common/enums");
const dining_table_entity_1 = require("../database/entities/dining-table.entity");
const expense_entity_1 = require("../database/entities/expense.entity");
const order_item_entity_1 = require("../database/entities/order-item.entity");
const payment_entity_1 = require("../database/entities/payment.entity");
const reservation_entity_1 = require("../database/entities/reservation.entity");
const restaurant_order_entity_1 = require("../database/entities/restaurant-order.entity");
let DashboardService = class DashboardService {
    tables;
    reservations;
    orders;
    orderItems;
    payments;
    expenses;
    constructor(tables, reservations, orders, orderItems, payments, expenses) {
        this.tables = tables;
        this.reservations = reservations;
        this.orders = orders;
        this.orderItems = orderItems;
        this.payments = payments;
        this.expenses = expenses;
    }
    async getOverview() {
        const now = new Date();
        const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const dayEnd = new Date(dayStart);
        dayEnd.setHours(23, 59, 59, 999);
        const [tablesTotal, tablesFree, tablesOccupied, tablesReserved, tablesCleaning, reservationsToday, ordersInProgress,] = await Promise.all([
            this.tables.count(),
            this.tables.count({ where: { status: enums_1.TableStatus.FREE } }),
            this.tables.count({ where: { status: enums_1.TableStatus.OCCUPIED } }),
            this.tables.count({ where: { status: enums_1.TableStatus.RESERVED } }),
            this.tables.count({ where: { status: enums_1.TableStatus.CLEANING } }),
            this.reservations.count({
                where: {
                    reservationAt: (0, typeorm_2.Between)(dayStart, dayEnd),
                    status: (0, typeorm_2.Not)(enums_1.ReservationStatus.CANCELLED),
                },
            }),
            this.orders.count({
                where: {
                    status: (0, typeorm_2.In)([
                        enums_1.OrderWorkflowStatus.PLACED,
                        enums_1.OrderWorkflowStatus.PREPARING,
                        enums_1.OrderWorkflowStatus.READY,
                        enums_1.OrderWorkflowStatus.SERVED,
                    ]),
                },
            }),
        ]);
        return {
            tables: {
                total: tablesTotal,
                free: tablesFree,
                occupied: tablesOccupied,
                reserved: tablesReserved,
                cleaning: tablesCleaning,
            },
            reservationsToday,
            ordersInProgress,
        };
    }
    async getFinanceSummary(periodRaw, fromRaw, toRaw) {
        const customFrom = this.parseDateBoundary(fromRaw, 'start');
        const customTo = this.parseDateBoundary(toRaw, 'end');
        let period;
        let ps;
        let pe;
        if (customFrom && customTo) {
            if (customFrom.getTime() > customTo.getTime()) {
                ps = customTo;
                pe = customFrom;
                pe.setHours(23, 59, 59, 999);
                ps.setHours(0, 0, 0, 0);
            }
            else {
                ps = customFrom;
                pe = customTo;
            }
            period = 'custom';
        }
        else {
            const calendarPeriod = this.normalizeFinancePeriod(periodRaw);
            const bounds = this.getCalendarPeriodBounds(calendarPeriod);
            ps = bounds.start;
            pe = bounds.end;
            period = calendarPeriod;
        }
        const now = new Date();
        const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        dayStart.setHours(0, 0, 0, 0);
        const dayEnd = new Date(dayStart);
        dayEnd.setHours(23, 59, 59, 999);
        const [revenuePeriod, revenueToday, expensesPeriod, expensesToday] = await Promise.all([
            this.sumPayments(ps, pe),
            this.sumPayments(dayStart, dayEnd),
            this.sumExpenses(ps, pe),
            this.sumExpenses(dayStart, dayEnd),
        ]);
        return {
            revenueTodayFcfa: revenueToday.toFixed(2),
            expensesTodayFcfa: expensesToday.toFixed(2),
            revenuePeriodFcfa: revenuePeriod.toFixed(2),
            expensesPeriodFcfa: expensesPeriod.toFixed(2),
            period,
            periodFrom: this.toIsoDate(ps),
            periodTo: this.toIsoDate(pe),
        };
    }
    parseDateBoundary(raw, edge) {
        if (!raw)
            return null;
        const s = raw.trim();
        if (!s)
            return null;
        const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(s);
        if (!m)
            return null;
        const y = Number(m[1]);
        const mo = Number(m[2]) - 1;
        const d = Number(m[3]);
        const dt = new Date(y, mo, d);
        if (Number.isNaN(dt.getTime()))
            return null;
        if (edge === 'start') {
            dt.setHours(0, 0, 0, 0);
        }
        else {
            dt.setHours(23, 59, 59, 999);
        }
        return dt;
    }
    toIsoDate(d) {
        const y = d.getFullYear();
        const m = `${d.getMonth() + 1}`.padStart(2, '0');
        const dd = `${d.getDate()}`.padStart(2, '0');
        return `${y}-${m}-${dd}`;
    }
    resolveReportPeriod(periodRaw, fromRaw, toRaw) {
        const customFrom = this.parseDateBoundary(fromRaw, 'start');
        const customTo = this.parseDateBoundary(toRaw, 'end');
        if (customFrom && customTo) {
            let ps = customFrom.getTime() <= customTo.getTime() ? customFrom : customTo;
            let pe = customFrom.getTime() <= customTo.getTime() ? customTo : customFrom;
            ps.setHours(0, 0, 0, 0);
            pe.setHours(23, 59, 59, 999);
            return { period: 'custom', ps, pe };
        }
        const calendarPeriod = this.normalizeFinancePeriod(periodRaw);
        const bounds = this.getCalendarPeriodBounds(calendarPeriod);
        return { period: calendarPeriod, ps: bounds.start, pe: bounds.end };
    }
    isDiscountPaymentReference(reference) {
        return reference?.trim().toUpperCase() === 'REMISE';
    }
    revenuePaymentSql(alias = 'pay') {
        return `(${alias}.reference IS NULL OR UPPER(TRIM(${alias}.reference)) <> 'REMISE')`;
    }
    async getSalesByUser(periodRaw, fromRaw, toRaw) {
        const { period, ps, pe } = this.resolveReportPeriod(periodRaw, fromRaw, toRaw);
        const rows = await this.orders
            .createQueryBuilder('o')
            .leftJoin('o.createdBy', 'u')
            .leftJoin('o.payments', 'pay')
            .select('u.id', 'userId')
            .addSelect('u.username', 'username')
            .addSelect('u.fullName', 'fullName')
            .addSelect('COUNT(DISTINCT o.id)', 'orderCount')
            .addSelect(`COALESCE(SUM(CASE WHEN ${this.revenuePaymentSql('pay')} THEN pay.amount ELSE 0 END), 0)`, 'revenue')
            .where('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: ps, b: pe })
            .groupBy('u.id')
            .addGroupBy('u.username')
            .addGroupBy('u.fullName')
            .orderBy(`COALESCE(SUM(CASE WHEN ${this.revenuePaymentSql('pay')} THEN pay.amount ELSE 0 END), 0)`, 'DESC')
            .getRawMany();
        const totalsRaw = await this.orders
            .createQueryBuilder('o')
            .select('COUNT(DISTINCT o.id)', 'orders')
            .leftJoin('o.payments', 'pay')
            .addSelect(`COALESCE(SUM(CASE WHEN ${this.revenuePaymentSql('pay')} THEN pay.amount ELSE 0 END), 0)`, 'revenue')
            .where('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: ps, b: pe })
            .getRawOne();
        const totalRevenue = Number(totalsRaw?.revenue ?? 0);
        const totalOrders = Number(totalsRaw?.orders ?? 0);
        const users = rows.map((r) => {
            const rev = Number(r.revenue ?? 0);
            const uname = r.username?.trim();
            const fname = r.fullName?.trim();
            const label = fname?.length
                ? `${fname} (@${uname ?? '?'})`
                : uname?.length
                    ? uname
                    : 'Non assigné';
            return {
                userId: r.userId ?? null,
                username: uname ?? null,
                fullName: fname ?? null,
                displayName: label,
                orderCount: Number(r.orderCount) || 0,
                revenueFcfa: rev.toFixed(2),
                share: totalRevenue > 0 ? rev / totalRevenue : 0,
            };
        });
        return {
            period,
            periodFrom: this.toIsoDate(ps),
            periodTo: this.toIsoDate(pe),
            totalRevenueFcfa: totalRevenue.toFixed(2),
            totalOrders,
            users,
        };
    }
    async getMySales(userId, periodRaw, fromRaw, toRaw, topLimit = 8) {
        if (!userId) {
            throw new common_1.ForbiddenException('Utilisateur non identifié');
        }
        const { period, ps, pe } = this.resolveReportPeriod(periodRaw, fromRaw, toRaw);
        const now = new Date();
        const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        dayStart.setHours(0, 0, 0, 0);
        const dayEnd = new Date(dayStart);
        dayEnd.setHours(23, 59, 59, 999);
        const userFilter = (qb) => qb.innerJoin('o.createdBy', 'creator').andWhere('creator.id = :userId', { userId });
        const [revenuePeriod, revenueToday, orderCountPeriod, orderCountToday] = await Promise.all([
            this.sumUserOrderPayments(userId, ps, pe),
            this.sumUserOrderPayments(userId, dayStart, dayEnd),
            this.countUserPaidOrders(userId, ps, pe),
            this.countUserPaidOrders(userId, dayStart, dayEnd),
        ]);
        const topRaw = await userFilter(this.orderItems
            .createQueryBuilder('oi')
            .innerJoin('oi.order', 'o'))
            .leftJoin('oi.product', 'p')
            .select('p.id', 'productId')
            .addSelect('COALESCE(p.name, oi.productNameSnapshot)', 'name')
            .addSelect('SUM(oi.quantity)', 'qty')
            .addSelect('SUM(oi.quantity * oi.unitPrice)', 'revenue')
            .where('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: ps, b: pe })
            .groupBy('p.id')
            .addGroupBy('oi.productNameSnapshot')
            .orderBy('SUM(oi.quantity * oi.unitPrice)', 'DESC')
            .addOrderBy('SUM(oi.quantity)', 'DESC')
            .limit(topLimit)
            .getRawMany();
        const catRaw = await userFilter(this.orderItems
            .createQueryBuilder('oi')
            .innerJoin('oi.order', 'o'))
            .leftJoin('oi.product', 'p')
            .leftJoin('p.category', 'cat')
            .select('cat.id', 'categoryId')
            .addSelect("COALESCE(cat.labelFr, '(Sans catégorie)')", 'categoryName')
            .addSelect('SUM(oi.quantity)', 'qty')
            .addSelect('SUM(oi.quantity * oi.unitPrice)', 'revenue')
            .where('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: ps, b: pe })
            .groupBy('cat.id')
            .addGroupBy('cat.labelFr')
            .orderBy('SUM(oi.quantity * oi.unitPrice)', 'DESC')
            .getRawMany();
        const totalsRaw = await userFilter(this.orders
            .createQueryBuilder('o'))
            .select('COUNT(DISTINCT o.id)', 'orders')
            .leftJoin('o.items', 'oi')
            .addSelect('COALESCE(SUM(oi.quantity), 0)', 'units')
            .addSelect('COALESCE(SUM(oi.quantity * oi.unitPrice), 0)', 'grossRevenue')
            .where('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: ps, b: pe })
            .getRawOne();
        const grossRevenue = Number(totalsRaw?.grossRevenue ?? 0);
        const totalRevenue = revenuePeriod;
        const totalOrders = Number(totalsRaw?.orders ?? 0);
        const totalUnits = Number(totalsRaw?.units ?? 0);
        const netRatio = grossRevenue > 0 ? totalRevenue / grossRevenue : 1;
        const topProducts = topRaw.map((r) => ({
            productId: r.productId,
            name: r.name?.trim().length ? r.name : '(Article supprimé)',
            quantity: Number(r.qty) || 0,
            revenueFcfa: (Number(r.revenue ?? 0) * netRatio).toFixed(2),
        }));
        const byCategory = catRaw.map((r) => {
            const rev = Number(r.revenue ?? 0) * netRatio;
            return {
                categoryId: r.categoryId,
                categoryName: r.categoryName,
                quantity: Number(r.qty) || 0,
                revenueFcfa: rev.toFixed(2),
                share: totalRevenue > 0 ? rev / totalRevenue : 0,
            };
        });
        return {
            period,
            periodFrom: this.toIsoDate(ps),
            periodTo: this.toIsoDate(pe),
            revenueTodayFcfa: revenueToday.toFixed(2),
            orderCountToday,
            revenuePeriodFcfa: revenuePeriod.toFixed(2),
            orderCountPeriod,
            totalRevenueFcfa: totalRevenue.toFixed(2),
            totalOrders,
            totalUnits,
            topProducts,
            byCategory,
        };
    }
    async sumUserOrderPayments(userId, from, to) {
        const raw = await this.orders
            .createQueryBuilder('o')
            .innerJoin('o.createdBy', 'creator')
            .leftJoin('o.payments', 'pay')
            .select(`COALESCE(SUM(CASE WHEN ${this.revenuePaymentSql('pay')} THEN pay.amount ELSE 0 END), 0)`, 'total')
            .where('creator.id = :userId', { userId })
            .andWhere('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: from, b: to })
            .getRawOne();
        return Number(raw?.total ?? 0);
    }
    async countUserPaidOrders(userId, from, to) {
        return this.orders
            .createQueryBuilder('o')
            .innerJoin('o.createdBy', 'creator')
            .where('creator.id = :userId', { userId })
            .andWhere('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: from, b: to })
            .getCount();
    }
    async getSalesBreakdown(periodRaw, fromRaw, toRaw, topLimit = 8) {
        const { period, ps, pe } = this.resolveReportPeriod(periodRaw, fromRaw, toRaw);
        const topRaw = await this.orderItems
            .createQueryBuilder('oi')
            .innerJoin('oi.order', 'o')
            .leftJoin('oi.product', 'p')
            .select('p.id', 'productId')
            .addSelect('COALESCE(p.name, oi.productNameSnapshot)', 'name')
            .addSelect('SUM(oi.quantity)', 'qty')
            .addSelect('SUM(oi.quantity * oi.unitPrice)', 'revenue')
            .where('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: ps, b: pe })
            .groupBy('p.id')
            .addGroupBy('oi.productNameSnapshot')
            .orderBy('SUM(oi.quantity * oi.unitPrice)', 'DESC')
            .addOrderBy('SUM(oi.quantity)', 'DESC')
            .limit(topLimit)
            .getRawMany();
        const catRaw = await this.orderItems
            .createQueryBuilder('oi')
            .innerJoin('oi.order', 'o')
            .leftJoin('oi.product', 'p')
            .leftJoin('p.category', 'cat')
            .select('cat.id', 'categoryId')
            .addSelect("COALESCE(cat.labelFr, '(Sans catégorie)')", 'categoryName')
            .addSelect('SUM(oi.quantity)', 'qty')
            .addSelect('SUM(oi.quantity * oi.unitPrice)', 'revenue')
            .where('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: ps, b: pe })
            .groupBy('cat.id')
            .addGroupBy('cat.labelFr')
            .orderBy('SUM(oi.quantity * oi.unitPrice)', 'DESC')
            .getRawMany();
        const totalsRaw = await this.orders
            .createQueryBuilder('o')
            .select('COUNT(DISTINCT o.id)', 'orders')
            .leftJoin('o.items', 'oi')
            .addSelect('COALESCE(SUM(oi.quantity), 0)', 'units')
            .addSelect('COALESCE(SUM(oi.quantity * oi.unitPrice), 0)', 'grossRevenue')
            .where('o.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('o.createdAt BETWEEN :a AND :b', { a: ps, b: pe })
            .getRawOne();
        const grossRevenue = Number(totalsRaw?.grossRevenue ?? 0);
        const totalRevenue = await this.sumPayments(ps, pe);
        const totalOrders = Number(totalsRaw?.orders ?? 0);
        const totalUnits = Number(totalsRaw?.units ?? 0);
        const netRatio = grossRevenue > 0 ? totalRevenue / grossRevenue : 1;
        const topProducts = topRaw.map((r) => ({
            productId: r.productId,
            name: r.name?.trim().length ? r.name : '(Article supprimé)',
            quantity: Number(r.qty) || 0,
            revenueFcfa: (Number(r.revenue ?? 0) * netRatio).toFixed(2),
        }));
        const byCategory = catRaw.map((r) => {
            const rev = Number(r.revenue ?? 0) * netRatio;
            return {
                categoryId: r.categoryId,
                categoryName: r.categoryName,
                quantity: Number(r.qty) || 0,
                revenueFcfa: rev.toFixed(2),
                share: totalRevenue > 0 ? rev / totalRevenue : 0,
            };
        });
        return {
            period,
            periodFrom: this.toIsoDate(ps),
            periodTo: this.toIsoDate(pe),
            totalRevenueFcfa: totalRevenue.toFixed(2),
            totalOrders,
            totalUnits,
            topProducts,
            byCategory,
        };
    }
    normalizeFinancePeriod(raw) {
        const x = raw?.trim().toLowerCase();
        if (x === 'day' || x === 'jour' || x === 'd' || x === 'j')
            return 'day';
        if (x === 'week' || x === 'semaine' || x === 'w' || x === 's')
            return 'week';
        if (x === 'year' || x === 'annee' || x === 'année' || x === 'y')
            return 'year';
        return 'month';
    }
    startOfWeekMonday(day) {
        const x = new Date(day.getFullYear(), day.getMonth(), day.getDate());
        const dow = x.getDay();
        const mondayOffset = dow === 0 ? -6 : 1 - dow;
        x.setDate(x.getDate() + mondayOffset);
        x.setHours(0, 0, 0, 0);
        return x;
    }
    getCalendarPeriodBounds(period, ref = new Date()) {
        const d = new Date(ref.getFullYear(), ref.getMonth(), ref.getDate());
        if (period === 'day') {
            const start = new Date(d);
            start.setHours(0, 0, 0, 0);
            const end = new Date(start);
            end.setHours(23, 59, 59, 999);
            return { start, end };
        }
        if (period === 'week') {
            const start = this.startOfWeekMonday(d);
            const end = new Date(start);
            end.setDate(end.getDate() + 6);
            end.setHours(23, 59, 59, 999);
            return { start, end };
        }
        if (period === 'year') {
            const start = new Date(d.getFullYear(), 0, 1, 0, 0, 0, 0);
            const end = new Date(d.getFullYear(), 11, 31, 23, 59, 59, 999);
            return { start, end };
        }
        const start = new Date(d.getFullYear(), d.getMonth(), 1, 0, 0, 0, 0);
        const end = new Date(d.getFullYear(), d.getMonth() + 1, 0);
        end.setHours(23, 59, 59, 999);
        return { start, end };
    }
    async sumPayments(from, to) {
        const raw = await this.payments
            .createQueryBuilder('pay')
            .select('COALESCE(SUM(pay.amount), 0)', 'total')
            .innerJoin('pay.order', 'ord')
            .where('ord.status = :paid', { paid: enums_1.OrderWorkflowStatus.PAID })
            .andWhere('pay.createdAt BETWEEN :a AND :b', { a: from, b: to })
            .andWhere(this.revenuePaymentSql('pay'))
            .getRawOne();
        return Number(raw?.total ?? 0);
    }
    async sumExpenses(from, to) {
        const raw = await this.expenses
            .createQueryBuilder('e')
            .select('COALESCE(SUM(e.amount), 0)', 'total')
            .where('e.spentOn BETWEEN :a AND :b', { a: from, b: to })
            .getRawOne();
        return Number(raw?.total ?? 0);
    }
};
exports.DashboardService = DashboardService;
exports.DashboardService = DashboardService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(dining_table_entity_1.DiningTable)),
    __param(1, (0, typeorm_1.InjectRepository)(reservation_entity_1.Reservation)),
    __param(2, (0, typeorm_1.InjectRepository)(restaurant_order_entity_1.RestaurantOrder)),
    __param(3, (0, typeorm_1.InjectRepository)(order_item_entity_1.OrderItem)),
    __param(4, (0, typeorm_1.InjectRepository)(payment_entity_1.Payment)),
    __param(5, (0, typeorm_1.InjectRepository)(expense_entity_1.Expense)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], DashboardService);
//# sourceMappingURL=dashboard.service.js.map