import { PrismaService } from '../database/prisma.service';
import { CreatePetDto } from './dto/create-pet.dto';
export declare class PetsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(userId: string, createPetDto: CreatePetDto): Promise<{
        id: string;
        name: string;
        breed: string | null;
        gender: string | null;
        birthday: Date | null;
        weight: number | null;
        avatarUrl: string | null;
        description: string | null;
        imageUrls: string[];
        videoUrl: string | null;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
    }>;
    findMyPets(userId: string): Promise<{
        id: string;
        name: string;
        breed: string | null;
        gender: string | null;
        birthday: Date | null;
        weight: number | null;
        avatarUrl: string | null;
        description: string | null;
        imageUrls: string[];
        videoUrl: string | null;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
    }[]>;
    findOne(id: string, userId: string): Promise<{
        id: string;
        name: string;
        breed: string | null;
        gender: string | null;
        birthday: Date | null;
        weight: number | null;
        avatarUrl: string | null;
        description: string | null;
        imageUrls: string[];
        videoUrl: string | null;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
    }>;
    remove(id: string, userId: string): Promise<{
        message: string;
    }>;
}
