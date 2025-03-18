declare module 'bun' {
  interface Env {
    PORT: string;
    MAIN_PATH: string;
    THUMB_PATH: string;
    PHOTO_PATH: string;

    ORIGIN_URL: string;
    DOMAIN_NAME: string;

    SECRET_KEY: string;

    COMMAND: string;
    DB_INSERT: string;
    DB_HOST: string;
    DB_USER: string;
    DB_PASS: string;
    DB_NAME: string;
  }
}
