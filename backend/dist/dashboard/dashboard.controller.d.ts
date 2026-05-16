import { DashboardService } from './dashboard.service';
export declare class DashboardController {
    private readonly dashboard;
    constructor(dashboard: DashboardService);
    financeSummary(period?: string, from?: string, to?: string): Promise<import("./dashboard.service").DashboardFinanceSummary>;
    overview(): Promise<import("./dashboard.service").DashboardOverview>;
    salesBreakdown(period?: string, from?: string, to?: string, limit?: string): Promise<import("./dashboard.service").SalesBreakdown>;
}
