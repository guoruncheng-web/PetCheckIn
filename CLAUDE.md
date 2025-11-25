# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 提供在此代码库中工作的指导。

## 项目概述

Flutter + NestJS 宠物日常打卡应用：一个跨平台移动应用，支持宠物管理、每日打卡、社交广场和成就系统。主要功能包括宠物绑定（最多5只）、日常打卡记录、同城动态互动（点赞/评论）、徽章奖励机制。

**技术栈：**
- 前端：Flutter + Provider
- 后端：NestJS + PostgreSQL + Prisma
- 云服务：阿里云 SMS（短信验证码）+ 阿里云 OSS（文件存储）
- 实时通信：Socket.IO（WebSocket）
- 缓存：Redis

## 常用命令

### 开发相关

```bash
# 安装依赖
cd pet_checkin && flutter pub get

# 启动 iOS 模拟器
flutter emulators --launch apple_ios_simulator

# 启动项目（使用配置文件）
flutter run --dart-define-from-file=env/dev.json

# 在指定设备上运行
flutter run -d <device_id>

# 使用 API 服务器地址运行
flutter run --dart-define API_BASE_URL=http://localhost:3000/api

# 运行 iOS 模拟器
flutter run -d ios

# 运行 Android 模拟器
flutter run -d android
```

### 测试相关

```bash
cd pet_checkin

# 运行所有测试
flutter test

# 运行指定测试文件
flutter test test/smoke_test.dart

# 详细输出模式
flutter test -v
```

### 代码生成

```bash
cd pet_checkin

# 生成 JSON 序列化代码
flutter pub run build_runner build

# 监听模式，持续生成
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 代码检查与格式化

```bash
cd pet_checkin

# 分析代码
flutter analyze

