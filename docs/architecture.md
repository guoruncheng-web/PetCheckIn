# 宠物日常打卡应用技术架构文档

## 1. 目标与范围
- 提供基于 Flutter + Supabase 的移动应用，实现宠物绑定、每日打卡、同城广场互动与个人中心功能。
- 支持用户认证、图片上传、实时数据同步、分页加载、地理筛选与成就徽章。
- 面向 iOS 与 Android 双端发布，严格还原 Figma 设计稿。

## 2. 技术栈与关键依赖
- 客户端：Flutter（Material3），`supabase_flutter`，`provider`/`riverpod`（二选一），`geolocator`，`image_picker`，`cached_network_image`，`intl`。
- 后端：Supabase（Auth、Postgres、Storage、Realtime、Edge Functions 可选）。
- 构建发布：Xcode、Android Gradle、CI/CD（GitHub Actions + Fastlane 建议）。

## 3. 系统架构概览
- 前端：分层架构（UI/ViewModel/Repository），路由驱动的模块化页面（首页、广场、个人中心）。
- 后端：Supabase 提供认证与数据库服务，使用 RLS 做行级权限控制；Storage 管理图片资源；Realtime 提供互动与打卡的实时推送。
- 地理：客户端定位生成城市编码；通过城市维度进行筛选（可选 PostGIS 做空间查询）。

## 4. 登录与注册流程
### 4.1 交互时序（简化泳道）
```
Client ─► AuthRepo ─► Supabase(Auth API) ─► SMS Provider
  │         │               │                    │
  ├─输入手机号────► sendPhoneOtp(phone) ─► POST /otp ─► 发送短信
  │         │               │                    │
  ├─输入验证码────► verifyOtp(phone,code) ─► POST /verify ─► 验证
  │         │               │                    │
  ◄────────── 返回 Session ─◄────────── 200 OK ◄───
```

### 4.2 状态机（客户端视角）
- `Idle` → `Sending`（获取验证码按钮点击）
- `Sending` → `Counting`（60 s 倒计时，可重发）
- `Counting` → `Verifying`（用户输入验证码并提交）
- `Verifying` → `Success` / `Failure`（跳转或提示错误）

### 4.3 异常与分支
| 场景 | 客户端表现 | 后端/Supabase 行为 |
|------|------------|-------------------|
| 手机号格式错误 | 实时正则校验，按钮禁用 | 请求不会发出 |
| 验证码错误 | Toast“验证码错误” | 返回 422，可重试 5 次后冷却 15 min |
| 短信发送频繁 | Toast“操作过于频繁” | 返回 429，需等待 60 s |
| 网络超时 | SnackBar+重试按钮 | 自动重试 2 次后降级提示 |
| 用户不存在 | 无感，自动创建账户 | Supabase Auth 默认创建用户 |
| 用户已存在且已注册 | 直接进入登录成功流 | 同上 |

### 4.4 注册补全引导（Onboarding）
- 触发条件：`verifyOtp` 返回 `isNewUser = true`
- 流程：
  1. 弹窗/页面提示“完善资料，开启打卡”
  2. 字段：昵称（必填，≤12 字符）、头像（选填，调用 `image_picker` 上传至 `profiles/avatar` bucket）、城市（选填，自动定位或手动选择）
  3. 跳过：允许跳过，后续可在个人中心补充
  4. 完成：写入 `profiles` 表，进入首页

### 4.5 安全与合规
- 验证码有效期：60 s（Supabase 默认）
- 冷却时间：60 s（前端倒计时+后端速率限制）
- 防刷：同一 IP 日发送上限 20 次（Supabase Auth 设置）
- 隐私：手机号仅用于登录，不对外展示；`profiles` 表公开字段仅 `nickname`、`avatar_url`、`city_name`

### 4.6 扩展点
- 一键登录：后续可接入 Apple/微信/QQ 一键登录，复用现有 `AuthRepo` 接口，新增 `signInWithProvider(provider)`
- 国际区号：UI 增加区号选择器，后端无需改动（Supabase 自动识别 +86）
- 双因子：如需邮箱+手机双因子，可在 `verifyOtp` 后二次验证邮箱 OTP

