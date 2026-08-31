#!/usr/bin/env python3
"""
tag-stdioe.py - real-time I:/O:/E: tagging for a CLI command's stdin, stdout, and stderr streams.
"""

import subprocess
import sys
import select

def tag_line(prefix: str, line: str) -> str:
    """prefix a tag (I:/O:/E:) to the line"""
    return f"{prefix}: {line}"

def main():
    if len(sys.argv) < 2:
        print("Usage: tag-stdioe.py <command> [args...]", file=sys.stderr)
        sys.exit(1)

    cmd = " ".join(sys.argv[1:])

    print(f"Running: {cmd}", file=sys.stderr)

    proc = subprocess.Popen(
        cmd,
        shell=True,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=0,
        universal_newlines=True
    )

    rlist = [sys.stdin, proc.stdout, proc.stderr]

    while rlist:
        readable, _, _ = select.select(rlist, [], [], 0.5)

        for fd in readable[:]:
            line = fd.readline()

            if not line:  # EOF
                if fd is sys.stdin and proc.stdin:
                    proc.stdin.close()
                rlist.remove(fd)
                continue

            # match statement
            match fd:
                case sys.stdin:
                    prefix = "I"
                case proc.stdout:
                    prefix = "O"
                case proc.stderr:
                    prefix = "E"
                case _:
                    prefix = "?"

            print(tag_line(prefix, line), end="")

        if proc.poll() is not None and not readable:
            break

    # process trailing output from stdout and stderr
    while True:
        line = proc.stdout.readline()
        if not line:
            break
        print(tag_line("O", line), end="")

    while True:
        line = proc.stderr.readline()
        if not line:
            break
        print(tag_line("E", line), end="")

    return_code = proc.wait()
    print(f"Finished with exit code: {return_code}", file=sys.stderr)

if __name__ == "__main__":
    main()
