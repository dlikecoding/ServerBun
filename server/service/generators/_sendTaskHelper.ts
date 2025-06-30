export const BATCH_SIZE_UPDATE_CAPTION = 200;

/**
 * Sends a single task obj to the child process via stdin,
 * then waits and reads stdout line by line until it receives
 * a valid JSON response.
 *
 * Assumes:
 * - The child process outputs one JSON object per task on stdout.
 * - The response for each task arrives before the next task is sent.
 *
 * Parameters:
 * @param task - The task obj to send to the child process.
 * @param childProc - A Bun subprocess with 'pipe' mode for stdin and stdout.
 * @param reader - A shared ReadableStreamDefaultReader for reading stdout from the child.
 *
 * Returns:
 * A Promise that resolves with the parsed JSON response from the child process.
 *
 * Throws:
 * If the child process closes before a valid JSON response is received.
 */
export const sendTask = async (mediaObj: object, childProc: Bun.Subprocess<'pipe', 'pipe', 'inherit'>, reader: ReadableStreamDefaultReader<Uint8Array>) => {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();

  // Serialize task as JSON and write it to the child process
  childProc.stdin.write(encoder.encode(JSON.stringify(mediaObj) + '\n'));

  // Wait for a JSON response line from the child
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;

    const text = decoder.decode(value, { stream: true }).trim();
    for (const line of text.split('\n')) {
      try {
        return JSON.parse(line);
      } catch {} // ignore non-JSON lines
    }
  }

  throw new Error('Child process closed before sending a JSON response');
};
