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

    def _check_and_kill_mpv_instances(self):
        """Check for and kill any running mpv instances before starting a new test session."""
        try:
            # Use tasklist on Windows to find mpv processes
            result = subprocess.run(
                ['tasklist', '/FI', 'IMAGENAME eq mpv.exe', '/FO', 'CSV'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            # Parse the output to find PIDs
            mpv_pids = []
            for line in result.stdout.split('\n'):
                if 'mpv.exe' in line.lower():
                    parts = line.split(',')
                    if len(parts) >= 2:
                        try:
                            pid = int(parts[1].strip('"'))
                            mpv_pids.append(pid)
                        except ValueError:
                            pass
            
            if mpv_pids:
                print(f"Found {len(mpv_pids)} running mpv instance(s), killing them...")
                for pid in mpv_pids:
                    try:
                        subprocess.run(['taskkill', '/F', '/PID', str(pid)],
                                     capture_output=True, timeout=5)
                        print(f"  Killed mpv process (PID: {pid})")
                    except subprocess.TimeoutExpired:
                        print(f"  Failed to kill mpv process (PID: {pid}): timeout")
                    except Exception as e:
                        print(f"  Failed to kill mpv process (PID: {pid}): {e}")
                # Give processes time to terminate
                time.sleep(0.5)
        except Exception as e:
            print(f"Warning: Failed to check for mpv instances: {e}")

    def start(self):
        # Check for and kill any running mpv instances before starting
        self._check_and_kill_mpv_instances()
        
        cmd = [
            'mpv', '--no-config', '--config-dir=.', '--vo=null', '--ao=null', '--idle=once',
            f'--input-ipc-server={self.ipc_path}',
            '--script=scripts/kardenwort',
            self.video,
        ]
        if self.subtitle:
            cmd.append(f'--sub-file={os.path.abspath(self.subtitle)}')
        if self.secondary_subtitle:
            cmd.append(f'--sub-file={os.path.abspath(self.secondary_subtitle)}')
            cmd.append('--sid=1')
            cmd.append('--secondary-sid=2')
        cmd.extend(self.extra_args)

        log_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'tests', 'mpv_last_run.log')
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




