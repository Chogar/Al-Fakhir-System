import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { ExpensesService } from './expenses.service';
export declare class ExpensesController {
    private readonly expenses;
    constructor(expenses: ExpensesService);
    list(spentOnFrom?: string, spentOnTo?: string): Promise<import("../database/entities/expense.entity").Expense[]>;
    categories(): Promise<{
        category: string;
        usageCount: number;
    }[]>;
    getOne(id: string): Promise<import("../database/entities/expense.entity").Expense>;
    create(dto: CreateExpenseDto): Promise<import("../database/entities/expense.entity").Expense>;
    update(id: string, dto: UpdateExpenseDto): Promise<import("../database/entities/expense.entity").Expense>;
    remove(id: string): Promise<void>;
}
