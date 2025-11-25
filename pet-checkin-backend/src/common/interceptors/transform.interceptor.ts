import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Response<T> {
  code: number;
  data: T;
  message: string;
}

@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, Response<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<Response<T>> {
    return next.handle().pipe(
      map((data) => {
        // 如果返回的数据已经包含 code/message，直接使用
        if (data && typeof data === 'object' && 'code' in data) {
          return data as Response<T>;
        }

        // 否则包装为统一格式
        const response = context.switchToHttp().getResponse();
        return {
          code: response.statusCode,
          data,
          message: data?.message || 'Success',
        };
      }),
    );
  }
}
