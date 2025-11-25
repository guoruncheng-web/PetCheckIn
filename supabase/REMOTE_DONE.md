# 远程 Supabase 初始化完成 ✅

## 1. 数据库结构
- 迁移文件：`20231113000003_final_remote.sql` 已成功应用
- 表清单：profiles / pets / checkins / likes / comments / favorites / badges / notifications
- RLS：已启用，所有写操作需登录，公开数据可读
- 触发器：
  - `on_auth_user_created`：注册后自动插入 profiles
  - `trg_pets_limit`：插入宠物时检查 ≤5 只
- 函数：`award_streak_badge()` 每日可调用，颁发连续打卡徽章

## 2. 下一步操作（在 Supabase Dashboard 完成）
1. **启用 Phone Auth**
   - Authentication → Providers → Phone → 启用
   - 选择短信服务商（Twilio/阿里云/腾讯云），填写 API Key & Sender ID
   - 模板示例：`\{token}\ 是你的宠物打卡验证码，60秒内有效。`

2. **创建 Storage 桶（3 个）**
   | 桶 ID | 公开读 | 文件大小 | MIME 限制 | 路径规则 |
   |---|---|---|---|---|
   | `profiles` | 否 | 2 MB | image/jpeg/png/webp | `/profiles/{user_id}/avatar.{ext}` |
   | `pets` | 否 | 2 MB | 同上 | `/pets/{pet_id}/avatar.{ext}` |
   | `checkins` | 否 | 5 MB | 同上 | `/checkins/{checkin_id}/{uuid}.{ext}` |

3. **为每个桶添加 RLS Policy（示例）**
   ```sql
   -- profiles 上传
   CREATE POLICY "profiles_upload_policy" ON storage.objects
     FOR INSERT TO authenticated
     WITH CHECK (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);
   -- profiles 下载
   CREATE POLICY "profiles_download_policy" ON storage.objects
     FOR SELECT TO authenticated
     USING (bucket_id = 'profiles');
   ```
   同理应用于 `pets` / `checkins` 桶

4. **可选：定时徽章任务**
   - 若支持 pg_cron：
     ```sql
     SELECT cron.schedule('award-streak', '0 2 * * *', 'SELECT public.award_streak_badge();');
     ```
   - 否则使用 Edge Function + Scheduled Events，或客户端每日首次打开时调用

## 3. 本地 Flutter 配置
```bash
flutter run \
  --dart-define SUPABASE_URL=<远程 API URL> \
  --dart-define SUPABASE_ANON_KEY=<远程 anon key>
```

## 4. 示例数据（可选）
- 文件：`remote_seed.sql`
- 步骤：
  1. 使用手机号注册两个用户（13800000000、13900000000）
  2. 复制对应的 `auth.users.id` 替换脚本中的 `:user1_id`、`:user2_id`
  3. 在 Dashboard SQL Editor 执行即可生成宠物、打卡、点赞、评论、徽章、通知

## 5. 生产 checklist
- [ ] 替换 staging 数据库为 prod 项目
- [ ] 关闭 Dashboard 匿名访问
- [ ] 启用短信防刷（默认已开启）
- [ ] 配置自定义 SMTP（可选）
- [ ] 每日自动备份已默认开启

## 6. 常见问题速查
| 现象 | 解决 |
|---|---|
| `permission denied for table pets` | 确认已登录，RLS 已启用 |
| 上传头像 403 | 检查 Storage 桶 RLS 路径是否匹配 `/profiles/{user_id}/avatar.*` |
| 验证码未收到 | 查看 SMS 服务商日志；确认手机号格式 +86；检查额度 |
| 广场无数据 | 执行 `remote_seed.sql` 或手动插入 checkins，确保 city_code 与当前用户同城 |

**现在你可以开始编写 Flutter 业务代码了！** 🎉