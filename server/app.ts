import { Hono } from "hono";
import { logger } from "hono/logger";
import { serveStatic } from "hono/bun";
import home from './routes/home'
// import { album } from './routes/album'


const app = new Hono();

app.use('*', logger())

// app.get("/", c => {
//     return c.json({"msg": "Mainpage"});
// })

const apiRoutes = app.basePath("api").route('/home', home);
// app.route('/api/album', album);
// app.route('/api/upload', album);

// app.post
// app.put
// app.delete

// app.get('*', serveStatic({
//     root: './frontend/dist',
//     path: './frontend/dist/index.html'
// }))
app.get('*', serveStatic({root: './frontend/dist'}))
app.get('*', serveStatic({path: './frontend/dist/index.html'}))

export default app
export type ApiRoutes = typeof apiRoutes