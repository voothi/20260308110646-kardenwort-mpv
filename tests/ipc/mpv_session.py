import os, subprocess, time
from tests.ipc.mpv_ipc import MpvIpc, default_ipc_path


class MpvSession:
    def __init__(self, fixture, ipc_path=None):
        self.ipc_path = ipc_path or default_ipc_path()
        self.fixture = fixture
        self.ipc = MpvIpc(self.ipc_path)
        self._proc = None

    def start(self):
        import uuid
        self.ipc_path = f"{self.ipc_path}-{uuid.uuid4().hex[:8]}"
        self.ipc._path = self.ipc_path # Update the IPC client's path too
        
        cmd = [
            'mpv', '--no-config', '--vo=null', '--idle',
            f'--input-ipc-server={self.ipc_path}',
            '--script=scripts/lls_core.lua',
        ]
        # Log mpv output to help debug IPC connection issues
        log_path = os.path.join(os.getcwd(), 'tests', 'mpv_last_run.log')
        with open(log_path, 'w') as f:
            f.write(f"Running command: {' '.join(cmd)}\n\n")
        
        self._proc = subprocess.Popen(
            cmd,
            stdout=open(log_path, 'a'),
            stderr=subprocess.STDOUT
        )
        self.ipc.connect(timeout=15.0)
        self.ipc.command(['loadfile', self.fixture])
        # Wait a moment for the file to load
        time.sleep(0.5)

    def stop(self):
        try:
            self.ipc.command(['quit'], timeout=2.0)
        except Exception:
            pass
        if self._proc and self._proc.poll() is None:
            self._proc.terminate()
            self._proc.wait(timeout=5)
        self.ipc.close()
