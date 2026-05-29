#!/usr/bin/env python3
import obsws_python as obs
import os
import sys

def main():
    if len(sys.argv) < 2:
        print("Usage: obs_control.py [start|stop|toggle|status]")
        sys.exit(1)
        
    action = sys.argv[1]
    host = os.environ.get("OBS_API_HOST", "localhost")
    port = int(os.environ.get("OBS_API_PORT", 4455))
    password = os.environ.get("OBS_API_PASSWORD")

    try:
        cl = obs.ReqClient(host=host, port=port, password=password, timeout=3)
        if action == "start":
            cl.start_record()
            print("started")
        elif action == "stop":
            cl.stop_record()
            print("stopped")
        elif action == "toggle":
            status = cl.get_record_status()
            if status.output_active:
                cl.stop_record()
                print("stopped")
            else:
                cl.start_record()
                print("started")
        elif action == "status":
            status = cl.get_record_status()
            print("active" if status.output_active else "inactive")
    except Exception as e:
        print(f"inactive", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
