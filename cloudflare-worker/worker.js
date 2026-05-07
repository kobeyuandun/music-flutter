import api from './src/service/api.js'
import { Hono } from 'hono'
import { cors } from 'hono/cors'

const app = new Hono()

app.use('*', cors())
app.get('/api', api)
app.get('/', (c) => {
  return c.text('Meting API Worker is running')
})

export default app
