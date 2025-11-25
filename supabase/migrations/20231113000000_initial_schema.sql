-- 启用 UUID 与 RLS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 用户档案表（与 auth.users 1:1）
CREATE TABLE public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  nickname    TEXT NOT NULL CHECK (char_length(nickname) <= 12),
  avatar_url  TEXT,
  bio         TEXT CHECK (char_length(bio) <= 200),
  city_code   TEXT,
  city_name   TEXT,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "任何人可查看公开资料" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "用户可更新自己资料" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 宠物表
CREATE TABLE public.pets (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
  name        TEXT NOT NULL CHECK (char_length(name) <= 20),
  breed       TEXT NOT NULL CHECK (char_length(breed) <= 30),
  age         INTEGER CHECK (age >= 0 AND age <= 30),
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (user_id, name)
);
ALTER TABLE public.pets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "任何人可查看宠物" ON public.pets FOR SELECT USING (true);
-- 拆分 ALL 为 SELECT/INSERT/UPDATE/DELETE，避免 WITH CHECK 混用
CREATE POLICY "用户可查看自己宠物" ON public.pets FOR SELECT USING (auth.uid() = user_id);
-- 移除子查询，改用触发器限制宠物数量，RLS 仅保留基础权限
-- 仅保留基础权限，数量限制由触发器负责，避免 WITH CHECK 子查询
CREATE POLICY "用户可插入自己宠物" ON public.pets FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "用户可更新自己宠物" ON public.pets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "用户可删除自己宠物" ON public.pets FOR DELETE USING (auth.uid() = user_id);

-- 打卡表
CREATE TYPE public.checkin_status AS ENUM ('pending','done');
CREATE TABLE public.checkins (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
  pet_id      UUID NOT NULL REFERENCES public.pets ON DELETE CASCADE,
  content     TEXT NOT NULL CHECK (char_length(content) <= 500),
  image_urls  TEXT[] DEFAULT '{}',
  status      public.checkin_status DEFAULT 'done',
  city_code   TEXT,
  city_name   TEXT,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.checkins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "任何人可读打卡" ON public.checkins FOR SELECT USING (true);
CREATE POLICY "用户可写自己打卡" ON public.checkins FOR ALL USING (auth.uid() = user_id);
CREATE INDEX idx_checkins_created_desc ON public.checkins (created_at DESC);
CREATE INDEX idx_checkins_city_created ON public.checkins (city_code, created_at DESC);
CREATE INDEX idx_checkins_user_created ON public.checkins (user_id, created_at DESC);

-- 点赞表
CREATE TABLE public.likes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
  checkin_id  UUID NOT NULL REFERENCES public.checkins ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (user_id, checkin_id)
);
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "任何人可读点赞" ON public.likes FOR SELECT USING (true);
CREATE POLICY "用户可管理自己点赞" ON public.likes FOR ALL USING (auth.uid() = user_id);

-- 评论表
CREATE TABLE public.comments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
  checkin_id  UUID NOT NULL REFERENCES public.checkins ON DELETE CASCADE,
  parent_id   UUID REFERENCES public.comments ON DELETE CASCADE,
  content     TEXT NOT NULL CHECK (char_length(content) <= 300),
  emoji       TEXT CHECK (char_length(emoji) <= 10),
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "任何人可读评论" ON public.comments FOR SELECT USING (true);
CREATE POLICY "用户可管理自己评论" ON public.comments FOR ALL USING (auth.uid() = user_id);
CREATE INDEX idx_comments_checkin_created ON public.comments (checkin_id, created_at ASC);

-- 收藏表
CREATE TABLE public.favorites (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
  checkin_id  UUID NOT NULL REFERENCES public.checkins ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (user_id, checkin_id)
);
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "用户可查看自己收藏" ON public.favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "用户可管理自己收藏" ON public.favorites FOR ALL USING (auth.uid() = user_id);

-- 成就徽章表
CREATE TYPE public.badge_type AS ENUM ('checkin_streak_7','checkin_streak_30','like_master','comment_master');
CREATE TABLE public.badges (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
  type        public.badge_type NOT NULL,
  awarded_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
  meta        JSONB DEFAULT '{}',
  UNIQUE (user_id, type)
);
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "任何人可读徽章" ON public.badges FOR SELECT USING (true);
CREATE POLICY "系统写入徽章" ON public.badges FOR INSERT USING (true); -- 由触发器调用

-- 通知表（仅用于本地缓存，非实时）
CREATE TABLE public.notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
  type        TEXT NOT NULL, -- 'like' | 'comment'
  actor_id    UUID REFERENCES public.profiles ON DELETE CASCADE,
  checkin_id  UUID REFERENCES public.checkins ON DELETE CASCADE,
  is_read     BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "用户可查看自己通知" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "用户可更新自己通知" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE INDEX idx_notifications_user_unread ON public.notifications (user_id, is_read, created_at DESC);

-- 函数：自动创建用户档案
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, nickname)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'phone');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 触发器：注册后自动插入档案
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 触发器函数：插入宠物前检查数量
CREATE OR REPLACE FUNCTION public.trg_check_pet_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT COUNT(*) >= 5 FROM public.pets WHERE user_id = NEW.user_id) THEN
    RAISE EXCEPTION '每人最多绑定 5 只宠物';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pets_insert_limit
  BEFORE INSERT ON public.pets
  FOR EACH ROW EXECUTE FUNCTION public.trg_check_pet_limit();

-- 函数：颁发连续打卡徽章（由定时器或触发器调用）
CREATE OR REPLACE FUNCTION public.award_streak_badge()
RETURNS VOID AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT user_id,
           COUNT(*) FILTER (WHERE created_at >= now() - interval '30 days') AS days_30,
           COUNT(*) FILTER (WHERE created_at >= now() - interval '7 days')  AS days_7
    FROM public.checkins
    GROUP BY user_id
  LOOP
    IF rec.days_7 >= 7 THEN
      INSERT INTO public.badges (user_id, type, meta)
      VALUES (rec.user_id, 'checkin_streak_7', jsonb_build_object('days', rec.days_7))
      ON CONFLICT DO NOTHING;
    END IF;
    IF rec.days_30 >= 30 THEN
      INSERT INTO public.badges (user_id, type, meta)
      VALUES (rec.user_id, 'checkin_streak_30', jsonb_build_object('days', rec.days_30))
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 定时器：每日 02:00 执行（需 pg_cron 扩展，若 Supabase 支持）
-- SELECT cron.schedule('award-streak', '0 2 * * *', 'SELECT public.award_streak_badge();');