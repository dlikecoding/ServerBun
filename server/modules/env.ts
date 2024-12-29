declare module 'bun' {
  interface Env {
    PORT: string;
    SOURCE_IMPORT: string;
    COMMAND: string;
    DB_INSERT: string;
    DB_HOST: string;
    DB_USER: string;
    DB_PASS: string;
    DB_NAME: string;
  }
}
