-- AlterTable
ALTER TABLE "pets" ADD COLUMN     "image_urls" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "video_url" TEXT;
