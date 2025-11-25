# NestJS 后端架构设计

## 技术栈

### 核心框架
- **NestJS**: 基于 TypeScript 的 Node.js 框架
- **PostgreSQL**: 关系型数据库
- **Prisma / TypeORM**: ORM 框架（推荐 Prisma）
- **Redis**: 缓存和 Session 存储

### 第三方服务
- **阿里云 SMS**: 短信验证码服务
- **阿里云 OSS**: 对象存储服务（图片、文件）

### 认证与安全
- **Passport.js**: 认证中间件
- **JWT**: Token 认证
- **bcrypt**: 密码加密

### 实时通信
- **Socket.IO**: WebSocket 实时推送（点赞、评论通知）

### 其他工具
- **class-validator**: 参数校验
- **class-transformer**: 数据转换
- **multer**: 文件上传
- **winston**: 日志系统

## 项目目录结构

```
pet-checkin-backend/
├── src/
│   ├── main.ts                          # 应用入口
│   ├── app.module.ts                    # 根模块
│   │
│   ├── common/                          # 公共模块
│   │   ├── decorators/                  # 自定义装饰器
│   │   │   ├── current-user.decorator.ts
│   │   │   └── roles.decorator.ts
│   │   ├── filters/                     # 异常过滤器
│   │   │   └── http-exception.filter.ts
│   │   ├── guards/                      # 守卫
│   │   │   ├── jwt-auth.guard.ts
│   │   │   └── roles.guard.ts
│   │   ├── interceptors/                # 拦截器
│   │   │   └── transform.interceptor.ts
│   │   ├── pipes/                       # 管道
│   │   │   └── validation.pipe.ts
│   │   └── interfaces/                  # 公共接口
│   │
│   ├── config/                          # 配置模块
│   │   ├── configuration.ts             # 配置加载
│   │   ├── database.config.ts
│   │   ├── redis.config.ts
│   │   ├── aliyun-sms.config.ts
│   │   └── aliyun-oss.config.ts
│   │
│   ├── modules/
│   │   ├── auth/                        # 认证模块
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.module.ts
│   │   │   ├── strategies/
│   │   │   │   ├── jwt.strategy.ts
│   │   │   │   └── local.strategy.ts
│   │   │   └── dto/
│   │   │       ├── send-otp.dto.ts
│   │   │       ├── verify-otp.dto.ts
│   │   │       ├── login.dto.ts
│   │   │       └── register.dto.ts
│   │   │
│   │   ├── users/                       # 用户模块
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   ├── users.module.ts
│   │   │   ├── entities/
│   │   │   │   └── user.entity.ts
│   │   │   └── dto/
│   │   │       ├── create-user.dto.ts
│   │   │       └── update-user.dto.ts
│   │   │
│   │   ├── profiles/                    # 用户资料模块
│   │   │   ├── profiles.controller.ts
│   │   │   ├── profiles.service.ts
│   │   │   ├── profiles.module.ts
│   │   │   ├── entities/
│   │   │   │   └── profile.entity.ts
│   │   │   └── dto/
│   │   │       ├── create-profile.dto.ts
│   │   │       └── update-profile.dto.ts
│   │   │
│   │   ├── pets/                        # 宠物模块
│   │   │   ├── pets.controller.ts
│   │   │   ├── pets.service.ts
│   │   │   ├── pets.module.ts
│   │   │   ├── entities/
│   │   │   │   └── pet.entity.ts
│   │   │   └── dto/
│   │   │       ├── create-pet.dto.ts
│   │   │       └── update-pet.dto.ts
│   │   │
│   │   ├── checkins/                    # 打卡模块
│   │   │   ├── checkins.controller.ts
│   │   │   ├── checkins.service.ts
│   │   │   ├── checkins.module.ts
│   │   │   ├── entities/
│   │   │   │   └── checkin.entity.ts
│   │   │   └── dto/
│   │   │       ├── create-checkin.dto.ts
│   │   │       └── query-checkin.dto.ts
│   │   │
│   │   ├── likes/                       # 点赞模块
│   │   │   ├── likes.controller.ts
│   │   │   ├── likes.service.ts
│   │   │   ├── likes.module.ts
│   │   │   ├── entities/
│   │   │   │   └── like.entity.ts
│   │   │   └── dto/
│   │   │       └── toggle-like.dto.ts
│   │   │
│   │   ├── comments/                    # 评论模块
│   │   │   ├── comments.controller.ts
│   │   │   ├── comments.service.ts
│   │   │   ├── comments.module.ts
│   │   │   ├── entities/
│   │   │   │   └── comment.entity.ts
│   │   │   └── dto/
│   │   │       ├── create-comment.dto.ts
│   │   │       └── query-comment.dto.ts
│   │   │
│   │   ├── badges/                      # 徽章模块
│   │   │   ├── badges.controller.ts
│   │   │   ├── badges.service.ts
│   │   │   ├── badges.module.ts
│   │   │   ├── entities/
│   │   │   │   └── badge.entity.ts
│   │   │   └── dto/
│   │   │       └── award-badge.dto.ts
│   │   │
│   │   ├── sms/                         # 短信服务模块
│   │   │   ├── sms.service.ts
│   │   │   └── sms.module.ts
│   │   │
│   │   ├── storage/                     # 文件存储模块
│   │   │   ├── storage.controller.ts
│   │   │   ├── storage.service.ts
│   │   │   └── storage.module.ts
│   │   │
│   │   ├── notifications/               # 通知模块
│   │   │   ├── notifications.gateway.ts  # WebSocket Gateway
│   │   │   ├── notifications.service.ts
│   │   │   └── notifications.module.ts
│   │   │
│   │   └── database/                    # 数据库模块
│   │       ├── database.module.ts
│   │       └── prisma.service.ts
│   │
│   └── prisma/                          # Prisma 配置
│       ├── schema.prisma                # 数据库模型定义
│       └── migrations/                  # 数据库迁移文件
│
├── test/                                # 测试文件
├── .env.development                     # 开发环境变量
├── .env.production                      # 生产环境变量
├── .gitignore
├── nest-cli.json
├── package.json
├── tsconfig.json
└── README.md
```

