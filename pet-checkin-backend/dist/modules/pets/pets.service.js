"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PetsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../database/prisma.service");
let PetsService = class PetsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(userId, createPetDto) {
        const petCount = await this.prisma.pet.count({
            where: { userId },
        });
        if (petCount >= 5) {
            throw new common_1.BadRequestException('每个用户最多只能添加5只宠物');
        }
        if (createPetDto.imageUrls && createPetDto.imageUrls.length > 6) {
            throw new common_1.BadRequestException('最多只能上传6张照片');
        }
        const pet = await this.prisma.pet.create({
            data: {
                userId,
                name: createPetDto.name,
                breed: createPetDto.breed,
                gender: createPetDto.gender,
                birthday: createPetDto.birthday ? new Date(createPetDto.birthday) : undefined,
                weight: createPetDto.weight,
                avatarUrl: createPetDto.avatarUrl,
                description: createPetDto.description,
                imageUrls: createPetDto.imageUrls || [],
                videoUrl: createPetDto.videoUrl,
            },
        });
        return pet;
    }
    async findMyPets(userId) {
        const pets = await this.prisma.pet.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
        return pets;
    }
    async findOne(id, userId) {
        const pet = await this.prisma.pet.findFirst({
            where: { id, userId },
        });
        if (!pet) {
            throw new common_1.NotFoundException('宠物不存在');
        }
        return pet;
    }
    async remove(id, userId) {
        const pet = await this.findOne(id, userId);
        await this.prisma.pet.delete({
            where: { id: pet.id },
        });
        return { message: '删除成功' };
    }
};
exports.PetsService = PetsService;
exports.PetsService = PetsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PetsService);
//# sourceMappingURL=pets.service.js.map