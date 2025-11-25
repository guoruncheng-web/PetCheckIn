# Supabase 初始化指南

## 1. 安装 Supabase CLI（若未安装）
```bash
npm i -g supabase
```

## 2. 登录并关联项目
```bash
supabase login
supabase link --project-ref <your-project-ref>  # 在 Supabase Dashboard 获取
```

## 3. 一键初始化（含迁移与示例数据）
```bash
cd supabase
bash init_supabase.sh
```

## 4. 手动执行迁移（若已远程链接）
```bash
supabase db push
```

## 5. 应用 Storage 桶配置
- 由于 Storage 桶需 project service_key，目前仅支持 Dashboard 手动创建：
  1. 进入 Supabase Dashboard → Storage → 新建 Bucket
  2. 创建三个桶（ID 与脚本一致）：
     - `profiles`：关闭 Public，文件大小 2 MB，允许 MIME：image/jpeg、image/png、image/webp
     - `pets`：同上
     - `checkins`：关闭 Public，文件大小 5 MB，允许 MIME 同上
  3. 为每个桶添加 RLS Policy（参考 `20231113000001_storage_buckets.sql`）

## 6. 启用 Phone Auth（手机号 OTP）
- Authentication → Providers → Phone → 启用
- SMS Provider 选择 Twilio/阿里云/腾讯云，填写 API Key & Sender ID
- 模板示例：
  - 验证码短信：`{token} 是你的宠物打卡验证码，60秒内有效。`

## 7. 获取环境变量
```bash
supabase status
```
复制 `API URL` 与 `anon key` 到 Flutter：
```bash
flutter run --dart-define SUPABASE_URL=<URL> --dart-define SUPABASE_ANON_KEY=<KEY>
```

## 8. 定时徽章任务（可选）
- 若 Supabase 支持 pg_cron，执行：
```sql
SELECT cron.schedule('award-streak', '0 2 * * *', 'SELECT public.award_streak_badge();');
```
- 否则使用 Edge Function + Scheduled Events，或客户端每日首次打开时调用函数

## 9. 开发完成后的生产 checklist
- [ ] 替换 staging 数据库为 prod 项目
- [ ] 关闭 Dashboard 匿名访问
- [ ] 启用短信发送频率限制（默认已开启）
- [ ] 配置自定义 SMTP（可选）
- [ ] 备份策略：每日自动备份已默认开启

## 10. 常见问题
| 问题 | 解决 |
|------|------|
| `permission denied for table pets` | 确认 RLS 已启用且用户已登录 |
| 上传头像 403 | 检查 Storage bucket 的 INSERT RLS 路径是否匹配 `/profiles/{user_id}/avatar.*` |
| 验证码未收到 | 查看 SMS 服务商日志；确认手机号格式 +86；检查额度 |
| 广场无数据 | 确认 checkins 表 city_code 与当前用户同城；或插入示例数据 |