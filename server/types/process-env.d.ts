export {};

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      PORT: number | 3000;
      NODE_ENV: 'dev' | 'production';

      MAIN_PATH: string;
      THUMB_PATH: string;
      UPLOAD_PATH: string;
      PHOTO_PATH: string;

      ORIGIN_URL: string;
      DOMAIN_NAME: string;

      SECRET_KEY: string;

      DB_HOST: string;
      DB_USER: string;
      DB_PASS: string;
      DB_NAME: string;
      DB_PORT: number;

      DB_CREATE: string;
      DB_MODEL: string;
      DB_TRIGGER: string;

      DB_BACKUP: string;
      // PROXY_ENABLED: 'true' | 'false';
    }
  }
}
