import { PrismaService } from '../database/prisma.service';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';
export declare class PetsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(userId: string, createPetDto: CreatePetDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        avatarUrl: string | null;
        gender: string | null;
        birthday: Date | null;
        userId: string;
        imageUrls: string[];
        videoUrl: string | null;
        breed: string | null;
        weight: number | null;
        description: string | null;
    }>;
    findMyPets(userId: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        avatarUrl: string | null;
        gender: string | null;
        birthday: Date | null;
        userId: string;
        imageUrls: string[];
        videoUrl: string | null;
        breed: string | null;
        weight: number | null;
        description: string | null;
    }[]>;
    findOne(id: string, userId: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        avatarUrl: string | null;
        gender: string | null;
        birthday: Date | null;
        userId: string;
        imageUrls: string[];
        videoUrl: string | null;
        breed: string | null;
        weight: number | null;
        description: string | null;
    }>;
    update(id: string, userId: string, updatePetDto: UpdatePetDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        avatarUrl: string | null;
        gender: string | null;
        birthday: Date | null;
        userId: string;
        imageUrls: string[];
        videoUrl: string | null;
        breed: string | null;
        weight: number | null;
        description: string | null;
    }>;
    remove(id: string, userId: string): Promise<{
        message: string;
    }>;
}
