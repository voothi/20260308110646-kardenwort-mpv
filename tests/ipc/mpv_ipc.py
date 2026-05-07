import json, os, socket, threading, time, tempfile


def default_ipc_path():
    if os.name == 'nt':
        return r'\\.\pipe\mpv-lls-test'
    return os.path.join(tempfile.gettempdir(), 'mpv-lls-test.sock')


class MpvIpc:
    def __init__(self, path=None):
        self._path = path or default_ipc_path()
        self._rid = 0
        self._lock = threading.Lock()
        self._pending = {}       # request_id -> (Event, [result])
        self._prop_events = {}   # property name -> Event
        self._conn = None

    def connect(self, timeout=5.0):
        deadline = time.time() + timeout
        while True:
            try:
                self._conn = self._open_transport()
                break
            except OSError:
                if time.time() > deadline:
                    raise TimeoutError(f'mpv IPC not ready: {self._path}')
                time.sleep(0.1)
        threading.Thread(target=self._read_loop, daemon=True).start()

    def _open_transport(self):
        if os.name == 'nt':
            return open(self._path, 'r+b', buffering=0)
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(self._path)
        return s.makefile('rwb', buffering=0)

    def _read_loop(self):
        buf = b''
        while True:
            try:
                chunk = self._conn.read(4096)
                if not chunk:
                    break
                buf += chunk
                while b'\n' in buf:
                    line, buf = buf.split(b'\n', 1)
                    msg = json.loads(line)
                    self._dispatch(msg)
            except (OSError, json.JSONDecodeError):
                break

    def _dispatch(self, msg):
        if 'request_id' in msg:
            with self._lock:
                entry = self._pending.get(msg['request_id'])
            if entry:
                ev, holder = entry
                holder.append(msg)
                ev.set()
        elif msg.get('event') == 'property-change':
            name = msg.get('name', '')
            ev = self._prop_events.get(name)
            if ev:
                ev.set()

    def command(self, cmd, timeout=5.0):
        with self._lock:
            self._rid += 1
            rid = self._rid
            ev, holder = threading.Event(), []
            self._pending[rid] = (ev, holder)
        self._conn.write(json.dumps({'command': cmd, 'request_id': rid}).encode() + b'\n')
        if not ev.wait(timeout):
            raise TimeoutError(f'mpv timeout on {cmd}')
        with self._lock:
            del self._pending[rid]
        return holder[0]

    def get_property(self, name, timeout=5.0):
        r = self.command(['get_property', name], timeout)
        if r.get('error') != 'success':
            raise RuntimeError(f'get_property({name}): {r}')
        return r['data']

    def observe_property(self, obs_id, name):
        self.command(['observe_property', obs_id, name])
        self._prop_events[name] = threading.Event()

    def wait_property_change(self, name, timeout=2.0):
        ev = self._prop_events.get(name)
        if not ev or not ev.wait(timeout):
            raise TimeoutError(f'property-change timeout: {name}')
        ev.clear()

    def close(self):
        if self._conn:
            try:
                self._conn.close()
            except OSError:
                pass


def query_lls_state(ipc, timeout=2.0):
    ipc.observe_property(99, 'user-data/lls/state')
    ipc.command(['script-message-to', 'lls_core', 'lls-state-query'])
    ipc.wait_property_change('user-data/lls/state', timeout)
    raw = ipc.get_property('user-data/lls/state')
    return json.loads(raw) if raw else {}


def query_lls_render(ipc, overlay_name, timeout=2.0):
    ipc.observe_property(98, 'user-data/lls/render')
    ipc.command(['script-message-to', 'lls_core', 'lls-render-query', overlay_name])
    ipc.wait_property_change('user-data/lls/render', timeout)
    return ipc.get_property('user-data/lls/render') or ''
