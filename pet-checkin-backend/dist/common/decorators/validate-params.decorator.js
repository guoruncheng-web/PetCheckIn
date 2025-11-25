"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ValidationRules = void 0;
exports.ValidateParams = ValidateParams;
const common_1 = require("@nestjs/common");
const field_names_1 = require("../constants/field-names");
function ValidateParams(rules) {
    return function (target, propertyName, descriptor) {
        const originalMethod = descriptor.value;
        descriptor.value = function (...args) {
            const paramNames = getParamNames(originalMethod);
            const errors = [];
            rules.forEach((rule, index) => {
                const value = args[index];
                const fieldKey = rule.field || paramNames[index];
                const fieldName = field_names_1.FieldNames[fieldKey] || fieldKey;
                if (rule.required &&
                    (!value || (typeof value === 'string' && value.trim() === ''))) {
                    errors.push({
                        field: fieldKey,
                        errorMsg: rule.message || `${fieldName}不能为空`,
                    });
                    return;
                }
                if (value && (typeof value !== 'string' || value.trim() !== '')) {
                    const stringValue = String(value);
                    if (rule.pattern && !rule.pattern.test(stringValue)) {
                        errors.push({
                            field: fieldKey,
                            errorMsg: rule.message || `${fieldName}格式错误`,
                        });
                    }
                    if (rule.minLength && stringValue.length < rule.minLength) {
                        errors.push({
                            field: fieldKey,
                            errorMsg: rule.message || `${fieldName}长度不能少于${rule.minLength}位`,
                        });
                    }
                    if (rule.maxLength && stringValue.length > rule.maxLength) {
                        errors.push({
                            field: fieldKey,
                            errorMsg: rule.message || `${fieldName}长度不能超过${rule.maxLength}位`,
                        });
                    }
                }
            });
            if (errors.length > 0) {
                throw new common_1.BadRequestException(errors);
            }
            return originalMethod.apply(this, args);
        };
    };
}
function getParamNames(func) {
    const fnStr = func.toString();
    const match = fnStr.match(/\(([^)]*)\)/);
    if (!match)
        return [];
    return match[1]
        .split(',')
        .map((param) => param.trim().split(':')[0].trim())
        .filter((param) => param);
}
exports.ValidationRules = {
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
//# sourceMappingURL=validate-params.decorator.js.map