# 格式化代码
flutter format .
```

## 架构设计

### 分层结构

```
UI 层 (pages/*/*, ui/**)
  ↓ 依赖
ViewModel/状态层 (view_models/*, provider/riverpod)
  ↓ 依赖
Repository 层 (repositories/*_repo.dart, repositories/*_repo_impl.dart)
  ↓ 依赖
Service 层 (services/api_service.dart, geolocator, image_picker)
  ↓ 依赖
Models 层 (models/*.dart)
```

### 目录结构

- **`lib/pages/`** - 功能页面组件（auth/, home/, square/, profile/）
- **`lib/ui/`** - 可复用 UI 组件和主题配置
  - `ui/components/` - 通用组件（AppBottomBar, AppRefresh 等）
  - `ui/theme/` - 应用主题配置（Material Design）
  - `ui/utils/` - UI 工具类（ScreenAdapter, UIKit）
- **`lib/models/`** - 数据模型（Profile, Pet, CheckIn, Badge, Like, Comment, Notification, Favorite）
- **`lib/repositories/`** - 数据访问层（Repository 模式，包含接口和实现）
- **`lib/services/`** - 外部服务集成（ApiService 单例，HTTP 请求封装）
- **`lib/view_models/`** - 业务逻辑和状态管理
- **`lib/routes.dart`** - 集中式路由配置
- **`lib/main.dart`** - 应用入口，包含 ApiService 初始化

### 状态管理

使用 **Provider**（可选支持 Riverpod，通过 `flutter_riverpod: ^2.6.1`）：
- 全局状态：用户会话、主题、未读通知数
- 模块状态：每个功能模块（home/square/profile）有自己的 ViewModel
- 页面状态：使用 `ValueNotifier` 或 `StatefulWidget` 管理本地 UI 状态

### 认证流程

1. **手机号 OTP 登录**：`POST /api/auth/send-otp` → `POST /api/auth/verify-otp` → 返回 JWT Token
2. **密码注册/登录**：`POST /api/auth/register` 或 `POST /api/auth/login` → 返回 JWT Token
3. **新用户引导**：`verify-otp` 返回 `isNewUser=true` 后，引导用户完善资料（昵称、头像、城市）
4. **导航守卫**：访问受保护路由时，如果本地无 JWT Token 则重定向到 `/login`
5. **Token 管理**：JWT Token 存储在本地（SharedPreferences），每次请求携带在 Header 中

### 核心功能

- **宠物管理**：每用户最多 5 只宠物，通过 RLS 策略强制执行（`pets` 表的 `WITH CHECK` 约束）
- **每日打卡**：使用 `gte('created_at', startOfDay)` + `lt('created_at', endOfDay)` 查询今日打卡
- **社交广场**：基于城市的动态筛选（`city_code` 字段），点赞/评论的乐观更新
- **徽章系统**：通过数据库触发器授予（如 7 天连续打卡 → `checkin_streak_7` 徽章）
- **实时更新**：Socket.IO（WebSocket）用于点赞/评论实时推送

## NestJS 后端

### 数据库表（PostgreSQL + Prisma）

- **`users`**：用户表（存储手机号、密码哈希）
- **`profiles`**：用户资料（与 users 1:1，包含昵称、头像、城市）
- **`pets`**：宠物信息（与 users N:1，每用户最多 5 只，应用层限制）
- **`checkins`**：每日打卡记录（与 users N:1，按 `created_at DESC` 和 `city_code` 索引）
- **`likes`**：点赞记录（users 和 checkins M:N，`user_id + checkin_id` 唯一约束）
- **`comments`**：评论记录（与 checkins N:1，通过 `parent_id` 支持嵌套回复）
- **`badges`**：成就徽章（与 users N:1，按 `user_id + type` 索引）

详细数据库设计参见 `docs/nestjs-backend-architecture.md`。

### 权限控制

使用 NestJS Guards 实现：
- **JwtAuthGuard**：验证 JWT Token，保护需要登录的接口
- **PetOwnerGuard**：验证资源所有权（如只能编辑自己的宠物）
- **CheckInOwnerGuard**：验证打卡记录所有权
- 每个接口根据业务逻辑应用相应的 Guard

### 文件存储（阿里云 OSS）

- **用户头像**：`profiles/{user_id}/avatar_{timestamp}.jpg`
- **宠物头像**：`pets/{pet_id}/avatar_{timestamp}.jpg`
- **打卡图片**：`checkins/{checkin_id}/{uuid}.jpg`（最多 9 张，2MB 限制）
- 所有文件使用阿里云 OSS 私有桶 + 签名 URL 访问

### 后端配置步骤

1. 创建 NestJS 项目：`nest new pet-checkin-backend`
2. 安装依赖并配置 Prisma：`npx prisma init`
3. 配置环境变量（`.env.development`）：
   - 数据库连接：`DATABASE_URL`
   - JWT 密钥：`JWT_SECRET`
   - 阿里云 SMS：`ALIYUN_SMS_ACCESS_KEY_ID`, `ALIYUN_SMS_ACCESS_KEY_SECRET`
   - 阿里云 OSS：`ALIYUN_OSS_ACCESS_KEY_ID`, `ALIYUN_OSS_BUCKET`
4. 运行数据库迁移：`npx prisma migrate dev`
5. 启动后端服务：`npm run start:dev`（开发模式，端口 3000）

详细后端架构和 API 文档参见 `docs/nestjs-backend-architecture.md`。

## 环境配置

API 服务器地址通过 `--dart-define` 传递：

```bash
flutter run --dart-define API_BASE_URL=http://localhost:3000/api
```

在代码中访问：
```dart
const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api')
```

或使用配置文件：
```bash
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json` 示例：
```json
{
  "API_BASE_URL": "http://localhost:3000/api"
}
```

## 关键技术细节

### 手机号标准化

前端在发送前自动为匹配 `1[3-9]\d{9}` 的中国手机号添加 `+86` 前缀（或在后端 NestJS 中统一处理）。

### 图片上传流程

1. `image_picker` 选择图片 → 用 `flutter_image_compress` 压缩（最大 800px）
2. 通过 `POST /api/storage/upload` 上传到阿里云 OSS → 返回 OSS URL
3. 使用返回的 URL 在 UI 中显示（带签名有效期的临时访问链接）

### 分页与无限滚动

使用 `.limit(50)` + `.range(start, end)` 进行分页。当响应长度 < limit 时标记 `hasMore=false`。

### 乐观 UI 更新

对于点赞/评论：立即更新本地状态 → 发送请求 → 失败时回滚并显示 Toast。

### 错误处理

- **认证错误**：显示 SnackBar 并提供用户友好的消息（如"验证码错误"、"操作过于频繁"）
- **网络错误**：自动重试 2 次，然后显示 ErrorView 和重试按钮
- **401 未授权**：Token 失效或未登录，清除本地 Token 并重定向到 `/login`
- **403 禁止访问**：权限不足，显示错误提示（如"无权操作他人的宠物"）

## 常用模式

### Repository 模式

Repository 抽象 HTTP API 调用：
```dart
// 接口 (auth_repo.dart)
abstract class AuthRepo {
  Future<void> sendPhoneOtp(String phone);
  Future<AuthResponse> verifyOtp(String phone, String code);
}

// 实现 (auth_repo_impl.dart)
class AuthRepoImpl implements AuthRepo {
  final ApiService _apiService;

  @override
  Future<AuthResponse> verifyOtp(String phone, String code) async {
    final response = await _apiService.post('/auth/verify-otp', {
      'phone': phone,
      'code': code,
    });
    return AuthResponse.fromJson(response);
  }
}
```

### 模型序列化

所有模型使用 `json_annotation` 和 `fromJson`/`toJson`：
```dart
@JsonSerializable()
class Pet {
  final String id;
  final String name;
  // ...
  factory Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);
  Map<String, dynamic> toJson() => _$PetToJson(this);
}
```

修改模型后运行 `flutter pub run build_runner build`。

### 导航

在 `lib/routes.dart` 中使用 `onGenerateRoute` 集中管理：
```dart
Navigator.pushNamed(context, AppRoutes.register, arguments: phoneNumber);
```

## 开发注意事项

- **屏幕适配**：使用 `flutter_screenutil` 通过 `ScreenUtilInitWrapper`（在 `main.dart` 中初始化）
- **主题**：基于橙色的 Material3 主题定义在 `ui/theme/app_theme.dart`
- **图标**：通过 `tool/generate_icons.dart` 生成自定义图标
- **WebSocket**：在 `initState` 中连接 Socket.IO 客户端，在 `dispose` 中断开连接以防止内存泄漏
- **Token 管理**：JWT Token 存储在 SharedPreferences，每次 HTTP 请求自动在 Header 中携带 `Authorization: Bearer {token}`
- **API 调试**：如果请求失败返回 401，检查 Token 是否有效；返回 403 检查是否有权限访问该资源

## 文档参考

- 架构详情：`docs/architecture.md`（包含详细的 ER 图、业务流程、时序图）
- NestJS 后端架构：`docs/nestjs-backend-architecture.md`（完整的后端设计、API 文档、数据库 Schema）
- 项目 README：`pet_checkin/README.md`（功能列表、技术栈、快速开始）

## 后端开发

### 启动 NestJS 后端

```bash
# 进入后端目录（需要先创建）
cd pet-checkin-backend

# 安装依赖
npm install

# 配置环境变量
cp .env.example .env.development
# 编辑 .env.development 填写数据库、阿里云等配置

# 运行数据库迁移
npx prisma migrate dev

# 启动开发服务器（端口 3000）
npm run start:dev

# 查看 API 文档（访问 http://localhost:3000/api-docs）
```

### 常用后端命令

```bash
# 生成新模块
nest g module modules/xxx
nest g controller modules/xxx
nest g service modules/xxx

# Prisma 相关
npx prisma studio                    # 数据库可视化界面
npx prisma migrate dev --name xxx    # 创建新迁移
npx prisma generate                  # 生成 Prisma Client

# 运行测试
npm run test                         # 单元测试
npm run test:e2e                     # E2E 测试

# 构建生产版本
npm run build
npm run start:prod
```

# 一般你不用重启服务,因为我让你开发或者修改功能的时候我服务是启动好的