## 5. 客户端架构
### 5.1 整体分层与依赖关系
```
┌─ UI / Page (login, home, square, profile)
│   │ 依赖 ViewModel 与 Theme
├─ ViewModel (ChangeNotifier / Riverpod)
│   │ 依赖 Repository & 本地状态
├─ Repository (AuthRepo, PetRepo, CheckinRepo...)
│   │ 依赖 SupabaseClient & 本地缓存
├─ Services (SupabaseService, GeoService, ImageService)
│   │ 依赖第三方 SDK (supabase_flutter, geolocator, image_picker)
└─ Models (User, Pet, Checkin, Comment, Like, Badge)
```

### 5.2 组件粒度与复用
- 通用组件统一放在 `lib/common/widgets`：
  - `AppButton`, `AppTextField`, `AppAvatar`, `LoadingIndicator`, `ErrorView`, `EmptyView`
  - 所有按钮与输入框统一使用设计稿色板与圆角，避免重复样式代码
- 验证码组件 `OtpInput`：
  - 支持 6 位自动聚焦、粘贴自动填充、倒计时显示、重发按钮冷却
  - 登录页与注册页共用，减少重复逻辑
- 图片上传组件 `ImageUploader`：
  - 封装 `image_picker` + 压缩 + Storage 上传 + 进度回调
  - 头像与打卡图片共用，支持圆形/方形预览

### 5.3 状态管理策略
- 全局状态：使用 `Provider` 或 `Riverpod` 的 `StateNotifier` 管理用户会话、主题、未读通知数
- 模块级状态：每个功能模块（home/square/profile）独立 ViewModel，避免跨模块耦合
- 页面级状态：使用 `ValueNotifier` 或 `StatefulWidget` 管理输入框、滚动位置、临时 UI 状态

### 5.4 错误与加载统一封装
- 所有 Repository 方法返回 `AsyncValue<T>`（Riverpod）或自定义 `Result<T>`（Provider），统一处理：
  - `loading` → 显示骨架屏/LoadingIndicator
  - `error` → 显示 ErrorView + 重试按钮
  - `data` → 渲染正常内容
- 全局错误拦截：通过 `FlutterError.onError` + `Zone` 捕获未处理异常，上报 Sentry（可选）
- 分层设计（详见 5.1 架构图）：
  - UI 层：按设计稿实现页面与组件，统一主题与交互动画。
  - 状态层：每模块一个 ViewModel（`ChangeNotifier` 或 `Riverpod`），负责状态、校验与交互逻辑。
  - 数据层：Repository 封装 Supabase 调用（认证、CRUD、存储、实时订阅、分页与缓存）。
- 目录结构建议：
  - `lib/features/auth/*` 登录页、注册页、验证码组件、倒计时逻辑
  - `lib/features/home/*` 首页与打卡详情
  - `lib/features/square/*` 广场与城市筛选
  - `lib/features/profile/*` 个人中心、设置、通知、成就
  - `lib/common/*` 主题、路由、通用组件、工具函数
  - `lib/data/models/*` 数据模型（User、Pet、Checkin、Comment、Like、Badge 等）
  - `lib/data/repos/*` 仓库层（AuthRepo、PetRepo、CheckinRepo、InteractionRepo、ProfileRepo）
  - `lib/services/*` Supabase 客户端封装、定位服务、图片上传服务
- 路由与页面：
  - 首页：宠物展示区（最多5只绑定）、今日打卡状态、历史打卡列表（分页）。
  - 广场：默认同城动态、城市下拉筛选、点赞与评论互动。
  - 个人中心：用户信息展示、退出登录、设置、通知中心、我的喜欢、成就徽章。
- 主题与动效：
  - 基于设计稿定义 `ThemeData` 与 `ColorScheme`（色板、字号、间距、阴影）。
  - 页面切换与组件交互提供统一动效；关键操作给予轻量反馈（SnackBar、Toast）。

## 6. 后端架构（Supabase）
### 6.1 认证方案（手机号 OTP）
- Supabase Auth 已内置 Phone OTP 能力，仅需在控制台启用并配置短信服务商（Twilio/阿里云/腾讯云）。
- 登录与注册同一路径：`signInWithOtp({ phone })`，若手机号不存在则自动创建用户，客户端通过 `isNewUser` 标识区分后续流程。
- 会话管理：Access Token 默认 15 min，Refresh Token 默认 1 周；Flutter 端通过 `supabase_flutter` 自动刷新。

