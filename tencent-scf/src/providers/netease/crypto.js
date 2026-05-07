const nodeCrypto = require('crypto');
const { webcrypto } = nodeCrypto;
const crypto = webcrypto;

// Node.js native crypto for AES-ECB (not supported by webcrypto)
function aesEncryptNode(plaintext, mode, key, iv) {
  const algorithm = mode === 'ecb' ? 'aes-128-ecb' : 'aes-128-cbc';
  const cipher = nodeCrypto.createCipheriv(algorithm, Buffer.from(key), mode === 'ecb' ? Buffer.alloc(0) : Buffer.from(iv));
  const encrypted = Buffer.concat([cipher.update(Buffer.from(plaintext)), cipher.final()]);
  return new Uint8Array(encrypted);
}

const iv = new Uint8Array([48, 49, 48, 50, 48, 51, 48, 52, 48, 53, 48, 54, 48, 55, 48, 56]) // '0102030405060708'
const presetKey = new Uint8Array([48, 67, 111, 74, 85, 109, 54, 81, 121, 119, 56, 87, 56, 106, 117, 100]) // '0CoJUm6Qyw8W8jud'
const linuxapiKey = new Uint8Array([114, 70, 103, 66, 38, 104, 35, 37, 50, 63, 94, 101, 68, 103, 58, 81]) // 'rFgB&h#%2?^eDg:Q'
const eapiKey = new Uint8Array([101, 56, 50, 99, 107, 101, 110, 104, 56, 100, 105, 99, 104, 101, 110, 56]) // 'e82ckenh8dichen8'
const base62 = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

const publicKeyPem = `-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgtQn2JZ34ZC28NWYpAUd98iZ3
7BUrX/aKzmFbt7clFSs6sXqHauqKWqdtLkF2KexO40H1YTX8z2lSgBBOAxLsvakl
V8k4cBFK9snQXE9/DDaFt6Rr7iVZMldczhC0JNgTz+SHXT6CBHuX3e9SdB1Ua44o
ncaTWz7OBGLbCiK45wIDAQAB
-----END PUBLIC KEY-----`

function textToBytes(text) {
  return new TextEncoder().encode(text)
}

function bytesToBase64(bytes) {
  let binary = ''
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return btoa(binary)
}

function bytesToHex(bytes) {
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('')
}

async function aesEncrypt(plaintext, mode, key, iv) {
  // Always use Node.js native crypto for AES (works for both CBC and ECB)
  return aesEncryptNode(plaintext, mode, key, iv);
}

async function rsaEncrypt(buffer, pem) {
  // Parse PEM to get raw public key bytes
  const pemBody = pem.replace(/-----BEGIN PUBLIC KEY-----/, '').replace(/-----END PUBLIC KEY-----/, '').replace(/\s/g, '')
  const binaryStr = atob(pemBody)
  const keyBytes = new Uint8Array(binaryStr.length)
  for (let i = 0; i < binaryStr.length; i++) keyBytes[i] = binaryStr.charCodeAt(i)

  const cryptoKey = await crypto.subtle.importKey('spki', keyBytes, { name: 'RSA-OAEP', hash: 'SHA-1' }, false, ['encrypt'])

  // Pad to 128 bytes (RSA_NO_PADDING equivalent: zero-pad then encrypt)
  const padded = new Uint8Array(128)
  const offset = 128 - buffer.length
  padded.set(buffer, offset)

  // Use RSA-OAEP with no label as a fallback approach
  // Since Workers don't support RSA_NO_PADDING, we use a workaround
  try {
    const encrypted = await crypto.subtle.encrypt({ name: 'RSA-OAEP', hash: 'SHA-1' }, cryptoKey, buffer)
    return new Uint8Array(encrypted)
  } catch (e) {
    // Fallback: manual RSA with raw key bytes
    throw new Error('RSA encryption failed: ' + e.message)
  }
}

// Simpler approach: use the original algorithm but with Web Crypto
// For Cloudflare Workers, we use AES + a pre-computed RSA result approach
// Actually, let's just import the key properly

