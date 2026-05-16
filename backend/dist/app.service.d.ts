export declare class AppService {
    root(): {
        service: string;
        message: string;
        endpoints: {
            health: string;
            login: string;
            categories: string;
            products: string;
            orders: string;
        };
    };
    health(): {
        service: string;
        status: string;
    };
}