### 6.2 数据库实体关系（ER 简图）
```
auth.users 1 ── 1 profiles
profiles 1 ── N pets
profiles 1 ── N checkins
checkins 1 ── N likes
checkins 1 ── N comments
profiles 1 ── N likes (复合唯一)
profiles 1 ── N comments
profiles 1 ── N badges
```

### 6.3 核心表详细字段与索引
| 表 | 关键字段 | 索引/约束 | 说明 |
|--|--|--|--|
| profiles | id(PK), user_id(FK auth.users), nickname, avatar_url, bio, city_code, city_name, created_at | UNIQUE(user_id) | 用户档案，手机号登录后自动创建 |
| pets | id(PK), user_id(FK profiles.id), name, breed, age, avatar_url, created_at | UNIQUE(user_id, name), CHECK (age>=0) | 单人≤5 只，插入前 COUNT(*) 校验 |
| checkins | id(PK), user_id, pet_id, content, image_urls[], status, city_code, city_name, created_at | INDEX(created_at DESC), INDEX(user_id, created_at), INDEX(city_code, created_at) | 广场按城市+时间倒序查询 |
| likes | id(PK), user_id, checkin_id, created_at | UNIQUE(user_id, checkin_id) | 幂等点赞 |
| comments | id(PK), user_id, checkin_id, content, emoji, parent_id, created_at | INDEX(checkin_id, created_at) | 楼中楼评论 |
| badges | id(PK), user_id, type, awarded_at, meta(jsonb) | INDEX(user_id, type) | 成就类型枚举：checkin_streak, like_master… |

### 6.4 RLS 策略（行级安全）示例
```sql
-- profiles：用户只能读写自己
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "用户可查看公开资料" ON profiles FOR SELECT USING (true);
CREATE POLICY "用户可更新自己资料" ON profiles FOR UPDATE USING (auth.uid() = user_id);

-- pets：单人≤5 只，写入前检查
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "用户可查看所有宠物" ON pets FOR SELECT USING (true);
CREATE POLICY "用户可管理自己宠物" ON pets FOR ALL USING (auth.uid() = user_id)
  WITH CHECK (
    (SELECT COUNT(*) FROM pets WHERE user_id = auth.uid()) < 5
  );

-- checkins：写限本人，读可公开（广场）
ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "任何人可读打卡" ON checkins FOR SELECT USING (true);
CREATE POLICY "用户可写自己打卡" ON checkins FOR ALL USING (auth.uid() = user_id);

-- likes/comments：写限本人，读公开
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "任何人可读点赞" ON likes FOR SELECT USING (true);
CREATE POLICY "用户可管理自己点赞" ON likes FOR ALL USING (auth.uid() = user_id);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "任何人可读评论" ON comments FOR SELECT USING (true);
CREATE POLICY "用户可管理自己评论" ON comments FOR ALL USING (auth.uid() = user_id);
```

### 6.5 Storage 分桶与权限
| 桶名 | 公开读 | 上传权限 | 路径规则 | 生命周期 |
|----|------|--------|--------|--------|
| profiles | 否（签名URL） | 登录用户 | `/profiles/{user_id}/avatar.{ext}` | 保留最新 1 张，旧图自动删除 |
| pets | 否 | 登录用户 | `/pets/{pet_id}/avatar.{ext}` | 同上 |
| checkins | 否 | 登录用户 | `/checkins/{checkin_id}/{uuid}.{ext}` | 最多 9 张，单张≤2 MB |

### 6.6 Realtime 订阅设计
- 频道命名：`checkins:{city_code}`、`likes:{checkin_id}`、`comments:{checkin_id}`
- 事件过滤：仅订阅当前可见列表的 city/checkin，减少流量
- 冲突解决：乐观更新 + 收到 `postgres_changes` 后合并，若版本冲突以服务端为准（Toast 提示“数据已更新”）

### 6.7 地理能力演进路线
- V1：客户端定位 → 逆地理编码 → 写入 city_code/city_name → 按 city_code 查询（已满足同城广场）
- V2：启用 PostGIS，存储 `geom Point` → 支持半径/多边形查询 → 按距离排序（需额外索引 `GIST(geom)`）
- V3：Edge Function 聚合附近动态，返回带距离列表，减少客户端计算
- 详见 6.1~6.7 小节：认证方案、ER 图、字段索引、RLS、Storage、Realtime、地理演进

