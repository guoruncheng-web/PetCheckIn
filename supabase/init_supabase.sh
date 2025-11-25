#!/usr/bin/env bash
# Supabase 本地初始化脚本（需安装 supabase CLI）
# 用法：bash init_supabase.sh

set -e

echo "1. 启动本地 Supabase..."
supabase start

echo "2. 应用数据库迁移..."
supabase db reset --linked

echo "3. 创建 Storage 桶（若远程）..."
# 若使用远程项目，请提前配置：
# supabase link --project-ref <your-project-ref>
# supabase db push

echo "4. 插入示例数据（可选）..."
supabase db seed --file seed.sql

echo "5. 获取本地 anon key & URL："
supabase status

echo "6. 配置 Flutter --dart-define："
echo "   SUPABASE_URL=<上方 API URL>"
echo "   SUPABASE_ANON_KEY=<上方 anon key>"
echo "完成！请复制 URL 与 Key 到 Flutter 运行配置。"