import os, subprocess
from tests.ipc.mpv_ipc import MpvIpc, default_ipc_path


class MpvSession:
    def __init__(self, fixture, ipc_path=None):
        self.ipc_path = ipc_path or default_ipc_path()
        self.fixture = fixture
        self.ipc = MpvIpc(self.ipc_path)
        self._proc = None

    def start(self):
        cmd = [
            'mpv', '--no-config', '--vo=null', '--no-terminal', '--idle=once',
            f'--input-ipc-server={self.ipc_path}',
            '--script=scripts/lls_core.lua',
            self.fixture,
        ]
        self._proc = subprocess.Popen(cmd)
        self.ipc.connect(timeout=5.0)

    def stop(self):
        try:
            self.ipc.command(['quit'], timeout=2.0)
        except Exception:
            pass
        if self._proc and self._proc.poll() is None:
            self._proc.terminate()
            self._proc.wait(timeout=5)
        self.ipc.close()
