import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { join } from 'path';

import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  app.enableCors({
    origin: true,
    credentials: true,
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidUnknownValues: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  const uploadsRoot = join(process.cwd(), 'uploads');
  app.useStaticAssets(uploadsRoot, { prefix: '/uploads/' });

  await app.listen(process.env.PORT ?? 3000);
}

void bootstrap().catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
