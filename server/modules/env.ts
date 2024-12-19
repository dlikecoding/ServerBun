declare module 'bun' {
  interface Env {
    PORT: string;
    SOURCE_IMPORT: string;
    COMMAND: string;
    DB_INSERT: string;
  }
}
