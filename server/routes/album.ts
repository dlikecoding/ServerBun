import { Hono } from 'hono'

const album = new Hono()

album.get('/', (c) => {
  return c.json({ albumpage: 'YOU ARE album' })
})

export { album }
