import type { StreamingApi } from 'hono/utils/stream';
import { reducePath } from '../helper';
import path from 'path';

export const reduceFPS = async (sourcePath: string, stream: StreamingApi) => {
  const newSourcePath = sourcePath.split('.')[0] + '.mp4';
  const basename = path.basename(sourcePath);

  const process = Bun.spawn(['ffmpeg', '-i', sourcePath, '-r', '30', '-c:v', 'libx264', '-preset', 'medium', '-crf', '28', '-c:a', 'copy', '-map_metadata', '0', newSourcePath], {
    stderr: 'pipe',
    stdout: 'pipe',
  });

  try {
    const reader = process.stderr.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { value, done } = await reader.read();
      if (done) break;

      const eachLine = decoder.decode(value, { stream: true }).trim();

      if (!eachLine.startsWith('frame=')) continue;
      const timeIndex = eachLine.indexOf('time=');

      const timeStr = eachLine.substring(timeIndex + 5, timeIndex + 13);
      await stream.writeln(`Process @ ${timeStr} - ${basename}`);
    }
  } catch (error) {
    console.warn(error);
  } finally {
    process.kill();
  }

  return (await process.exited) === 0 ? newSourcePath : '';
};

export const mediaUpdate = (absPath: string) => {
  const file = Bun.file(absPath);
  const file_size = file.size;

  const file_name = path.basename(absPath);
  const file_ext = 'MP4';
  const source_file = reducePath(absPath);

  const mime_type = 'video/mp4';

  return { frame_rate: 30, source_file, file_size, mime_type, file_name, file_ext };
};
