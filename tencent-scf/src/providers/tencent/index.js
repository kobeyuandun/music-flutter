const { get_playlist } = require('./playlist.js');
const { get_song_url, get_song_info, get_pic } = require('./song.js');
const { get_lyric } = require('./lyric.js');

const support_type = ['url', 'pic', 'lrc', 'song', 'playlist']

const handle = async (type, id, cookie = '') => {
    let result;
    switch (type) {
        case 'lrc':
            result = await get_lyric(id)
            break
        case 'pic':
            result = await get_pic(id)
            break
        case 'url':
            result = await get_song_url(id)
            break
        case 'song':
            result = await get_song_info(id)
            break
        case 'playlist':
            result = await get_playlist(id)
            break
        default:
            return -1;
    }
    return result
}

module.exports = {
    register: (ctx) => {
        ctx.register('tencent', { handle, support_type })
    }
}
