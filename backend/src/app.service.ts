import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
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
}
