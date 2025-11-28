import { PetsService } from './pets.service';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';
export declare class PetsController {
    private readonly petsService;
    constructor(petsService: PetsService);
    create(req: any, createPetDto: CreatePetDto): Promise<{
        code: number;
        data: {
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
        };
        message: string;
    }>;
    findMyPets(req: any): Promise<{
        code: number;
        data: {
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
        }[];
        message: string;
    }>;
    findOne(req: any, id: string): Promise<{
        code: number;
        data: {
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
        };
        message: string;
    }>;
    update(req: any, id: string, updatePetDto: UpdatePetDto): Promise<{
        code: number;
        data: {
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
        };
        message: string;
    }>;
    remove(req: any, id: string): Promise<{
        code: number;
        message: string;
    }>;
}
