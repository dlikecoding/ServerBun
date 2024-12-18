import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
// To create a schema to validate post req
import { z } from "zod";


const home = new Hono();

// Using z to validate if input in valid
const postSchema = z.object({
    homepage: z.string()
})

home.get('/', zValidator('json', postSchema), (c) => {
    return c.json({ "homepage": 'YOU ARE HOME' })
})


export default home;