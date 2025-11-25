-- 示例数据：2 个用户 + 每人 2 只宠物 + 若干打卡/点赞/评论/徽章
-- 仅用于开发/测试环境，生产请清空

-- 用户 1：手机号 13800000000（需先通过 Supabase Auth 注册，得到 auth.users.id 后替换下方 :user1_id）
-- 用户 2：手机号 13900000000（同上 :user2_id）

-- 替换占位符后执行
-- :user1_id 与 :user2_id 为真实 auth.users.id

INSERT INTO public.profiles (id, nickname, avatar_url, bio, city_code, city_name) VALUES
(:user1_id, '小明', 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=avatar+boy+cartoon&image_size=square', '柯基铲屎官', '310100', '上海市'),
(:user2_id, '小红', 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=avatar+girl+cartoon&image_size=square', '英短猫奴', '320100', '南京市');

INSERT INTO public.pets (user_id, name, breed, age, avatar_url) VALUES
(:user1_id, '豆豆', '威尔士柯基', 2, 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=corgi+puppy+cartoon&image_size=square'),
(:user1_id, '球球', '柴犬', 1, 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=shiba+inu+puppy+cartoon&image_size=square'),
(:user2_id, '奶茶', '英国短毛猫', 3, 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=british+shorthair+cat+cartoon&image_size=square'),
(:user2_id, '泡芙', '布偶猫', 1, 'https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=ragdoll+cat+cartoon&image_size=square');

-- 打卡示例（近 30 天）
INSERT INTO public.checkins (user_id, pet_id, content, image_urls, city_code, city_name, created_at) VALUES
(:user1_id, (SELECT id FROM public.pets WHERE user_id = :user1_id AND name = '豆豆'), '今天学会了坐下！', ARRAY['https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=corgi+sitting+cartoon&image_size=square'], '310100', '上海市', now() - interval '1 day'),
(:user1_id, (SELECT id FROM public.pets WHERE user_id = :user1_id AND name = '球球'), '第一次出门打疫苗，超乖', ARRAY['https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=shiba+vet+cartoon&image_size=square'], '310100', '上海市', now() - interval '3 days'),
(:user2_id, (SELECT id FROM public.pets WHERE user_id = :user2_id AND name = '奶茶'), '晒太阳的慵懒午后', ARRAY['https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=cat+sunbath+cartoon&image_size=square'], '320100', '南京市', now() - interval '2 days'),
(:user2_id, (SELECT id FROM public.pets WHERE user_id = :user2_id AND name = '泡芙'), '新玩具到手！', ARRAY['https://trae-api-us.mchost.guru/api/ide/v1/text_to_image?prompt=ragdoll+toy+cartoon&image_size=square'], '320100', '南京市', now() - interval '5 days');

-- 点赞示例
INSERT INTO public.likes (user_id, checkin_id, created_at)
SELECT :user1_id, id, now()
FROM public.checkins
WHERE user_id = :user2_id
LIMIT 2;

-- 评论示例
INSERT INTO public.comments (user_id, checkin_id, content, emoji, created_at)
SELECT :user1_id, id, '太可爱了！', '❤️', now()
FROM public.checkins
WHERE user_id = :user2_id
LIMIT 1;

-- 成就示例
INSERT INTO public.badges (user_id, type, meta)
VALUES
(:user1_id, 'checkin_streak_7', '{"days":7}'),
(:user2_id, 'like_master', '{"received":150}');