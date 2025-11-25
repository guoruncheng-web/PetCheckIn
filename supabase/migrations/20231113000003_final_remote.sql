-- 终极精简版：直接执行，无重复 Policy，已验证远程可用
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- profiles
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
CREATE POLICY "查看公开资料" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "更新自己资料" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- pets
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
CREATE POLICY "查看宠物" ON public.pets FOR SELECT USING (true);
CREATE POLICY "管理自己宠物" ON public.pets FOR ALL USING (auth.uid() = user_id);

-- 触发器：宠物 ≤5
CREATE OR REPLACE FUNCTION public.trg_pet_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT COUNT(*) >= 5 FROM public.pets WHERE user_id = NEW.user_id) THEN
    RAISE EXCEPTION '每人最多绑定 5 只宠物';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pets_limit
  BEFORE INSERT ON public.pets
  FOR EACH ROW EXECUTE FUNCTION public.trg_pet_limit();

-- checkins
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
CREATE POLICY "读打卡" ON public.checkins FOR SELECT USING (true);
CREATE POLICY "写自己打卡" ON public.checkins FOR ALL USING (auth.uid() = user_id);
CREATE INDEX idx_checkins_created_desc ON public.checkins (created_at DESC);
CREATE INDEX idx_checkins_city_created ON public.checkins (city_code, created_at DESC);
CREATE INDEX idx_checkins_user_created ON public.checkins (user_id, created_at DESC);

-- likes
CREATE TABLE public.likes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
  checkin_id  UUID NOT NULL REFERENCES public.checkins ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (user_id, checkin_id)
);
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "读点赞" ON public.likes FOR SELECT USING (true);
CREATE POLICY "管理自己点赞" ON public.likes FOR ALL USING (auth.uid() = user_id);

-- comments
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
CREATE POLICY "读评论" ON public.comments FOR SELECT USING (true);
CREATE POLICY "管理自己评论" ON public.comments FOR ALL USING (auth.uid() = user_id);
CREATE INDEX idx_comments_checkin_created ON public.comments (checkin_id, created_at ASC);

-- favorites
CREATE TABLE public.favorites (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
  checkin_id  UUID NOT NULL REFERENCES public.checkins ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (user_id, checkin_id)
);
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "读收藏" ON public.favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "管理自己收藏" ON public.favorites FOR ALL USING (auth.uid() = user_id);

-- badges
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
CREATE POLICY "读徽章" ON public.badges FOR SELECT USING (true);

-- notifications
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
CREATE POLICY "读通知" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "更新自己通知" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE INDEX idx_notifications_user_unread ON public.notifications (user_id, is_read, created_at DESC);

-- 自动创建档案
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, nickname)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'phone');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 连续打卡徽章函数
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