## 数据库设计（Prisma Schema）

```prisma
// prisma/schema.prisma

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

// 用户表
model User {
  id            String      @id @default(uuid())
  phone         String      @unique
  password      String?     // 可选密码（支持密码登录）
  createdAt     DateTime    @default(now()) @map("created_at")
  updatedAt     DateTime    @updatedAt @map("updated_at")

  profile       Profile?
  pets          Pet[]
  checkins      CheckIn[]
  likes         Like[]
  comments      Comment[]
  badges        Badge[]

  @@map("users")
}

// 用户资料表
model Profile {
  id            String      @id @default(uuid())
  userId        String      @unique @map("user_id")
  nickname      String
  avatarUrl     String?     @map("avatar_url")
  bio           String?
  cityCode      String?     @map("city_code")
  cityName      String?     @map("city_name")
  createdAt     DateTime    @default(now()) @map("created_at")
  updatedAt     DateTime    @updatedAt @map("updated_at")

  user          User        @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("profiles")
}

// 宠物表
model Pet {
  id            String      @id @default(uuid())
  userId        String      @map("user_id")
  name          String
  breed         String?
  gender        String?
  birthday      DateTime?
  weight        Float?
  avatarUrl     String?     @map("avatar_url")
  createdAt     DateTime    @default(now()) @map("created_at")
  updatedAt     DateTime    @updatedAt @map("updated_at")

  user          User        @relation(fields: [userId], references: [id], onDelete: Cascade)
  checkins      CheckIn[]

  @@unique([userId, name])
  @@map("pets")
}

// 打卡表
model CheckIn {
  id            String      @id @default(uuid())
  userId        String      @map("user_id")
  petId         String      @map("pet_id")
  content       String?
  imageUrls     String[]    @map("image_urls")
  cityCode      String?     @map("city_code")
  cityName      String?     @map("city_name")
  latitude      Float?
  longitude     Float?
  createdAt     DateTime    @default(now()) @map("created_at")
  updatedAt     DateTime    @updatedAt @map("updated_at")

  user          User        @relation(fields: [userId], references: [id], onDelete: Cascade)
  pet           Pet         @relation(fields: [petId], references: [id], onDelete: Cascade)
  likes         Like[]
  comments      Comment[]

  @@index([userId, createdAt])
  @@index([cityCode, createdAt])
  @@map("checkins")
}

// 点赞表
model Like {
  id            String      @id @default(uuid())
  userId        String      @map("user_id")
  checkInId     String      @map("check_in_id")
  createdAt     DateTime    @default(now()) @map("created_at")

  user          User        @relation(fields: [userId], references: [id], onDelete: Cascade)
  checkIn       CheckIn     @relation(fields: [checkInId], references: [id], onDelete: Cascade)

  @@unique([userId, checkInId])
  @@map("likes")
}

// 评论表
model Comment {
  id            String      @id @default(uuid())
  userId        String      @map("user_id")
  checkInId     String      @map("check_in_id")
  content       String
  emoji         String?
  parentId      String?     @map("parent_id")
  createdAt     DateTime    @default(now()) @map("created_at")
  updatedAt     DateTime    @updatedAt @map("updated_at")

  user          User        @relation(fields: [userId], references: [id], onDelete: Cascade)
  checkIn       CheckIn     @relation(fields: [checkInId], references: [id], onDelete: Cascade)
  parent        Comment?    @relation("CommentReplies", fields: [parentId], references: [id])
  replies       Comment[]   @relation("CommentReplies")

  @@index([checkInId, createdAt])
  @@map("comments")
}

// 徽章表
model Badge {
  id            String      @id @default(uuid())
  userId        String      @map("user_id")
  type          String      // checkin_streak_7, checkin_streak_30, like_master, etc.
  level         Int         @default(1)
  awardedAt     DateTime    @default(now()) @map("awarded_at")
  meta          Json?       // 额外元数据

  user          User        @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, type])
  @@map("badges")
}
```

