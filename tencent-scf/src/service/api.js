const Providers = require('../providers/index.js');
const { format: lyricFormat, get_url } = require('../util.js');

module.exports = async (event) => {
  const p = new Providers()
  const query = event.queryStringParameters || event.queryString || {}
  const server = query.server || 'netease'
  const type = query.type || 'playlist'
  const id = query.id || '6907557348'

  if (!p.get_provider_list().includes(server) || !p.get(server).support_type.includes(type)) {
    // status 400
    return { statusCode: 400, headers: { "Content-Type": "application/json" }, body: JSON.stringify({ status: 400, message: 'server 参数不合法', param: { server, type, id } }) }
  }

  let data = await p.get(server).handle(type, id)

  if (type === 'url') {
    let url = data
    if (!url) {
      // status 403
      return { statusCode: 403, headers: { "Content-Type": "application/json" }, body: JSON.stringify({ error: "no url" }) }
    }
    if (url.startsWith('@'))
      return { statusCode: 200, headers: { "Content-Type": "text/plain" }, body: url }
    return { statusCode: 302, headers: { "Location": url }, body: "" }
  }

  if (type === 'pic') {
    return { statusCode: 302, headers: { "Location": data }, body: "" }
  }

  if (type === 'lrc') {
    return { statusCode: 200, headers: { "Content-Type": "text/plain; charset=utf-8" }, body: lyricFormat(data.lyric, data.tlyric || '') }
  }

  return { statusCode: 200, headers: { "Content-Type": "application/json" }, body: JSON.stringify(data.map(x => {
    for (let i of ['url', 'pic', 'lrc']) {
      const _ = String(x[i])
      if (!_.startsWith('@') && !_.startsWith('http') && _.length > 0) {
        x[i] = `${get_url(event)}/api?server=${server}&type=${i}&id=${_}`
      }
    }
    return x
  })) } }

