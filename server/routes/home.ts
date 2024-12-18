import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
// To create a schema to validate post req
import { z } from "zod";


const home = new Hono();

// Using z to validate if input in valid
const postSchema = z.object({
    homepage: z.string()
})

// Make sure all of id is numbers
home.get('/:id{[0-9]+}', (c) => {
    return c.json({ "homepage": 'YOU ARE HOME' })
})

home.get('/', (c) => {
    return c.json({ "homepage": 'YOU ARE HOME' })
})

home.post('/', zValidator('json', postSchema), (c) => {
    return c.json({ "homepage": 'YOU ARE HOME' })
})

export default home;