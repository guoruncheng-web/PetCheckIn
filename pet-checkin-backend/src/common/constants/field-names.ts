/**
 * 全局字段名称映射字典
 * key: 英文字段名
 * value: 中文显示名称
 */
export const FieldNames: Record<string, string> = {
  // 认证相关
  phone: '手机号',
  password: '密码',
  code: '验证码',
  nickname: '昵称',

  // 用户资料相关
  avatarUrl: '头像',
  bio: '个人简介',
  cityCode: '城市代码',
  cityName: '城市名称',

  // 宠物相关
  petName: '宠物名称',
  petType: '宠物类型',
  petBreed: '宠物品种',
  petBirthday: '宠物生日',
  petGender: '宠物性别',

  // 打卡相关
  content: '内容',
  images: '图片',
  location: '位置',

  // 评论相关
  comment: '评论',
  commentId: '评论ID',

  // 通用
  id: 'ID',
  userId: '用户ID',
  petId: '宠物ID',
  checkinId: '打卡ID',
};
