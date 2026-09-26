"""Open the web build in headless Chrome (DevTools Protocol, stdlib only):
print console messages/errors, click, run JS, save a screenshot at the end.

Usage: py -3.14 tools/browser_check.py <url> <out_prefix> <seconds> [w h] ["x,y@t;js:code@t;..."]
  - serve the build first: py -3.14 -m http.server 8060 --bind 127.0.0.1 -d build/web
  - clicks are in window pixels (the canvas is centred, max 2:1)
  - fake Yandex SDK test: copy tools/fake_yandex_sdk.js to build/web/sdk.js and open
    http://fake.test:8060/ (mapped to localhost below). Delete sdk.js before packing!
"""
import base64, json, os, socket, struct, subprocess, sys, time, urllib.request

url, out, secs = sys.argv[1], sys.argv[2], float(sys.argv[3])
w, h = (int(sys.argv[4]), int(sys.argv[5])) if len(sys.argv) > 5 else (1280, 720)
clicks = []
if len(sys.argv) > 6:
    for c in sys.argv[6].split(';'):
        what, t = c.rsplit('@', 1)
        if what.startswith('js:'):
            clicks.append((float(t), what[3:], None))
        else:
            x, y = what.split(',')
            clicks.append((float(t), int(x), int(y)))
chrome = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
prof = os.path.join(os.environ.get('TEMP', '.'), 'chrome_cdp')
p = subprocess.Popen([chrome, '--headless=new', '--remote-debugging-port=9333', f'--user-data-dir={prof}',
                      '--host-resolver-rules=MAP fake.test 127.0.0.1', '--no-proxy-server', '--unsafely-treat-insecure-origin-as-secure=http://fake.test:8060', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', f'--window-size={w},{h}', 'about:blank'],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
ws_url = None
for _ in range(150):
    try:
        tabs = json.load(urllib.request.urlopen('http://127.0.0.1:9333/json'))
        ws_url = next(t['webSocketDebuggerUrl'] for t in tabs if t['type'] == 'page')
        break
    except Exception:
        time.sleep(0.2)
host, path = ws_url[len('ws://'):].split('/', 1)
hn, port = host.split(':')
s = socket.create_connection((hn, int(port)))
s.send((f"GET /{path} HTTP/1.1\r\nHost: {host}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
        "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
buf = b''
while b'\r\n\r\n' not in buf:
    buf += s.recv(4096)
buf = buf.split(b'\r\n\r\n', 1)[1]

def send(obj):
    data = json.dumps(obj).encode()
    hdr = bytes([0x81])
    n = len(data)
    if n < 126: hdr += bytes([0x80 | n])
    elif n < 65536: hdr += bytes([0x80 | 126]) + struct.pack('>H', n)
    else: hdr += bytes([0x80 | 127]) + struct.pack('>Q', n)
    mask = b'\x01\x02\x03\x04'
    s.send(hdr + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

def need(n):
    global buf
    while len(buf) < n:
        chunk = s.recv(1 << 20)
        if not chunk: raise EOFError
        buf += chunk

def recv():
    global buf
    need(2)
    n = buf[1] & 0x7f; off = 2
    if n == 126: need(4); n = struct.unpack('>H', buf[2:4])[0]; off = 4
    elif n == 127: need(10); n = struct.unpack('>Q', buf[2:10])[0]; off = 10
    need(off + n)
    msg = buf[off:off + n]; buf = buf[off + n:]
    return json.loads(msg)

mid = 0
def call(method, params=None):
    global mid
    mid += 1
    send({'id': mid, 'method': method, 'params': params or {}})
    return mid

call('Runtime.enable'); call('Log.enable'); call('Page.enable'); call('Network.enable'); call('Network.setCacheDisabled', {'cacheDisabled': True})
call('Page.navigate', {'url': url})
s.settimeout(0.3)
start = time.time()
shots = {}
pending = sorted(clicks, key=lambda c: c[0])
while time.time() - start < secs:
    while pending and time.time() - start >= pending[0][0]:
        t, x, y = pending.pop(0)
        if y is None:
            call('Runtime.evaluate', {'expression': x})
            print(f'[{time.time()-start:5.1f}] js {x}')
            continue
        for typ in ('mousePressed', 'mouseReleased'):
            call('Input.dispatchMouseEvent', {'type': typ, 'x': x, 'y': y, 'button': 'left', 'clickCount': 1})
        print(f'[{time.time()-start:5.1f}] click {x},{y}')
    try:
        m = recv()
    except socket.timeout:
        continue
    meth = m.get('method')
    if meth == 'Runtime.consoleAPICalled':
        args = ' '.join(str(a.get('value', a.get('description', ''))) for a in m['params']['args'])
        print(f"[{time.time()-start:5.1f}] console.{m['params']['type']}: {args[:400]}")
    elif meth == 'Runtime.exceptionThrown':
        print(f"[{time.time()-start:5.1f}] EXCEPTION: {json.dumps(m['params']['exceptionDetails'])[:600]}")
    elif meth == 'Log.entryAdded':
        e = m['params']['entry']
        print(f"[{time.time()-start:5.1f}] log.{e['level']}: {e.get('text','')[:400]} {e.get('url','')}")
    elif 'id' in m and m['id'] in shots:
        open(shots.pop(m['id']), 'wb').write(base64.b64decode(m['result']['data']))
s.settimeout(None)
i = call('Page.captureScreenshot', {'format': 'png'})
while True:
    m = recv()
    if m.get('id') == i:
        open(out + '.png', 'wb').write(base64.b64decode(m['result']['data']))
        break
p.kill()
print('saved', out + '.png')