## 7. 安全与权限（RLS）
- 原则：用户仅能读写自己的数据；公开数据仅可读。
- 示例策略：
  - `pets`：`select/insert/update/delete` where `user_id = auth.uid()`
  - `checkins`：写操作限本人；`select`公开或按 `city_code` 过滤
  - `likes/comments/favorites`：`insert` 限本人；`delete` 仅允许本人；`select`公开
  - `profiles`：本人读写；公共读取限制字段集合（头像、昵称、城市）
- Storage：仅登录可上传；读取使用短期签名 URL；禁用公开写入。

## 8. 关键业务流程
### 8.1 宠物绑定（最多 5 只）
```
用户点击“添加宠物”
  ↓
Client：检查本地缓存已绑定数量 ≥5？
  ├─ 是：Toast“最多绑定 5 只”
  └─ 否：弹出 PetForm（name/breed/age/avatar）
        ↓
选择头像 → ImageUploader（压缩≤800 px）→ 返回临时 URL
        ↓
提交 → PetRepo.addPet(dto) → 先 SELECT COUNT(*) 再 INSERT
        ↓
成功：本地列表乐观新增 + 刷新 UI
失败：Snackbar 提示原因（重复名/超限/网络错误）
```

### 8.2 今日打卡
```
进入首页 → CheckinRepo.todayStatus(userId) → 查询当日 00:00-23:59 区间
  ├─ 未打卡：显示“去完成”按钮
  │   ↓
  │  点击 → 打开打卡编辑器（选择宠物→输入内容→选图≤9 张）
  │   ↓
  │  提交 → 压缩图片并行上传 → 拿到 image_urls[] → INSERT checkins
  │   ↓
  │  成功：本地乐观插入 + Realtime 推送广场；刷新今日状态
  └─ 已打卡：显示“已完成”标签与内容卡片
```

### 8.3 广场同城筛选
```
首次加载：GeoRepo.resolveCity(position) → 逆地理编码得 city_code
  ↓
CheckinRepo.listCityFeed(cityCode, page=0) → 按 created_at DESC 分页
  ↓
下拉切换城市：重新请求新 cityCode，缓存 5 min（内存+DiskCache）
  ↓
上拉加载：page+1，直到返回空数组（前端标记 hasMore=false）
```

### 8.4 点赞/取消点赞（幂等）
```
用户点击爱心 → InteractionRepo.like(checkinId)
  ├─ 乐观：本地立即 +1 & 切换状态 → 减少等待体感
  ├─ 请求：INSERT likes ON CONFLICT DO NOTHING（返回影响行数=0 说明已点过）
  └─ 失败：回滚本地状态 + Toast
取消点赞：DELETE likes WHERE user_id=? AND checkin_id=?
```

### 8.5 评论楼中楼
```
输入框聚焦 → 键盘弹起 → 发送按钮高亮
  ↓
发送 → InteractionRepo.addComment({checkinId, content, emoji, parentId?})
  ├─ parentId=null：一级评论
  └─ parentId≠null：楼中楼，前端渲染缩进样式
  ↓
成功：乐观插入列表 + 滚动到底部 + 软键盘收起
```

### 8.6 成就徽章（事件驱动）
```
触发器：AFTER INSERT ON checkins → 统计近 30 天打卡天数
  ├─ ≥7 天且未发“连续 7 天”徽章 → INSERT badges(type='checkin_streak_7')
  ├─ ≥30 天 → 颁发“连续 30 天”
  └─ 首次获得：推送本地通知 + 个人中心红点

触发器：AFTER INSERT ON likes → 统计累计被点赞数
  ├─ ≥100 → 颁发“人气王”
  └─ ≥500 → 颁发“明星宠物”
```

### 8.7 通知中心
```
Realtime 订阅：comments:{userId}, likes:{userId}
  ↓
收到新事件 → 本地写入 notifications 表（仅保留 30 天）→ 红点+1
  ↓
用户点击通知 → 跳转对应打卡详情 → 标记已读
  ↓
全部已读：调用 InteractionRepo.markAllRead() → 清除红点
```

