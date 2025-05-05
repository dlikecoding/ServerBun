import { createMiddleware } from 'hono/factory';

type TaskKey = 'captioning' | 'editing' | 'detecting' | 'importing';

type TaskState = {
  [key in TaskKey]: boolean;
};

const activeTasks: TaskState = { captioning: false, editing: false, detecting: false, importing: false };

// const isTaskRunning = (key: TaskKey): boolean => activeTasks[key];
// export const taskStatusMiddleware = (taskName: TaskKey) =>
//   createMiddleware(async (c, next) => {
//     if (!isTaskRunning(taskName)) return await next();
//     return c.json({ error: '❌ Background processing. Try again shortly.' }, 503);
//   });

// Process Upload/Admin Reindex from one client at a time to avoid server overhead
const isAnyTaskRunning = (): boolean => Object.values(activeTasks).some(Boolean);
export const taskImportStatusMiddleware = createMiddleware(async (c, next) => {
  if (!isAnyTaskRunning()) return await next();
  return c.json({ error: '❌ Background processing data. Try again shortly.' }, 503);
});

export const markTaskStart = (key: TaskKey): void => {
  activeTasks[key] = true;
};

export const markTaskEnd = (key: TaskKey): void => {
  activeTasks[key] = false;
};
