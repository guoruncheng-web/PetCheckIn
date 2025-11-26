import { PetsService } from './pets.service';
import { CreatePetDto } from './dto/create-pet.dto';
export declare class PetsController {
    private readonly petsService;
    constructor(petsService: PetsService);
    create(req: any, createPetDto: CreatePetDto): Promise<{
        code: number;
        data: {
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
        };
        message: string;
    }>;
    findMyPets(req: any): Promise<{
        code: number;
        data: {
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
        }[];
        message: string;
    }>;
    findOne(req: any, id: string): Promise<{
        code: number;
        data: {
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
        };
        message: string;
    }>;
    remove(req: any, id: string): Promise<{
        code: number;
        message: string;
    }>;
}