## API 接口设计

### 认证模块 (Auth)

#### 发送验证码
```
POST /api/auth/send-otp
Body: { "phone": "13800138000" }
Response: { "success": true, "expiresIn": 60 }
```

#### 验证码登录/注册
```
POST /api/auth/verify-otp
Body: { "phone": "13800138000", "code": "123456" }
Response: {
  "accessToken": "jwt-token",
  "isNewUser": true,
  "user": { "id": "uuid", "phone": "13800138000" }
}
```

#### 密码登录
```
POST /api/auth/login
Body: { "phone": "13800138000", "password": "password123" }
Response: {
  "accessToken": "jwt-token",
  "user": { "id": "uuid", "phone": "13800138000" }
}
```

#### 密码注册
```
POST /api/auth/register
Body: { "phone": "13800138000", "password": "password123", "nickname": "宠友" }
Response: {
  "accessToken": "jwt-token",
  "user": { "id": "uuid", "phone": "13800138000" }
}
```

#### 登出
```
POST /api/auth/logout
Headers: { "Authorization": "Bearer jwt-token" }
Response: { "success": true }
```

### 用户资料模块 (Profiles)

#### 获取用户资料
```
GET /api/profiles/:userId
Response: {
  "id": "uuid",
  "nickname": "宠友",
  "avatarUrl": "https://oss.example.com/avatar.jpg",
  "bio": "爱宠人士",
  "cityName": "北京"
}
```

#### 更新用户资料
```
PATCH /api/profiles/:userId
Headers: { "Authorization": "Bearer jwt-token" }
Body: { "nickname": "新昵称", "bio": "新简介" }
Response: { ... }
```

#### 上传头像
```
POST /api/profiles/:userId/avatar
Headers: { "Authorization": "Bearer jwt-token" }
Content-Type: multipart/form-data
Body: { "file": <image-file> }
Response: { "avatarUrl": "https://oss.example.com/avatar.jpg" }
```

### 宠物模块 (Pets)

#### 获取我的宠物列表
```
GET /api/pets
Headers: { "Authorization": "Bearer jwt-token" }
Response: {
  "data": [
    { "id": "uuid", "name": "小白", "breed": "金毛", "avatarUrl": "..." }
  ],
  "total": 2
}
```

#### 添加宠物
```
POST /api/pets
Headers: { "Authorization": "Bearer jwt-token" }
Body: {
  "name": "小白",
  "breed": "金毛",
  "gender": "male",
  "birthday": "2020-01-01"
}
Response: { "id": "uuid", ... }
```

#### 更新宠物信息
```
PATCH /api/pets/:petId
Headers: { "Authorization": "Bearer jwt-token" }
Body: { "name": "小白白" }
Response: { ... }
```

#### 删除宠物
```
DELETE /api/pets/:petId
Headers: { "Authorization": "Bearer jwt-token" }
Response: { "success": true }
```

