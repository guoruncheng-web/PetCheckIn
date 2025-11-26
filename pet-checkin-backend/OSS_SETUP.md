# 阿里云 OSS 配置指南

## 1. 创建 OSS Bucket

### 步骤：

1. **登录阿里云控制台**
   ```
   https://oss.console.aliyun.com/
   ```

2. **创建 Bucket**
   - 点击「创建 Bucket」按钮
   - **Bucket 名称**：`pet-checkin` (全局唯一，需自己取名)
   - **地域**：选择离用户最近的（如：华东1-杭州 `oss-cn-hangzhou`）
   - **存储类型**：标准存储
   - **读写权限**：私有（推荐，通过签名URL访问）
   - **版本控制**：不开启
   - **服务端加密**：无

3. **获取 AccessKey**
   - 访问 RAM 控制台：https://ram.console.aliyun.com/manage/ak
   - 点击「创建 AccessKey」
   - **保存好 AccessKeyId 和 AccessKeySecret**（只显示一次）

4. **配置跨域 CORS（可选，如果前端直传需要）**
   - 进入 Bucket 管理页面
   - 数据安全 → 跨域设置 → 创建规则
   - 来源：`*` 或具体域名
   - 允许 Methods：`GET, POST, PUT`
   - 允许 Headers：`*`
   - 暴露 Headers：`ETag`

## 2. 安装依赖

```bash
npm install ali-oss
```

或手动添加到 `package.json`:

```json
{
  "dependencies": {
    "ali-oss": "^6.20.0"
  }
}
```

## 3. 配置环境变量

在 `.env.development` 中添加：

```env
# 阿里云 OSS 配置
ALIYUN_OSS_ACCESS_KEY_ID=你的AccessKeyId
ALIYUN_OSS_ACCESS_KEY_SECRET=你的AccessKeySecret
ALIYUN_OSS_REGION=oss-cn-hangzhou
ALIYUN_OSS_BUCKET=pet-checkin
ALIYUN_OSS_ENDPOINT=oss-cn-hangzhou.aliyuncs.com
```

## 4. 文件结构

```
src/
├── modules/
│   └── storage/
│       ├── storage.module.ts
│       ├── storage.controller.ts
│       └── storage.service.ts
```

## 5. 使用示例

### 后端上传（推荐）

**优点：**
- AccessKey 不暴露给客户端
- 统一控制文件命名、大小、格式
- 更容易实现权限控制

**流程：**
1. Flutter 选择图片
2. 发送图片到后端 `/api/storage/upload`
3. 后端上传到 OSS
4. 返回 OSS URL 给前端
5. 前端更新用户头像 URL

### 前端直传（不推荐，需要暴露凭证）

只在特殊场景使用，需要后端提供临时凭证（STS Token）

## 6. 测试上传

```bash
# 使用 curl 测试
curl -X POST http://localhost:3000/api/storage/upload \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@/path/to/image.jpg" \
  -F "type=avatar"
```

## 7. OSS 费用说明

- **存储费用**：标准存储约 ¥0.12/GB/月
- **流量费用**：外网流出流量约 ¥0.50/GB
- **请求费用**：PUT 请求 ¥0.01/万次，GET 请求 ¥0.01/万次
- **免费额度**：新用户有 3 个月免费额度

## 8. 安全建议

1. ✅ 使用 RAM 子账号，只授予 OSS 权限
2. ✅ Bucket 设置为私有，通过签名 URL 访问
3. ✅ 不要将 AccessKey 提交到 Git
4. ✅ 生产环境使用 STS 临时凭证（如果前端直传）
5. ✅ 设置防盗链（Referer 白名单）
6. ✅ 启用 HTTPS

## 9. 常见问题

**Q: Bucket 名称已存在？**
A: Bucket 名称全局唯一，换一个名称

**Q: AccessDenied 错误？**
A: 检查 AccessKey 权限，确保有 OSS 操作权限

**Q: 图片无法访问？**
A: 如果 Bucket 是私有的，需要使用签名 URL

**Q: 跨域错误？**
A: 配置 Bucket 的 CORS 规则

## 10. 相关链接

- OSS 控制台：https://oss.console.aliyun.com/
- OSS 文档：https://help.aliyun.com/zh/oss/
- RAM 控制台：https://ram.console.aliyun.com/
- 价格计算器：https://www.aliyun.com/price/product#/oss/detail
