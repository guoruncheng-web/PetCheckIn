-- 宠物表字段扩展迁移（远程可直接执行）

-- 1. 新增字段
ALTER TABLE public.pets
  ADD COLUMN IF NOT EXISTS gender      TEXT CHECK (gender IN ('公','母','未知')),
  ADD COLUMN IF NOT EXISTS birthday    DATE,
  ADD COLUMN IF NOT EXISTS weight_kg   NUMERIC(4,2) CHECK (weight_kg > 0 AND weight_kg <= 150),
  ADD COLUMN IF NOT EXISTS color       TEXT CHECK (char_length(color) <= 20),
  ADD COLUMN IF NOT EXISTS microchip   TEXT CHECK (char_length(microchip) <= 20),
  ADD COLUMN IF NOT EXISTS neutered    BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS description TEXT CHECK (char_length(description) <= 300);

-- 2. 更新 breed 长度（原 30 可能不够）
ALTER TABLE public.pets
  ALTER COLUMN breed TYPE TEXT;

-- 3. 索引加速（按生日、性别查询）
CREATE INDEX IF NOT EXISTS idx_pets_birthday ON public.pets (birthday DESC);
CREATE INDEX IF NOT EXISTS idx_pets_gender    ON public.pets (gender);

-- 4. 触发器：自动计算年龄（可选，若需实时 age 列）
CREATE OR REPLACE FUNCTION public.trg_pet_set_age()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.birthday IS NOT NULL THEN
    NEW.age := DATE_PART('year', AGE(CURRENT_DATE, NEW.birthday));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pets_set_age ON public.pets;
CREATE TRIGGER trg_pets_set_age
  BEFORE INSERT OR UPDATE OF birthday ON public.pets
  FOR EACH ROW EXECUTE FUNCTION public.trg_pet_set_age();

-- 5. 视图：方便查询年龄（若不想用触发器，可在客户端计算）
DROP VIEW IF EXISTS public.pet_details;
CREATE VIEW public.pet_details AS
SELECT  p.*,
        DATE_PART('year', AGE(CURRENT_DATE, p.birthday)) AS computed_age
FROM    public.pets p;