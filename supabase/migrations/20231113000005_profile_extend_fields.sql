-- 20231113000005_profile_extend_fields.sql
-- 扩展 profiles 表常用字段

-- 1. 新增列
ALTER TABLE public.profiles
ADD COLUMN phone            text,
ADD COLUMN gender           smallint NOT NULL DEFAULT 0 CHECK (gender BETWEEN 0 AND 2), -- 0 未知 1 男 2 女
ADD COLUMN birthday         date,
ADD COLUMN age int,
ADD COLUMN province_code    text,
ADD COLUMN province_name    text,
ADD COLUMN follower_count   int NOT NULL DEFAULT 0 CHECK (follower_count >= 0),
ADD COLUMN following_count  int NOT NULL DEFAULT 0 CHECK (following_count >= 0),
ADD COLUMN is_verified      boolean NOT NULL DEFAULT false,
ADD COLUMN last_active_at   timestamptz;

-- 2. 唯一索引：phone（允许 NULL 重复，非 NULL 唯一）
CREATE UNIQUE INDEX profiles_phone_unique ON public.profiles (phone) WHERE phone IS NOT NULL;

-- 3. 常用组合索引
CREATE INDEX profiles_city_province_idx ON public.profiles (city_code, province_code);
CREATE INDEX profiles_last_active_at_idx ON public.profiles (last_active_at DESC);

-- 4. RLS：允许用户更新自己的扩展字段
CREATE POLICY "用户可更新自己资料" ON public.profiles
FOR UPDATE USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 5. 触发器：更新 last_active_at（登录或调用心跳接口时触发）
CREATE OR REPLACE FUNCTION trg_set_last_active()
RETURNS trigger AS $$
BEGIN
  NEW.last_active_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_last_active
BEFORE UPDATE ON public.profiles
FOR EACH ROW
WHEN (OLD.last_active_at IS DISTINCT FROM NEW.last_active_at)
EXECUTE FUNCTION trg_set_last_active();

-- 6. 触发器：插入或更新 birthday 时自动计算 age
CREATE OR REPLACE FUNCTION trg_calc_age()
RETURNS trigger AS $$
BEGIN
  IF NEW.birthday IS NOT NULL THEN
    NEW.age := date_part('year', age(NEW.birthday));
  ELSE
    NEW.age := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_calc_age
BEFORE INSERT OR UPDATE OF birthday ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION trg_calc_age();

-- 7. 注释
COMMENT ON COLUMN public.profiles.phone           IS '手机号，脱敏展示';
COMMENT ON COLUMN public.profiles.gender          IS '性别：0 未知 1 男 2 女';
COMMENT ON COLUMN public.profiles.birthday        IS '生日';
COMMENT ON COLUMN public.profiles.age             IS '年龄，自动生成';
COMMENT ON COLUMN public.profiles.province_code   IS '省份编码';
COMMENT ON COLUMN public.profiles.province_name   IS '省份名称';
COMMENT ON COLUMN public.profiles.follower_count  IS '粉丝数';
COMMENT ON COLUMN public.profiles.following_count IS '关注数';
COMMENT ON COLUMN public.profiles.is_verified     IS '官方认证';
COMMENT ON COLUMN public.profiles.last_active_at  IS '最后活跃时间';