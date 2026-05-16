import { AppService } from './app.service';
export declare class AppController {
    private readonly appService;
    constructor(appService: AppService);
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
