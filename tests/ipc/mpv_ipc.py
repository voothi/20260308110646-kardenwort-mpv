import json, os, socket, threading, time, tempfile

# On Windows, synchronous named pipe handles do NOT support concurrent ReadFile
# + WriteFile from different threads on the same handle. Fix: open with
# FILE_FLAG_OVERLAPPED so reads and writes are independent async operations.
if os.name == 'nt':
    import ctypes
    import ctypes.wintypes as _wt

    _k32 = ctypes.WinDLL('kernel32', use_last_error=True)

    _k32.CreateFileW.restype      = ctypes.c_void_p
    _k32.CreateEventW.restype     = ctypes.c_void_p
    _k32.CloseHandle.argtypes     = [ctypes.c_void_p]
    _k32.CloseHandle.restype      = _wt.BOOL
    _k32.CancelIoEx.argtypes      = [ctypes.c_void_p, ctypes.c_void_p]
    _k32.CancelIoEx.restype       = _wt.BOOL
    _k32.ReadFile.argtypes        = [ctypes.c_void_p, ctypes.c_char_p, _wt.DWORD,
                                     ctypes.POINTER(_wt.DWORD), ctypes.c_void_p]
    _k32.ReadFile.restype         = _wt.BOOL
    _k32.WriteFile.argtypes       = [ctypes.c_void_p, ctypes.c_char_p, _wt.DWORD,
                                     ctypes.POINTER(_wt.DWORD), ctypes.c_void_p]
    _k32.WriteFile.restype        = _wt.BOOL
    _k32.GetOverlappedResult.argtypes = [ctypes.c_void_p, ctypes.c_void_p,
                                          ctypes.POINTER(_wt.DWORD), _wt.BOOL]
    _k32.GetOverlappedResult.restype  = _wt.BOOL
    _k32.WaitForSingleObject.argtypes = [ctypes.c_void_p, _wt.DWORD]
    _k32.WaitForSingleObject.restype  = _wt.DWORD

    _GENERIC_READ        = 0x80000000
    _GENERIC_WRITE       = 0x40000000
    _OPEN_EXISTING       = 3
    _FILE_FLAG_OVERLAPPED = 0x40000000
    _ERROR_IO_PENDING    = 997
    _INFINITE            = 0xFFFFFFFF

    class _OVERLAPPED(ctypes.Structure):
        _fields_ = [
            ('Internal',     ctypes.c_size_t),   # ULONG_PTR
            ('InternalHigh', ctypes.c_size_t),   # ULONG_PTR
            ('Offset',       _wt.DWORD),
            ('OffsetHigh',   _wt.DWORD),
            ('hEvent',       ctypes.c_void_p),
        ]

    class _WinPipe:
        def __init__(self, path):
            h = _k32.CreateFileW(path,
                                 _GENERIC_READ | _GENERIC_WRITE,
                                 0, None, _OPEN_EXISTING,
                                 _FILE_FLAG_OVERLAPPED, None)
            if h is None or h == ctypes.c_void_p(-1).value:
                raise OSError(ctypes.get_last_error())
            self._h = h
            ev = _k32.CreateEventW(None, True, False, None)
            if ev is None:
                _k32.CloseHandle(h)
                raise OSError(ctypes.get_last_error())
            self._read_ev = ev

        def read(self, size):
            h = self._h
            if not h:
                raise OSError('pipe closed')
            buf = ctypes.create_string_buffer(size)
            ov  = _OVERLAPPED()
            ov.hEvent = self._read_ev
            n = _wt.DWORD(0)
            ok = _k32.ReadFile(h, buf, size, ctypes.byref(n), ctypes.byref(ov))
            if not ok:
                err = ctypes.get_last_error()
                if err != _ERROR_IO_PENDING:
                    raise OSError(err)
                _k32.WaitForSingleObject(self._read_ev, _INFINITE)
                ok = _k32.GetOverlappedResult(h, ctypes.byref(ov),
                                              ctypes.byref(n), 0)
                if not ok:
                    raise OSError(ctypes.get_last_error())
            return buf.raw[:n.value]

        def write(self, data):
            h = self._h
            if not h:
                raise OSError('pipe closed')
            if isinstance(data, (memoryview, bytearray)):
                data = bytes(data)
            ov = _OVERLAPPED()
            n  = _wt.DWORD(0)
            ok = _k32.WriteFile(h, data, len(data), ctypes.byref(n),
                                ctypes.byref(ov))
            if not ok:
                err = ctypes.get_last_error()
                if err != _ERROR_IO_PENDING:
                    raise OSError(err)
                _k32.GetOverlappedResult(h, ctypes.byref(ov), ctypes.byref(n), 1)

        def close(self):
            h  = self._h
            ev = self._read_ev
            self._h        = None
            self._read_ev  = None
            if h:
                _k32.CancelIoEx(h, None)
                _k32.CloseHandle(h)
            if ev:
                _k32.CloseHandle(ev)


def default_ipc_path():
    if os.name == 'nt':
        return r'\\.\pipe\mpv-lls-test'
    return os.path.join(tempfile.gettempdir(), 'mpv-lls-test.sock')


class MpvIpc:
    def __init__(self, path=None):
        self._path = path or default_ipc_path()
        self._rid  = 0
        self._lock = threading.Lock()
        self._pending    = {}   # request_id -> (Event, [result])
        self._prop_events = {}  # property name -> Event
        self._conn = None

    def connect(self, timeout=15.0):
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
            return _WinPipe(self._path)
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
        self._conn.write(
            json.dumps({'command': cmd, 'request_id': rid}).encode() + b'\n')
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
