const { request } = require('./util.js');
const { map_song_list } = require('./util.js');

const get_artist_songs = async (id, cookie) => {
    id = parseInt(id)
    const data = { id }
    const res = await request('POST', `https://music.163.com/api/artist/top/song`, data, {
        crypto: 'weapi',
        cookie: {},
    })
    return map_song_list(res)
}
module.exports = { get_artist_songs };
