import { Hono } from "hono";

const upload = new Hono();

upload.get('/', (c) => {
    return c.json({ "uploadpage": 'YOU ARE upload' })
})


export { upload };