const weapi = async (object) => {
  const text = JSON.stringify(object)

  // Generate random secret key
  const randomBytes = crypto.getRandomValues(new Uint8Array(16))
  const secretKey = new Uint8Array(16)
  for (let i = 0; i < 16; i++) {
    secretKey[i] = base62.charCodeAt(randomBytes[i] % 62)
  }

  // First AES-CBC encryption
  const firstEncrypted = await aesEncrypt(textToBytes(text), 'cbc', presetKey, iv)
  const firstBase64 = bytesToBase64(firstEncrypted)

  // Second AES-CBC encryption with secret key
  const secondEncrypted = await aesEncrypt(textToBytes(firstBase64), 'cbc', secretKey, iv)

  // RSA encrypt the reversed secret key
  const reversedKey = new Uint8Array(secretKey.reverse())

  // For RSA, we need a different approach since Workers don't have RSA_NO_PADDING
  // We'll use a pre-built implementation or a math-based one
  const encSecKey = await rsaEncryptRaw(reversedKey)

  return {
    params: bytesToBase64(secondEncrypted),
    encSecKey: encSecKey
  }
}

const linuxapi = async (object) => {
  const text = JSON.stringify(object)
  const encrypted = await aesEncrypt(textToBytes(text), 'ecb', linuxapiKey, new Uint8Array(0))
  return {
    eparams: bytesToHex(encrypted).toUpperCase()
  }
}

const eapi = async (url, object) => {
  const text = typeof object === 'object' ? JSON.stringify(object) : object
  const message = `nobody${url}use${text}md5forencrypt`

  // Use Node.js native MD5 (always available in Node.js)
  const digest = nodeCrypto.createHash('md5').update(message).digest('hex')
  const data = `${url}-36cd479b6b5-${text}-36cd479b6b5-${digest}`
  const encrypted = await aesEncrypt(textToBytes(data), 'ecb', eapiKey, new Uint8Array(0))
  return {
    params: bytesToHex(encrypted).toUpperCase()
  }
}

// Simple MD5 implementation for Cloudflare Workers
async function md5(message) {
  // Cloudflare Workers actually support MD5 through crypto.subtle
  // But just in case, here's a pure JS implementation
  const msgBuffer = typeof message === 'string' ? textToBytes(message) : message

  try {
    const hashBuffer = await crypto.subtle.digest('MD5', msgBuffer)
    return bytesToHex(new Uint8Array(hashBuffer))
  } catch (e) {
    // Pure JS MD5 fallback
    return md5Pure(msgBuffer)
  }
}

// Pure JavaScript MD5 implementation
function md5Pure(input) {
  // Convert input to array of bytes
  const bytes = Array.from(input)

  // Initialize MD5 state
  let a0 = 0x67452301
  let b0 = 0xefcdab89
  let c0 = 0x98badcfe
  let d0 = 0x10325476

  // Pre-processing: adding padding bits
  const origLen = bytes.length
  bytes.push(0x80)
  while (bytes.length % 64 !== 56) bytes.push(0)
  const lenBits = origLen * 8
  for (let i = 0; i < 8; i++) {
    bytes.push((lenBits >>> (i * 8)) & 0xff)
  }

  // Constants
  const S = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
  ]
  const K = []
  for (let i = 0; i < 64; i++) {
    K[i] = Math.floor(Math.abs(Math.sin(i + 1)) * 0x100000000)
  }

  function add32(a, b) { return (a + b) & 0xffffffff }
  function cmn(q, a, b, x, s, t) { return add32(rol(add32(add32(a, q), add32(x, t)), s), b) }
  function ff(a, b, c, d, x, s, t) { return cmn((b & c) | ((~b) & d), a, b, x, s, t) }
  function gg(a, b, c, d, x, s, t) { return cmn((b & d) | (c & (~d)), a, b, x, s, t) }
  function hh(a, b, c, d, x, s, t) { return cmn(b ^ c ^ d, a, b, x, s, t) }
  function ii(a, b, c, d, x, s, t) { return cmn(c ^ (b | (~d)), a, b, x, s, t) }
  function rol(num, cnt) { return (num << cnt) | (num >>> (32 - cnt)) }

  // Process each 512-bit block
  for (let offset = 0; offset < bytes.length; offset += 64) {
    const M = []
    for (let j = 0; j < 16; j++) {
      M[j] = bytes[offset + j * 4] | (bytes[offset + j * 4 + 1] << 8) |
             (bytes[offset + j * 4 + 2] << 16) | (bytes[offset + j * 4 + 3] << 24)
    }

    let A = a0, B = b0, C = c0, D = d0

    for (let i = 0; i < 64; i++) {
      let f, g
      if (i < 16) { f = ff(B, C, D, M[i], S[i], K[i]); g = i }
      else if (i < 32) { f = gg(B, C, D, M[(5 * i + 1) % 16], S[i], K[i]); g = (5 * i + 1) % 16 }
      else if (i < 48) { f = hh(B, C, D, M[(3 * i + 5) % 16], S[i], K[i]); g = (3 * i + 5) % 16 }
      else { f = ii(B, C, D, M[(7 * i) % 16], S[i], K[i]); g = (7 * i) % 16 }

      const temp = D; D = C; C = B; B = add32(B, f); A = temp
    }

    a0 = add32(a0, A); b0 = add32(b0, B); c0 = add32(c0, C); d0 = add32(d0, D)
  }

  // Produce the final hash value (little-endian)
  const result = []
  for (const val of [a0, b0, c0, d0]) {
    for (let i = 0; i < 4; i++) {
      result.push((val >>> (i * 8)) & 0xff)
    }
  }
  return result.map(b => b.toString(16).padStart(2, '0')).join('')
}

