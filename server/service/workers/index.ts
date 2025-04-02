import os from 'os';

export const MAX_CONCURRENT_WORKERS = Math.max(1, os.cpus().length - 2); // Number of parallel operations

export const workerQueue = async (tasks: (() => Promise<void>)[], workerLimit: number = MAX_CONCURRENT_WORKERS) => {
  const executing: Promise<void>[] = [];

  for (const task of tasks) {
    const promise = task().finally(() => {
      executing.splice(executing.indexOf(promise), 1); // Remove completed task
    });

    executing.push(promise);

    if (executing.length >= workerLimit) {
      await Promise.race(executing); // Wait for at least one to finish
    }
  }

  await Promise.allSettled(executing); // Ensure all workers finish before exiting
};
