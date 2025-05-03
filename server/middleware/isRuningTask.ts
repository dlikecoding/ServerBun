import { createMiddleware } from 'hono/factory';

type TaskKey = 'captioning' | 'editing' | 'detecting';

type TaskState = {
  [key in TaskKey]: boolean;
};

const activeTasks: TaskState = { captioning: false, editing: false, detecting: false };

const isTaskRunning = (key: TaskKey): boolean => activeTasks[key];

export const taskStatusMiddleware = (taskName: TaskKey) =>
  createMiddleware(async (c, next) => {
    if (isTaskRunning(taskName)) {
      return c.json({ error: '❌ Background processing. Try again shortly.' }, 503);
    }
    return await next();
  });

export const markTaskStart = (key: TaskKey): void => {
  activeTasks[key] = true;
};

export const markTaskEnd = (key: TaskKey): void => {
  activeTasks[key] = false;
};
