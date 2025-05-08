import { sql } from '..';

export const refreshView = async () => {
  return await sql`
    REFRESH MATERIALIZED VIEW multi_schema.suggest_words`;
};
