import type { UUID } from 'crypto';
import { createMiddleware } from 'hono/factory';
import { getUserBySession } from './validateAuth';

type TaskKey = 'captioning' | 'editing' | 'detecting' | 'importing';

type TaskState = {
  [key in TaskKey]: UUID | null;
};

// const activeTasks: TaskState = { captioning: false, editing: false, detecting: false, importing: false };

const activeTasks: TaskState = { captioning: null, editing: null, detecting: null, importing: null };

const isTaskRunning = (key: TaskKey): UUID | null => activeTasks[key];

// Process Upload/Admin Reindex from one client at a time to avoid server overhead
export const taskStatusMiddleware = (taskName: TaskKey) =>
  createMiddleware(async (c, next) => {
    const taskRunningId = isTaskRunning(taskName);

    const user = getUserBySession(c);
    if (!user || !user.userId) return c.json({ error: '❌ User not found. Please login and try again' }, 503);

    // if current task is not running OR current user running current task, return true
    if (!taskRunningId || user.userId === taskRunningId) return await next();

    return c.json({ error: '❌ Background processing. Try again shortly.' }, 503);
  });

// const isAnyTaskRunning = (): UUID => Object.values(activeTasks).some(UUID);
// export const taskImportStatusMiddleware = createMiddleware(async (c, next) => {
//   if (!isAnyTaskRunning()) return await next();
//   return c.json({ error: '❌ Background processing data. Try again shortly.' }, 503);
// });

export const markTaskStart = (key: TaskKey, userId: UUID): void => {
  activeTasks[key] = userId;
};

export const markTaskEnd = (key: TaskKey): void => {
  activeTasks[key] = null;
};
