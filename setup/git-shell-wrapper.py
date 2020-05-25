#!/usr/bin/env python3
"""A thin wrapper around git-shell which updates the mirror before continuing

"""

import subprocess
import sys
import os


def get_repo_path():
    # sys.argv is in te format
    # ['-c', "git-receive-pack '/git-server/repos/test-delete-me.git'"]
    git_shell_args = sys.argv[-1]
    quoted_repo = git_shell_args.split()[-1]
    unquoted_repo = quoted_repo[1:-1]
    return unquoted_repo


if __name__ == "__main__":
    repo = get_repo_path()
    os.chdir(repo)
    subprocess.run(["git", "fetch"])
    subprocess.run(["/usr/bin/git-shell"] + sys.argv[1:])
