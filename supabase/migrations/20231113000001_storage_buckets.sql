-- 存储桶初始化（需 supabase_admin 或 service_role 执行）
-- 在 Supabase Dashboard -> Storage -> Buckets 新建，或使用 SQL 如下：

-- 头像桶
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('profiles', 'profiles', false, 2097152, ARRAY['image/jpeg','image/png','image/webp']);

-- 宠物头像桶
INSERT INTO storage.buckets (id, name, public, false, 2097152, ARRAY['image/jpeg','image/png','image/webp']);

-- 打卡图片桶
INSERT INTO storage.buckets (id, name, public, false, 5242880, ARRAY['image/jpeg','image/png','image/webp']);

-- 桶级 RLS（示例：仅登录用户可上传，下载需签名 URL）
CREATE POLICY "profiles_upload_policy" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "profiles_download_policy" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'profiles');

-- 同上规则可应用于 pets / checkins 桶