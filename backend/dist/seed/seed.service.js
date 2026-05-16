"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var SeedService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SeedService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const bcrypt = __importStar(require("bcrypt"));
const typeorm_2 = require("typeorm");
const enums_1 = require("../common/enums");
const category_entity_1 = require("../database/entities/category.entity");
const role_entity_1 = require("../database/entities/role.entity");
const user_entity_1 = require("../database/entities/user.entity");
let SeedService = SeedService_1 = class SeedService {
    config;
    roles;
    users;
    categories;
    logger = new common_1.Logger(SeedService_1.name);
    constructor(config, roles, users, categories) {
        this.config = config;
        this.roles = roles;
        this.users = users;
        this.categories = categories;
    }
    async onApplicationBootstrap() {
        if (this.config.get('SEED_ADMIN', 'false') !== 'true') {
            return;
        }
        await this.seedRoles();
        await this.seedCategories();
        await this.seedAdmin();
    }
    async seedRoles() {
        for (const name of Object.values(enums_1.RoleName)) {
            const exists = await this.roles.findOne({ where: { name } });
            if (!exists) {
                await this.roles.save(this.roles.create({ name }));
                this.logger.log(`Rôle créé : ${name}`);
            }
        }
    }
    async seedCategories() {
        const defs = [
            {
                slug: enums_1.MenuCategorySlug.PLATS,
                labelFr: 'Plats',
                labelAr: 'أطباق',
                sortOrder: 0,
            },
            {
                slug: enums_1.MenuCategorySlug.BOISSONS,
                labelFr: 'Boissons',
                labelAr: 'مشروبات',
                sortOrder: 1,
            },
            {
                slug: enums_1.MenuCategorySlug.DESSERTS,
                labelFr: 'Desserts',
                labelAr: 'حلويات',
                sortOrder: 2,
            },
            {
                slug: enums_1.MenuCategorySlug.GRILLADES,
                labelFr: 'Grillades',
                labelAr: 'مشاوي',
                sortOrder: 3,
            },
        ];
        for (const def of defs) {
            const exists = await this.categories.findOne({
                where: { slug: def.slug },
            });
            if (!exists) {
                await this.categories.save(this.categories.create(def));
                this.logger.log(`Catégorie créée : ${def.slug}`);
            }
        }
    }
    async seedAdmin() {
        const username = String(this.config.get('ADMIN_USERNAME') ?? 'admin');
        const password = String(this.config.get('ADMIN_PASSWORD') ?? 'ChangeMe!123');
        const rounds = +this.config.get('BCRYPT_ROUNDS', '10');
        const passwordHash = await bcrypt.hash(password, rounds);
        const adminRole = await this.roles.findOneOrFail({
            where: { name: enums_1.RoleName.ADMIN },
        });
        const ensure = this.config.get('SEED_ENSURE_ADMIN_CREDENTIALS', 'false') === 'true';
        if (ensure) {
            const adminUser = await this.users
                .createQueryBuilder('user')
                .innerJoin('user.role', 'role')
                .where('role.name = :rn', { rn: enums_1.RoleName.ADMIN })
                .orderBy('user.createdAt', 'ASC')
                .getOne();
            if (adminUser) {
                const clash = await this.users.findOne({ where: { username } });
                if (clash && clash.id !== adminUser.id) {
                    this.logger.error(`SEED_ENSURE_ADMIN_CREDENTIALS : « ${username} » est déjà pris par un autre compte.`);
                    return;
                }
                await this.users.update({ id: adminUser.id }, {
                    username,
                    passwordHash,
                });
                this.logger.warn(`Identifiants administrateur synchronisés (connexion : ${username}). Mettez SEED_ENSURE_ADMIN_CREDENTIALS=false.`);
                return;
            }
        }
        const existing = await this.users.findOne({ where: { username } });
        if (existing) {
            return;
        }
        await this.users.save(this.users.create({
            username,
            passwordHash,
            fullName: 'Administrateur',
            role: adminRole,
        }));
        this.logger.warn(`Compte administrateur créé (${username}). Changez le mot de passe et désactivez SEED_ADMIN.`);
    }
};
exports.SeedService = SeedService;
exports.SeedService = SeedService = SeedService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(1, (0, typeorm_1.InjectRepository)(role_entity_1.Role)),
    __param(2, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(3, (0, typeorm_1.InjectRepository)(category_entity_1.Category)),
    __metadata("design:paramtypes", [config_1.ConfigService,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], SeedService);
//# sourceMappingURL=seed.service.js.map