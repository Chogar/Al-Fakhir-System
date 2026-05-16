import { OnApplicationBootstrap } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';
import { Category } from '../database/entities/category.entity';
import { Role } from '../database/entities/role.entity';
import { User } from '../database/entities/user.entity';
export declare class SeedService implements OnApplicationBootstrap {
    private readonly config;
    private readonly roles;
    private readonly users;
    private readonly categories;
    private readonly logger;
    constructor(config: ConfigService, roles: Repository<Role>, users: Repository<User>, categories: Repository<Category>);
    onApplicationBootstrap(): Promise<void>;
    private seedRoles;
    private seedCategories;
    private seedAdmin;
}
