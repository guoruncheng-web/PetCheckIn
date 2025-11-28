-- AlterTable
ALTER TABLE "checkins" ADD COLUMN     "address" TEXT,
ADD COLUMN     "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "video_url" TEXT,
ALTER COLUMN "image_urls" SET DEFAULT ARRAY[]::TEXT[];