## 9. Repository API 契约（示例）
- `AuthRepo`：`sendPhoneOtp(phone)`，`verifyOtp(phone, token)`，`signOut()`，`currentUser()`，`isNewUser()`
- `ProfileRepo`：`getProfile(userId)`，`updateProfile(profile)`
- `PetRepo`：`listPets(userId)`，`addPet(dto)`，`updatePet(id, dto)`，`deletePet(id)`，`countPets(userId)`
- `CheckinRepo`：`todayStatus(userId)`，`createCheckin(dto)`，`listCheckins(query, page)`，`getCheckin(id)`
- `InteractionRepo`：`like(checkinId)`，`unlike(checkinId)`，`listLikes(checkinId)`，`addComment(dto)`，`listComments(checkinId)`，`favorite(checkinId)`，`unfavorite(checkinId)`
- `GeoRepo`：`resolveCity(position)`，`listCityFeed(cityCode, page)`

## 10. 路由与导航
- 新增路由：
  - `/login`：手机号输入 + 验证码页（首次进入或会话失效时自动跳转）。
  - `/register`：手机号注册页（与登录页共用组件，首次验证成功后引导完善资料）。
  - `/onboarding`：注册后首次进入的引导页（可选，用于完善昵称、头像、城市）。
- 导航守卫：
  - 进入 `/home`、`/square`、`/profile` 等核心页面前，若 `auth.currentUser == null` 则重定向至 `/login`。
  - 登录成功后，若 `isNewUser == true` 则跳转 `/onboarding`，否则进入 `/home`。

## 11. UI 规范与设计对齐
- 严格按照 Figma 的色板、字号、间距、阴影、圆角与动效执行；建立 `ThemeData` 统一管理。
- 通用组件：卡片、列表项、头像与图片组件、表单控件、分页加载指示器。
- 可用性：错误/加载/空态统一设计；关键操作提示与撤销（如取消点赞）。

## 12. 测试方案
- 单元测试：ViewModel 业务逻辑（打卡状态、点赞幂等、评论树）、Repository 边界（分页、过滤、错误）。
- 集成与真机：登录、头像/图片上传、今日打卡、广场分页、城市切换、通知中心、成就徽章。
- 实时一致性：双设备同步点赞/评论，断网重连一致性验证。
- 目标覆盖率：核心业务逻辑 >= 60%，关键场景全覆盖。

## 13. 性能与优化
- 图片：压缩与限制尺寸；列表使用缩略图与延迟加载；缓存头像与图片。
- 数据：分页与字段裁剪（`select` 指定列）；合并实时事件以减少 UI 刷新开销。
- 订阅：按需订阅，模块销毁时取消；避免内存泄漏。

## 14. 安全与隐私
- 全面 RLS；所有写操作需登录且属主校验。
- Storage 使用签名 URL；避免公开写入；输入与文件类型校验。
- 会话安全：定期刷新；退出登录清理本地状态；错误与异常不泄露敏感信息。

## 15. 部署与发布
- 环境：`staging`/`prod` Supabase 项目分离；`SUPABASE_URL`/`SUPABASE_ANON_KEY` 通过构建注入。
- 打包：Android 签名与 Play 发布；iOS 签名与 App Store Connect 发布。
- 配置：构建变体区分日志级别、后端地址与 Feature Flags。

## 16. CI/CD（建议）
- PR 构建与测试（Flutter test、静态分析）。
- 发布流水线：Fastlane 集成，手动触发 `staging` 与 `prod` 构建与分发。
- 质量门禁：覆盖率阈值、Lint 检查、基本 UI 冒烟测试。

## 17. 风险与缓解
- 实时复杂度：采用乐观更新与周期性全量同步。
- 地理准确性：先用城市编码，后续启用 PostGIS 做精细化筛选。
- 图片存储与隐私：默认私有 + 有效期签名 URL；权限审计与访问日志。

## 18. 里程碑
- M1：认证、宠物绑定、今日打卡与基础 UI。
- M2：广场同城、分页与互动（点赞/评论）、通知中心。
- M3：成就系统、个人中心完善、地理筛选优化。
- M4：测试完善、性能优化、双端发布与商店上架。
