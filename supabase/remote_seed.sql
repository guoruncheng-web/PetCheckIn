-- 远程 Supabase 示例数据（替换 :user1_id / :user2_id 为真实 auth.users.id 后执行）
-- 执行前请先完成 Phone Auth 注册，获取 UUID

-- 示例用户（需先注册手机号，得到 auth.users.id 后替换占位符）
-- :user1_id 对应手机号 13800000000
-- :user2_id 对应手机号 13900000000

-- 1. 更新昵称与城市
UPDATE public.profiles
SET nickname = '小明', city_code = '310100', city_name = '上海市'
WHERE id = :user1_id;

UPDATE public.profiles
SET nickname = '小红', city_code = '320100', city_name = '南京市'
WHERE id = :user2_id;

-- 2. 插入宠物（每人 2 只）
INSERT INTO public.pets (user_id, name, breed, age, avatar_url) VALUES
(:user1_id, '豆豆', '威尔士柯基', 2, 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=corgi+puppy+cartoon&image_size=square'),
(:user1_id, '球球', '柴犬', 1, 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=shiba+inu+puppy+cartoon&image_size=square'),
(:user2_id, '奶茶', '英国短毛猫', 3, 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=british+shorthair+cat+cartoon&image_size=square'),
(:user2_id, '泡芙', '布偶猫', 1, 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=ragdoll+cat+cartoon&image_size=square');

-- 3. 插入打卡（近 7 天）
INSERT INTO public.checkins (user_id, pet_id, content, image_urls, city_code, city_name, created_at)
SELECT
  p.user_id,
  p.id AS pet_id,
  CASE p.name
    WHEN '豆豆' THEN '今天学会了坐下！'
    WHEN '球球' THEN '第一次出门打疫苗，超乖'
    WHEN '奶茶' THEN '晒太阳的慵懒午后'
    WHEN '泡芙' THEN '新玩具到手！'
  END,
  ARRAY[CASE p.name
    WHEN '豆豆' THEN 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=corgi+sitting+cartoon&image_size=square'
    WHEN '球球' THEN 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=shiba+vet+cartoon&image_size=square'
    WHEN '奶茶' THEN 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=cat+sunbath+cartoon&image_size=square'
    WHEN '泡芙' THEN 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=ragdoll+toy+cartoon&image_size=square'
  END],
  u.city_code,
  u.city_name,
  now() - (interval '1 day' * (CASE p.name WHEN '豆豆' THEN 1 WHEN '球球' THEN 3 WHEN '奶茶' THEN 2 WHEN '泡芙' THEN 5 END))
FROM public.pets p
JOIN public.profiles u ON u.id = p.user_id
WHERE p.user_id IN (:user1_id, :user2_id);

-- 4. 点赞（互相点赞 2 条）
INSERT INTO public.likes (user_id, checkin_id, created_at)
SELECT
  :user1_id,
  c.id,
  now()
FROM public.checkins c
WHERE c.user_id = :user2_id
ORDER BY c.created_at
LIMIT 2;

INSERT INTO public.likes (user_id, checkin_id, created_at)
SELECT
  :user2_id,
  c.id,
  now()
FROM public.checkins c
WHERE c.user_id = :user1_id
ORDER BY c.created_at
LIMIT 2;

-- 5. 评论（每人留 1 条）
INSERT INTO public.comments (user_id, checkin_id, content, emoji, created_at)
SELECT
  :user1_id,
  c.id,
  '太可爱了！',
  '❤️',
  now()
FROM public.checkins c
WHERE c.user_id = :user2_id
ORDER BY c.created_at
LIMIT 1;

INSERT INTO public.comments (user_id, checkin_id, content, emoji, created_at)
SELECT
  :user2_id,
  c.id,
  '毛茸茸想 Rua！',
  '😍',
  now()
FROM public.checkins c
WHERE c.user_id = :user1_id
ORDER BY c.created_at
LIMIT 1;

-- 6. 成就徽章
INSERT INTO public.badges (user_id, type, meta)
VALUES
(:user1_id, 'checkin_streak_7', '{"days":7}'),
(:user2_id, 'like_master', '{"received":150}');

-- 7. 通知中心（对应点赞/评论）
INSERT INTO public.notifications (user_id, type, actor_id, checkin_id, is_read, created_at)
SELECT
  c.user_id,
  'comment',
  :user1_id,
  c.id,
  false,
  now()
FROM public.checkins c
WHERE c.user_id = :user2_id
ORDER BY c.created_at
LIMIT 1;

INSERT INTO public.notifications (user_id, type, actor_id, checkin_id, is_read, created_at)
SELECT
  c.user_id,
  'like',
  :user2_id,
  c.id,
  false,
  now()
FROM public.checkins c
WHERE c.user_id = :user1_id
ORDER BY c.created_at
LIMIT 1;