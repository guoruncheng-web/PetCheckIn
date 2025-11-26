/* eslint-disable @typescript-eslint/no-base-to-string */
import { BadRequestException } from '@nestjs/common';
import { FieldNames } from '../constants/field-names';

export interface ValidationRule {
  field: string; // 英文字段名，会自动从 FieldNames 字典中查找对应的中文名称
  required?: boolean;
  pattern?: RegExp;
  minLength?: number;
  maxLength?: number;
  message?: string; // 自定义错误消息，如果提供则优先使用
}

export interface ValidationError {
  field: string;
  errorMsg: string;
}

export function ValidateParams(rules: ValidationRule[]) {
  return function (
    target: unknown,
    propertyName: string,
    descriptor: PropertyDescriptor,
  ) {
    const originalMethod = descriptor.value as (...args: unknown[]) => unknown;

    descriptor.value = function (...args: unknown[]) {
      // 获取参数名称
      const paramNames = getParamNames(originalMethod);
      const errors: ValidationError[] = [];

      rules.forEach((rule) => {
        // 根据字段名查找对应的参数索引
        const paramIndex = paramNames.findIndex(name => name === rule.field);
        if (paramIndex === -1) {
          return; // 如果找不到对应参数，跳过
        }

        const value = args[paramIndex];
        const fieldKey = rule.field;
        const fieldName = FieldNames[fieldKey] || fieldKey;

        // 必填校验
        if (
          rule.required &&
          (!value || (typeof value === 'string' && value.trim() === ''))
        ) {
          errors.push({
            field: fieldKey,
            errorMsg: rule.message || `${fieldName}不能为空`,
          });
          return; // 如果必填校验失败，跳过后续校验
        }

        // 如果值存在且不为空，进行其他校验
        if (value && (typeof value !== 'string' || value.trim() !== '')) {
          const stringValue = String(value);

          // 正则校验
          if (rule.pattern && !rule.pattern.test(stringValue)) {
            errors.push({
              field: fieldKey,
              errorMsg: rule.message || `${fieldName}格式错误`,
            });
          }

          // 最小长度校验
          if (rule.minLength && stringValue.length < rule.minLength) {
            errors.push({
              field: fieldKey,
              errorMsg:
                rule.message || `${fieldName}长度不能少于${rule.minLength}位`,
            });
          }

          // 最大长度校验
          if (rule.maxLength && stringValue.length > rule.maxLength) {
            errors.push({
              field: fieldKey,
              errorMsg:
                rule.message || `${fieldName}长度不能超过${rule.maxLength}位`,
            });
          }
        }
      });

      // 如果有错误，抛出异常
      if (errors.length > 0) {
        throw new BadRequestException(errors);
      }

      // eslint-disable-next-line @typescript-eslint/no-unsafe-return
      return originalMethod.apply(this, args);
    };
  };
}

// 获取函数参数名称
function getParamNames(func: (...args: unknown[]) => unknown): string[] {
  const fnStr = func.toString();
  const match = fnStr.match(/\(([^)]*)\)/);
  if (!match) return [];

  return match[1]
    .split(',')
    .map((param) => param.trim().split(':')[0].trim())
    .filter((param) => param);
}

// 常用校验规则
export const ValidationRules = {
  phone: {
    pattern: /^1[3-9]\d{9}$/,
  },
  password: {
    minLength: 6,
    maxLength: 20,
  },
  otp: {
    pattern: /^\d{4,6}$/,
  },
};
