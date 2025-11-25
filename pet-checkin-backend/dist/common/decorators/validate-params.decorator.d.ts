export interface ValidationRule {
    field: string;
    required?: boolean;
    pattern?: RegExp;
    minLength?: number;
    maxLength?: number;
    message?: string;
}
export interface ValidationError {
    field: string;
    errorMsg: string;
}
export declare function ValidateParams(rules: ValidationRule[]): (target: unknown, propertyName: string, descriptor: PropertyDescriptor) => void;
export declare const ValidationRules: {
    phone: {
        pattern: RegExp;
    };
    password: {
        minLength: number;
        maxLength: number;
    };
    otp: {
        pattern: RegExp;
    };
};
