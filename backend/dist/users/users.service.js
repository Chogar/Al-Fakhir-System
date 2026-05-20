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
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const bcrypt = __importStar(require("bcrypt"));
const typeorm_2 = require("typeorm");
const app_permissions_1 = require("../auth/app-permissions");
const role_entity_1 = require("../database/entities/role.entity");
const user_entity_1 = require("../database/entities/user.entity");
let UsersService = class UsersService {
    users;
    roles;
    config;
    constructor(users, roles, config) {
        this.users = users;
        this.roles = roles;
        this.config = config;
    }
    bcryptRounds() {
        return +(this.config.get('BCRYPT_ROUNDS') ?? 10);
    }
    normalizeStoredPermissions(value) {
        const allowed = new Set(app_permissions_1.APP_PERMISSION_KEYS);
        const out = [];
        const seen = new Set();
        for (const item of value) {
            if (typeof item !== 'string') {
                throw new common_1.BadRequestException('Format de permissions invalide');
            }
            if (!allowed.has(item)) {
                throw new common_1.BadRequestException(`Permission inconnue : ${item}`);
            }
            if (!seen.has(item)) {
                seen.add(item);
                out.push(item);
            }
        }
        return out;
    }
    serializeStaff(u) {
        return {
            id: u.id,
            username: u.username,
            fullName: u.fullName,
            isActive: u.isActive,
            role: u.role ? { id: u.role.id, name: u.role.name } : null,
            permissions: u.permissions,
            effectivePermissions: (0, app_permissions_1.resolveEffectivePermissions)(u),
            createdAt: u.createdAt,
            updatedAt: u.updatedAt,
        };
    }
    serializeRole(r) {
        return { id: r.id, name: r.name };
    }
    async findAllStaffSerialized() {
        const rows = await this.users.find({
            relations: ['role'],
            order: { username: 'ASC' },
        });
        return rows.map((u) => this.serializeStaff(u));
    }
    async listRolesSerialized() {
        const rows = await this.roles.find({ order: { name: 'ASC' } });
        return rows.map((r) => this.serializeRole(r));
    }
    async findOneStaffSerialized(id) {
        const u = await this.users.findOne({
            where: { id },
            relations: ['role'],
        });
        if (!u)
            throw new common_1.NotFoundException('Utilisateur introuvable');
        return this.serializeStaff(u);
    }
    async createStaff(dto) {
        const uname = dto.username.trim();
        const exists = await this.users.findOne({ where: { username: uname } });
        if (exists) {
            throw new common_1.ConflictException('Ce nom d’utilisateur existe déjà');
        }
        const role = await this.roles.findOne({ where: { name: dto.role } });
        if (!role)
            throw new common_1.BadRequestException('Rôle invalide');
        const hash = await bcrypt.hash(dto.password, this.bcryptRounds());
        const perms = dto.permissions === undefined
            ? null
            : dto.permissions === null
                ? null
                : this.normalizeStoredPermissions(dto.permissions);
        const row = this.users.create({
            username: uname,
            passwordHash: hash,
            fullName: dto.fullName?.trim() ? dto.fullName.trim() : null,
            isActive: dto.isActive ?? true,
            role,
            permissions: perms,
        });
        await this.users.save(row);
        const full = await this.users.findOne({
            where: { id: row.id },
            relations: ['role'],
        });
        return this.serializeStaff(full);
    }
    async updateStaff(id, dto, actorId) {
        const row = await this.users.findOne({
            where: { id },
            relations: ['role'],
        });
        if (!row)
            throw new common_1.NotFoundException('Utilisateur introuvable');
        if (dto.isActive === false && id === actorId) {
            throw new common_1.ForbiddenException('Vous ne pouvez pas vous désactiver vous-même');
        }
        if (dto.fullName !== undefined) {
            row.fullName =
                dto.fullName === null || dto.fullName.trim() === ''
                    ? null
                    : dto.fullName.trim();
        }
        if (dto.role !== undefined) {
            const role = await this.roles.findOne({ where: { name: dto.role } });
            if (!role)
                throw new common_1.BadRequestException('Rôle invalide');
            row.role = role;
        }
        if (dto.password !== undefined && dto.password.length > 0) {
            row.passwordHash = await bcrypt.hash(dto.password, this.bcryptRounds());
        }
        if (dto.isActive !== undefined) {
            row.isActive = dto.isActive;
        }
        if (dto.permissions !== undefined) {
            row.permissions =
                dto.permissions === null
                    ? null
                    : this.normalizeStoredPermissions(dto.permissions);
        }
        await this.users.save(row);
        const full = await this.users.findOne({
            where: { id },
            relations: ['role'],
        });
        return this.serializeStaff(full);
    }
    async deactivateStaff(id, actorId) {
        return this.updateStaff(id, { isActive: false }, actorId);
    }
    async changePassword(username, currentPassword, newPassword) {
        const uname = username.trim();
        const user = await this.findByUsernameWithSecret(uname);
        if (!user) {
            throw new common_1.UnauthorizedException('Identifiants invalides');
        }
        const ok = await bcrypt.compare(currentPassword, user.passwordHash);
        if (!ok) {
            throw new common_1.UnauthorizedException('Mot de passe actuel incorrect');
        }
        user.passwordHash = await bcrypt.hash(newPassword, this.bcryptRounds());
        await this.users.save(user);
        return { ok: true };
    }
    findByUsernameWithSecret(username) {
        return this.users
            .createQueryBuilder('user')
            .addSelect('user.passwordHash')
            .leftJoinAndSelect('user.role', 'role')
            .where('user.username = :username', { username })
            .andWhere('user.isActive = :active', { active: true })
            .getOne();
    }
    findById(id) {
        return this.users.findOne({
            where: { id },
            relations: ['role'],
        });
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(1, (0, typeorm_1.InjectRepository)(role_entity_1.Role)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        config_1.ConfigService])
], UsersService);
//# sourceMappingURL=users.service.js.map