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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var ProfilesController_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProfilesController = void 0;
const common_1 = require("@nestjs/common");
const profiles_service_1 = require("./profiles.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
let ProfilesController = ProfilesController_1 = class ProfilesController {
    profilesService;
    logger = new common_1.Logger(ProfilesController_1.name);
    constructor(profilesService) {
        this.profilesService = profilesService;
    }
    async getMyProfile(req) {
        this.logger.log('🔍 GET /profiles/me called');
        this.logger.debug(`User: ${JSON.stringify(req.user)}`);
        const userId = req.user.userId;
        const profile = await this.profilesService.getProfile(userId);
        this.logger.log(`Profile found: ${!!profile}`);
        if (!profile) {
            return {
                code: 404,
                message: '个人信息不存在',
                data: null,
            };
        }
        return {
            code: 200,
            message: '获取个人信息成功',
            data: profile,
        };
    }
    async updateMyProfile(req, body) {
        const userId = req.user.userId;
        const profile = await this.profilesService.updateProfile(userId, body);
        return {
            code: 200,
            message: '更新个人信息成功',
            data: profile,
        };
    }
    async updateMyCity(req, cityCode, cityName) {
        this.logger.log(`📍 PUT /profiles/me/city called`);
        this.logger.debug(`User: ${req.user.userId}, City: ${cityName} (${cityCode})`);
        const userId = req.user.userId;
        const profile = await this.profilesService.updateProfile(userId, {
            cityCode,
            cityName,
        });
        return {
            code: 200,
            message: '城市修改成功',
            data: profile,
        };
    }
};
exports.ProfilesController = ProfilesController;
__decorate([
    (0, common_1.Get)('me'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "getMyProfile", null);
__decorate([
    (0, common_1.Put)('me'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "updateMyProfile", null);
__decorate([
    (0, common_1.Put)('me/city'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('cityCode')),
    __param(2, (0, common_1.Body)('cityName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "updateMyCity", null);
exports.ProfilesController = ProfilesController = ProfilesController_1 = __decorate([
    (0, common_1.Controller)('profiles'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [profiles_service_1.ProfilesService])
], ProfilesController);
//# sourceMappingURL=profiles.controller.js.map