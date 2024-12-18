import { Hono } from "hono";
import { logger } from "hono/logger";
import home from './routes/home'
import { album } from './routes/album'

const app = new Hono();


app.use('*', logger())



app.get("/", c => {
    return c.json({"msg": "Mainpage"});
})

app.route('/home', home);
app.route('/album', album);
app.route('/upload', album);

// app.post
// app.put
// app.delete

export default app