### 打卡模块 (CheckIns)

#### 创建打卡
```
POST /api/checkins
Headers: { "Authorization": "Bearer jwt-token" }
Body: {
  "petId": "uuid",
  "content": "今天天气不错",
  "imageUrls": ["https://oss.example.com/image1.jpg"],
  "cityCode": "110000",
  "cityName": "北京"
}
Response: { "id": "uuid", ... }
```

#### 获取今日打卡
```
GET /api/checkins/today
Headers: { "Authorization": "Bearer jwt-token" }
Response: {
  "data": [
    { "id": "uuid", "content": "...", "createdAt": "2024-01-01T10:00:00Z" }
  ]
}
```

#### 获取广场动态（同城）
```
GET /api/checkins/square?cityCode=110000&page=1&limit=20
Response: {
  "data": [...],
  "total": 100,
  "page": 1,
  "limit": 20
}
```

#### 获取打卡详情
```
GET /api/checkins/:checkInId
Response: {
  "id": "uuid",
  "content": "...",
  "user": { "nickname": "...", "avatarUrl": "..." },
  "pet": { "name": "...", "avatarUrl": "..." },
  "likesCount": 10,
  "commentsCount": 5,
  "isLiked": false
}
```

### 点赞模块 (Likes)

#### 点赞/取消点赞
```
POST /api/likes/toggle
Headers: { "Authorization": "Bearer jwt-token" }
Body: { "checkInId": "uuid" }
Response: { "isLiked": true, "likesCount": 11 }
```

#### 获取打卡的点赞列表
```
GET /api/likes?checkInId=uuid&page=1&limit=20
Response: {
  "data": [
    { "user": { "nickname": "...", "avatarUrl": "..." }, "createdAt": "..." }
  ],
  "total": 50
}
```

### 评论模块 (Comments)

#### 创建评论
```
POST /api/comments
Headers: { "Authorization": "Bearer jwt-token" }
Body: {
  "checkInId": "uuid",
  "content": "好可爱！",
  "emoji": "😍",
  "parentId": null
}
Response: { "id": "uuid", ... }
```

#### 获取打卡的评论列表
```
GET /api/comments?checkInId=uuid&page=1&limit=20
Response: {
  "data": [
    {
      "id": "uuid",
      "content": "...",
      "user": { "nickname": "...", "avatarUrl": "..." },
      "replies": [...],
      "createdAt": "..."
    }
  ],
  "total": 30
}
```

#### 删除评论
```
DELETE /api/comments/:commentId
Headers: { "Authorization": "Bearer jwt-token" }
Response: { "success": true }
```

### 徽章模块 (Badges)

#### 获取我的徽章
```
GET /api/badges
Headers: { "Authorization": "Bearer jwt-token" }
Response: {
  "data": [
    { "type": "checkin_streak_7", "level": 1, "awardedAt": "..." }
  ]
}
```

### 文件存储模块 (Storage)

#### 上传图片
```
POST /api/storage/upload
Headers: { "Authorization": "Bearer jwt-token" }
Content-Type: multipart/form-data
Body: { "file": <image-file>, "type": "avatar" | "pet" | "checkin" }
Response: { "url": "https://oss.example.com/xxx.jpg" }
```

## 环境变量配置

```env
# .env.development

# 应用配置
NODE_ENV=development
PORT=3000
API_PREFIX=api

# 数据库配置
DATABASE_URL=postgresql://user:password@localhost:5432/pet_checkin_dev

# Redis 配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT 配置
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=7d

# 阿里云 SMS 配置
ALIYUN_SMS_ACCESS_KEY_ID=your-access-key-id
ALIYUN_SMS_ACCESS_KEY_SECRET=your-access-key-secret
ALIYUN_SMS_SIGN_NAME=宠物打卡
ALIYUN_SMS_TEMPLATE_CODE=SMS_123456789
ALIYUN_SMS_REGION=cn-hangzhou

# 阿里云 OSS 配置
ALIYUN_OSS_ACCESS_KEY_ID=your-access-key-id
ALIYUN_OSS_ACCESS_KEY_SECRET=your-access-key-secret
ALIYUN_OSS_REGION=oss-cn-hangzhou
ALIYUN_OSS_BUCKET=pet-checkin
ALIYUN_OSS_ENDPOINT=https://oss-cn-hangzhou.aliyuncs.com

# OTP 配置
OTP_EXPIRES_IN=60
OTP_RETRY_LIMIT=5
```

