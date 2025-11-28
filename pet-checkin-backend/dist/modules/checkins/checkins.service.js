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
exports.CheckInsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../database/prisma.service");
let CheckInsService = class CheckInsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(userId, dto) {
        const pet = await this.prisma.pet.findUnique({
            where: { id: dto.petId },
        });
        if (!pet) {
            throw new common_1.NotFoundException('宠物不存在');
        }
        if (pet.userId !== userId) {
            throw new common_1.ForbiddenException('无权操作他人的宠物');
        }
        const checkIn = await this.prisma.checkIn.create({
            data: {
                userId,
                petId: dto.petId,
                content: dto.content,
                imageUrls: dto.imageUrls || [],
                videoUrl: dto.videoUrl,
                tags: dto.tags || [],
                address: dto.address,
                cityCode: dto.cityCode,
                cityName: dto.cityName,
                latitude: dto.latitude,
                longitude: dto.longitude,
            },
            include: {
                pet: {
                    select: {
                        id: true,
                        name: true,
                        breed: true,
                        avatarUrl: true,
                    },
                },
                user: {
                    select: {
                        id: true,
                        profile: {
                            select: {
                                id: true,
                                nickname: true,
                                avatarUrl: true,
                            },
                        },
                    },
                },
            },
        });
        return checkIn;
    }
    async findAll(dto) {
        const { cityCode, page = 1, limit = 20 } = dto;
        const skip = (page - 1) * limit;
        const where = {};
        if (cityCode) {
            where.cityCode = cityCode;
        }
        const [checkins, total] = await Promise.all([
            this.prisma.checkIn.findMany({
                where,
                skip,
                take: limit,
                orderBy: {
                    createdAt: 'desc',
                },
                include: {
                    pet: {
                        select: {
                            id: true,
                            name: true,
                            breed: true,
                            avatarUrl: true,
                        },
                    },
                    user: {
                        select: {
                            id: true,
                            profile: {
                                select: {
                                    id: true,
                                    nickname: true,
                                    avatarUrl: true,
                                },
                            },
                        },
                    },
                    _count: {
                        select: {
                            likes: true,
                            comments: true,
                        },
                    },
                },
            }),
            this.prisma.checkIn.count({ where }),
        ]);
        return {
            data: checkins,
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        };
    }
    async findOne(id) {
        const checkIn = await this.prisma.checkIn.findUnique({
            where: { id },
            include: {
                pet: {
                    select: {
                        id: true,
                        name: true,
                        breed: true,
                        avatarUrl: true,
                    },
                },
                user: {
                    select: {
                        id: true,
                        profile: {
                            select: {
                                id: true,
                                nickname: true,
                                avatarUrl: true,
                            },
                        },
                    },
                },
                _count: {
                    select: {
                        likes: true,
                        comments: true,
                    },
                },
            },
        });
        if (!checkIn) {
            throw new common_1.NotFoundException('打卡记录不存在');
        }
        return checkIn;
    }
    async findMyCheckIns(userId, page = 1, limit = 20) {
        const skip = (page - 1) * limit;
        const [checkins, total] = await Promise.all([
            this.prisma.checkIn.findMany({
                where: { userId },
                skip,
                take: limit,
                orderBy: {
                    createdAt: 'desc',
                },
                include: {
                    pet: {
                        select: {
                            id: true,
                            name: true,
                            breed: true,
                            avatarUrl: true,
                        },
                    },
                    _count: {
                        select: {
                            likes: true,
                            comments: true,
                        },
                    },
                },
            }),
            this.prisma.checkIn.count({ where: { userId } }),
        ]);
        return {
            data: checkins,
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        };
    }
    async remove(id, userId) {
        const checkIn = await this.prisma.checkIn.findUnique({
            where: { id },
        });
        if (!checkIn) {
            throw new common_1.NotFoundException('打卡记录不存在');
        }
        if (checkIn.userId !== userId) {
            throw new common_1.ForbiddenException('无权删除他人的打卡');
        }
        await this.prisma.checkIn.delete({
            where: { id },
        });
        return { message: '删除成功' };
    }
};
exports.CheckInsService = CheckInsService;
exports.CheckInsService = CheckInsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], CheckInsService);
//# sourceMappingURL=checkins.service.js.map