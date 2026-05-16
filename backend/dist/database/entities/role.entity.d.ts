import { RoleName } from '../../common/enums';
import { User } from './user.entity';
export declare class Role {
    id: string;
    name: RoleName;
    users: User[];
    createdAt: Date;
    updatedAt: Date;
}
