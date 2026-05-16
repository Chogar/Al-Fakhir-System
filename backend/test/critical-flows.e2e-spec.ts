import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';

/**
 * Flux API critiques (nécessitent PostgreSQL joignable avec les mêmes
 * variables DATABASE_* que le fichier .env du backend).
 *
 *   cd backend && npm run test:e2e
 */
describe('Critical API flows (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidUnknownValues: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('GET /api/health → 200', () => {
    return request(app.getHttpServer())
      .get('/api/health')
      .expect(200)
      .expect({ service: 'al-fakhir-api', status: 'ok' });
  });

  it('POST /api/auth/login sans corps valide → 400', () => {
    return request(app.getHttpServer())
      .post('/api/auth/login')
      .send({})
      .expect(400);
  });

  it('POST /api/auth/login identifiants invalides → 401', () => {
    return request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ username: '__no_such_user__', password: 'wrong-pass-1234' })
      .expect(401);
  });

  it('POST /api/orders sans JWT → 401', () => {
    return request(app.getHttpServer())
      .post('/api/orders')
      .send({
        serviceType: 'TAKEAWAY',
        items: [
          {
            productId: '00000000-0000-4000-8000-000000000001',
            quantity: 1,
          },
        ],
      })
      .expect(401);
  });
});
