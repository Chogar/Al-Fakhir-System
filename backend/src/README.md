## Source backend

Ce dossier réintroduit une base source TypeScript pour l'API.

- Point d'entrée: `main.ts`
- Module/app santé: `app.module.ts`, `app.controller.ts`, `app.service.ts`
- Validation métier réutilisable: `orders/order-validation.ts`

Scripts:

- `npm run build` compile `src` vers `dist`
- `npm run start:dev` compile puis démarre
- `npm test` lance les tests backend