// RSA raw encryption (RSA_NO_PADDING equivalent)
// Uses basic modular exponentiation with parsed public key
async function rsaEncryptRaw(data) {
  // Parse the PEM public key to extract n and e
  const pemBody = publicKeyPem.replace(/-----BEGIN PUBLIC KEY-----/, '').replace(/-----END PUBLIC KEY-----/, '').replace(/\s/g, '')
  const derBytes = atob(pemBody)
  const der = new Uint8Array(derBytes.length)
  for (let i = 0; i < derBytes.length; i++) der[i] = derBytes.charCodeAt(i)

  // Parse DER-encoded SubjectPublicKeyInfo for RSA
  // Skip ASN.1 header to get to the modulus and exponent
  // The public key is in PKCS#1 format inside SubjectPublicKeyInfo
  // For a 1024-bit key, modulus is 128 bytes

  // Simple DER parser for RSA public key
  let idx = 0
  function readTag() { return der[idx++] }
  function readLength() {
    let len = der[idx++]
    if (len & 0x80) {
      const numBytes = len & 0x7f
      len = 0
      for (let i = 0; i < numBytes; i++) len = (len << 8) | der[idx++]
    }
    return len
  }
  function readInteger() {
    readTag() // INTEGER tag 0x02
    const len = readLength()
    const bytes = der.slice(idx, idx + len)
    idx += len
    // Remove leading zero byte (sign byte)
    let start = 0
    if (bytes[0] === 0) start = 1
    return bytes.slice(start)
  }

  // SubjectPublicKeyInfo wrapping
  readTag() // SEQUENCE
  readLength() // length
  // AlgorithmIdentifier
  readTag() // SEQUENCE
  const algLen = readLength()
  idx += algLen // skip algorithm identifier bytes
  // BIT STRING
  readTag() // BIT STRING 0x03
  readLength()
  idx++ // skip unused bits byte
  // RSAPublicKey (PKCS#1)
  readTag() // SEQUENCE
  readLength()

  const nBytes = readInteger() // modulus
  const eBytes = readInteger() // exponent

  // Convert to BigInt
  let n = 0n
  for (const b of nBytes) n = (n << 8n) | BigInt(b)
  let e = 0n
  for (const b of eBytes) e = (e << 8n) | BigInt(b)

  // Convert data to BigInt (big-endian, 128 bytes with zero padding)
  const padded = new Uint8Array(128)
  const offset = 128 - data.length
  padded.set(data, offset)
  let m = 0n
  for (const b of padded) m = (m << 8n) | BigInt(b)

  // RSA: c = m^e mod n
  const c = modPow(m, e, n)

  // Convert back to hex
  let hex = c.toString(16)
  // Pad to 256 hex chars (128 bytes)
  while (hex.length < 256) hex = '0' + hex

  return hex
}

// Modular exponentiation: base^exp mod modulus using BigInt
function modPow(base, exp, modulus) {
  if (modulus === 1n) return 0n
  let result = 1n
  base = base % modulus
  while (exp > 0n) {
    if (exp % 2n === 1n) {
      result = (result * base) % modulus
    }
    exp = exp >> 1n
    base = (base * base) % modulus
  }
  return result
}

module.exports = { weapi, linuxapi, eapi }