## 权限控制设计

### 使用 Guard 实现权限控制

```typescript
// 示例：宠物管理权限
@Controller('pets')
@UseGuards(JwtAuthGuard)
export class PetsController {

  @Get()
  findMyPets(@CurrentUser() user: User) {
    return this.petsService.findByUserId(user.id);
  }

  @Patch(':id')
  @UseGuards(PetOwnerGuard) // 只有宠物主人才能更新
  updatePet(@Param('id') id: string, @Body() dto: UpdatePetDto) {
    return this.petsService.update(id, dto);
  }
}
```

### PetOwnerGuard 实现

```typescript
@Injectable()
export class PetOwnerGuard implements CanActivate {
  constructor(private petsService: PetsService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const petId = request.params.id;

    const pet = await this.petsService.findOne(petId);
    return pet.userId === user.id;
  }
}
```

## 实时通知设计（WebSocket）

```typescript
// notifications.gateway.ts
@WebSocketGateway({ cors: true })
export class NotificationsGateway {

  @SubscribeMessage('subscribe_checkin')
  handleSubscribe(
    @MessageBody() data: { checkInId: string },
    @ConnectedSocket() client: Socket
  ) {
    client.join(`checkin:${data.checkInId}`);
  }

  // 当有新点赞时，服务端推送
  async notifyNewLike(checkInId: string, like: Like) {
    this.server.to(`checkin:${checkInId}`).emit('new_like', like);
  }

  // 当有新评论时，服务端推送
  async notifyNewComment(checkInId: string, comment: Comment) {
    this.server.to(`checkin:${checkInId}`).emit('new_comment', comment);
  }
}
```

## 徽章自动授予逻辑

### 使用 Cron Job 自动检查

```typescript
// badges.service.ts
@Injectable()
export class BadgesService {

  @Cron('0 2 * * *') // 每天凌晨2点执行
  async checkAndAwardBadges() {
    const users = await this.usersService.findAll();

    for (const user of users) {
      await this.checkStreakBadge(user.id);
      await this.checkLikeBadge(user.id);
    }
  }

  private async checkStreakBadge(userId: string) {
    const streak = await this.checkinsService.calculateStreak(userId);

    if (streak >= 7) {
      await this.awardBadge(userId, 'checkin_streak_7');
    }
    if (streak >= 30) {
      await this.awardBadge(userId, 'checkin_streak_30');
    }
  }
}
```

## 部署建议

### Docker Compose 部署

```yaml
version: '3.8'

services:
  # NestJS 应用
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - postgres
      - redis
    restart: always

  # PostgreSQL
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: pet_checkin
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  # Redis
  redis:
    image: redis:7-alpine
    restart: always

volumes:
  postgres_data:
```

## 迁移步骤

1. **创建 NestJS 项目**
   ```bash
   nest new pet-checkin-backend
   cd pet-checkin-backend
   ```

2. **安装依赖**
   ```bash
   npm install @nestjs/config @nestjs/passport @nestjs/jwt passport passport-jwt
   npm install @prisma/client
   npm install -D prisma
   npm install bcrypt class-validator class-transformer
   npm install ali-oss @alicloud/sms-sdk
   npm install @nestjs/websockets @nestjs/platform-socket.io
   npm install redis ioredis @nestjs/schedule
   ```

3. **初始化 Prisma**
   ```bash
   npx prisma init
   # 编辑 prisma/schema.prisma
   npx prisma migrate dev --name init
   ```

4. **配置环境变量**
   - 创建 `.env.development` 和 `.env.production`
   - 配置数据库、阿里云 SMS、阿里云 OSS 等凭证

5. **实现各模块功能**
   - 按照上述目录结构创建各模块
   - 实现认证、用户、宠物、打卡等功能

6. **修改 Flutter 代码**
   - 替换 `SupabaseService` 为 `ApiService`
   - 使用 REST API 替代 Supabase 客户端调用
   - 实现 WebSocket 连接用于实时通知

## 下一步

你想要我：
1. **立即创建 NestJS 项目脚手架**
2. **先编写详细的 API 文档和数据库迁移脚本**
3. **开始修改 Flutter 代码以适配新后端**

请选择你想先进行的步骤。
