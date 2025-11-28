# 数据库迁移说明 - 打卡功能增强

## 迁移日期
2025-11-28

## 迁移名称
`20251128035509_add_checkin_video_tags_address`

## 变更内容

### CheckIn 表新增字段

| 字段名 | 类型 | 说明 | 是否必填 | 默认值 |
|--------|------|------|----------|--------|
| `video_url` | TEXT | 视频URL（1个） | 否 | NULL |
| `tags` | TEXT[] | 标签数组 | 否 | [] |
| `address` | TEXT | 详细地址 | 否 | NULL |

### 变更的字段

| 字段名 | 变更内容 |
|--------|----------|
| `image_urls` | 添加默认值 `[]` |

## SQL 迁移脚本

```sql
-- AlterTable
ALTER TABLE "checkins"
ADD COLUMN "address" TEXT,
ADD COLUMN "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN "video_url" TEXT,
ALTER COLUMN "image_urls" SET DEFAULT ARRAY[]::TEXT[];
```

## API 接口变更

### 创建打卡接口

**请求路径**: `POST /api/checkins`

**请求头**:
```json
{
  "Authorization": "Bearer <jwt-token>"
}
```

**请求体**:
```json
{
  "petId": "uuid",
  "content": "今天天气不错，带着毛球去公园玩了",
  "imageUrls": [
    "https://oss.example.com/image1.jpg",
    "https://oss.example.com/image2.jpg"
  ],
  "videoUrl": "https://oss.example.com/video.mp4",
  "tags": ["开心", "散步", "公园"],
  "address": "广州市天河区天河路123号",
  "cityCode": "440100",
  "cityName": "广州市",
  "latitude": 23.1234,
  "longitude": 113.5678
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| petId | string | ✅ | 宠物ID |
| content | string | ❌ | 心情文案（最多200字） |
| imageUrls | string[] | ❌ | 图片URLs（最多9张） |
| videoUrl | string | ❌ | 视频URL（1个） |
| tags | string[] | ❌ | 标签数组 |
| address | string | ❌ | 详细地址 |
| cityCode | string | ❌ | 城市代码（用于同城筛选） |
| cityName | string | ❌ | 城市名称 |
| latitude | number | ❌ | 纬度 |
| longitude | number | ❌ | 经度 |

**响应示例**:
```json
{
  "id": "uuid",
  "userId": "uuid",
  "petId": "uuid",
  "content": "今天天气不错，带着毛球去公园玩了",
  "imageUrls": ["https://oss.example.com/image1.jpg"],
  "videoUrl": "https://oss.example.com/video.mp4",
  "tags": ["开心", "散步", "公园"],
  "address": "广州市天河区天河路123号",
  "cityCode": "440100",
  "cityName": "广州市",
  "latitude": 23.1234,
  "longitude": 113.5678,
  "createdAt": "2025-11-28T03:55:09.000Z",
  "updatedAt": "2025-11-28T03:55:09.000Z"
}
```

## DTO 文件

已创建以下DTO文件：

1. `src/modules/checkins/dto/create-checkin.dto.ts` - 创建打卡DTO
2. `src/modules/checkins/dto/query-checkin.dto.ts` - 查询打卡DTO

## 前端集成

前端打卡页面需要收集以下信息：

1. **必填字段**:
   - 选择宠物 (petId)

2. **可选字段**:
   - 心情文案 (content) - 最多200字
   - 图片 (imageUrls) - 最多9张
   - 视频 (videoUrl) - 1个
   - 标签 (tags) - 数组，支持自定义
   - 地理位置信息：
     - 详细地址 (address) - 通过逆地理编码获取
     - 城市代码 (cityCode)
     - 城市名称 (cityName)
     - 经纬度 (latitude, longitude)

## 回滚方案

如果需要回滚此迁移，执行以下SQL：

```sql
-- 移除新增字段
ALTER TABLE "checkins"
DROP COLUMN "address",
DROP COLUMN "tags",
DROP COLUMN "video_url";

-- 移除默认值
ALTER TABLE "checkins"
ALTER COLUMN "image_urls" DROP DEFAULT;
```

## 注意事项

1. **图片数量限制**: 前端需要验证最多上传9张图片
2. **视频数量限制**: 只能上传1个视频
3. **文案长度**: 心情文案最多200字
4. **标签**: 标签数组无数量限制，但建议前端限制在10个以内
5. **地址信息**:
   - `address` 存储完整的人类可读地址
   - `cityCode` 用于同城动态筛选
   - 经纬度用于精确定位

## 测试清单

- [ ] 创建打卡（只有图片）
- [ ] 创建打卡（只有视频）
- [ ] 创建打卡（图片+视频）
- [ ] 创建打卡（带标签）
- [ ] 创建打卡（带地址信息）
- [ ] 查询同城打卡（按cityCode筛选）
- [ ] 验证图片数量限制（最多9张）
- [ ] 验证视频数量限制（1个）
- [ ] 验证文案长度限制（200字）
