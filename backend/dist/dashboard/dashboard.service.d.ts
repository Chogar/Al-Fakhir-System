import { Repository } from 'typeorm';
import { DiningTable } from '../database/entities/dining-table.entity';
import { Expense } from '../database/entities/expense.entity';
import { OrderItem } from '../database/entities/order-item.entity';
import { Payment } from '../database/entities/payment.entity';
import { Reservation } from '../database/entities/reservation.entity';
import { RestaurantOrder } from '../database/entities/restaurant-order.entity';
export type DashboardOverview = {
    tables: {
        total: number;
        free: number;
        occupied: number;
        reserved: number;
        cleaning: number;
    };
    reservationsToday: number;
    ordersInProgress: number;
};
export type DashboardFinanceSummary = {
    revenueTodayFcfa: string;
    expensesTodayFcfa: string;
    revenuePeriodFcfa: string;
    expensesPeriodFcfa: string;
    period: 'day' | 'week' | 'month' | 'year' | 'custom';
    periodFrom: string;
    periodTo: string;
};
export type SalesBreakdown = {
    period: 'day' | 'week' | 'month' | 'year' | 'custom';
    periodFrom: string;
    periodTo: string;
    totalRevenueFcfa: string;
    totalOrders: number;
    totalUnits: number;
    topProducts: Array<{
        productId: string | null;
        name: string;
        quantity: number;
        revenueFcfa: string;
    }>;
    byCategory: Array<{
        categoryId: string | null;
        categoryName: string;
        quantity: number;
        revenueFcfa: string;
        share: number;
    }>;
};
export declare class DashboardService {
    private readonly tables;
    private readonly reservations;
    private readonly orders;
    private readonly orderItems;
    private readonly payments;
    private readonly expenses;
    constructor(tables: Repository<DiningTable>, reservations: Repository<Reservation>, orders: Repository<RestaurantOrder>, orderItems: Repository<OrderItem>, payments: Repository<Payment>, expenses: Repository<Expense>);
    getOverview(): Promise<DashboardOverview>;
    getFinanceSummary(periodRaw?: string, fromRaw?: string, toRaw?: string): Promise<DashboardFinanceSummary>;
    private parseDateBoundary;
    private toIsoDate;
    getSalesBreakdown(periodRaw?: string, fromRaw?: string, toRaw?: string, topLimit?: number): Promise<SalesBreakdown>;
    private normalizeFinancePeriod;
    private startOfWeekMonday;
    private getCalendarPeriodBounds;
    private sumPayments;
    private sumExpenses;
}
