import os, subprocess, time
from tests.ipc.mpv_ipc import MpvIpc, default_ipc_path
import uuid


class MpvSession:
    def __init__(self, video, subtitle=None, secondary_subtitle=None,
                 extra_args=None, ipc_path=None):
        self.video               = video
        self.subtitle            = subtitle
        self.secondary_subtitle  = secondary_subtitle
        self.extra_args          = extra_args or []
        self.ipc_path            = ipc_path or (default_ipc_path() + '-' + uuid.uuid4().hex[:8])
        self.ipc                 = MpvIpc(self.ipc_path)
        self._proc               = None

    def start(self):
        cmd = [
            'mpv', '--no-config', '--vo=null', '--ao=null', '--idle=once',
            f'--input-ipc-server={self.ipc_path}',
            '--script=scripts/lls_core.lua',
            self.video,
        ]
        if self.subtitle:
            cmd.append(f'--sub-file={os.path.abspath(self.subtitle)}')
        if self.secondary_subtitle:
            cmd.append(f'--sub-file={os.path.abspath(self.secondary_subtitle)}')
            cmd.append('--sid=1')
            cmd.append('--secondary-sid=2')
        cmd.extend(self.extra_args)

        log_path = os.path.join(os.getcwd(), 'tests', 'mpv_last_run.log')
        with open(log_path, 'w') as f:
            f.write(f"Running command: {' '.join(cmd)}\n\n")
        self._proc = subprocess.Popen(
            cmd,
            stdout=open(log_path, 'a'),
            stderr=subprocess.STDOUT,
        )
        self.ipc.connect(timeout=15.0)
        time.sleep(0.8)

    def stop(self):
        try:
            self.ipc.command(['quit'], timeout=2.0)
        except Exception:
            pass
        if self._proc and self._proc.poll() is None:
            self._proc.terminate()
            try:
                self._proc.wait(timeout=5)
            except Exception:
                pass
        self.ipc.close()
