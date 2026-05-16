import { Repository } from 'typeorm';
import { Expense } from '../database/entities/expense.entity';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
export declare class ExpensesService {
    private readonly expenses;
    constructor(expenses: Repository<Expense>);
    findAll(opts?: {
        spentOnFrom?: string;
        spentOnTo?: string;
    }): Promise<Expense[]>;
    findOne(id: string): Promise<Expense>;
    create(dto: CreateExpenseDto): Promise<Expense>;
    update(id: string, dto: UpdateExpenseDto): Promise<Expense>;
    remove(id: string): Promise<void>;
    listDistinctCategories(): Promise<Array<{
        category: string;
        usageCount: number;
    }>>;
}
