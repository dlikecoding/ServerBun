import type { ValidResult } from '../middleware/validateFiles';

declare module 'hono' {
  interface ContextVariableMap {
    user_session_id: string;
    validated_result: ValidResult;
  }
}
