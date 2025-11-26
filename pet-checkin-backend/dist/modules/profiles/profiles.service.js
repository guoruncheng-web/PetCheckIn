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
exports.ProfilesService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../database/prisma.service");
let ProfilesService = class ProfilesService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getProfile(userId) {
        let profile = await this.prisma.profile.findUnique({
            where: { userId },
            include: {
                user: {
                    select: {
                        phone: true,
                    },
                },
            },
        });
        if (!profile) {
            const user = await this.prisma.user.findUnique({
                where: { id: userId },
                select: { phone: true },
            });
            if (!user) {
                return null;
            }
            const defaultNickname = `宠友${user.phone.slice(-4)}`;
            const newProfile = await this.prisma.profile.create({
                data: {
                    userId,
                    nickname: defaultNickname,
                },
            });
            profile = {
                ...newProfile,
                user,
            };
        }
        const [petsCount, checkinsCount, totalLikes] = await Promise.all([
            this.prisma.pet.count({ where: { userId } }),
            this.prisma.checkIn.count({ where: { userId } }),
            this.prisma.like.count({
                where: {
                    checkIn: {
                        userId,
                    },
                },
            }),
        ]);
        return {
            id: profile.id,
            userId: profile.userId,
            nickname: profile.nickname,
            avatarUrl: profile.avatarUrl,
            bio: profile.bio,
            gender: profile.gender,
            birthday: profile.birthday,
            phone: profile.user.phone,
            cityCode: profile.cityCode,
            cityName: profile.cityName || profile.cityCode,
            province: profile.cityName,
            isVerified: false,
            petsCount,
            checkinsCount,
            followingCount: 0,
            followerCount: 0,
            totalLikes,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
        };
    }
    async updateProfile(userId, data) {
        const updateData = { ...data };
        if (data.birthday) {
            updateData.birthday = new Date(data.birthday);
        }
        return this.prisma.profile.update({
            where: { userId },
            data: updateData,
        });
    }
};
exports.ProfilesService = ProfilesService;
exports.ProfilesService = ProfilesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ProfilesService);
//# sourceMappingURL=profiles.service.js.map