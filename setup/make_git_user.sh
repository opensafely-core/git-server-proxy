#!/bin/ash

# Notable adduser flags:
# -D avoids password generation
# -s changes user's shell
#
# '/usr/bin/git-shell' is a restricted login shell.
# It does all the heavy lifting when it comes to
# providing remote git service. For further info:
# https://git-scm.com/docs/git-shell

adduser -D -s /setup/git-shell-wrapper.py $1 && echo $1:12345 | chpasswd
addgroup $1 git

mkdir /git-server/$1-keys

# Initialize git home directories
cd /home/$1 && mkdir -p .ssh && \
        cp /dev/null .ssh/authorized_keys && \
        chmod -R 600 .ssh && chmod 700 .ssh && \
        chown -R $1:$1 .

# If this flag is set to “accept-new” then ssh will automatically add
# new host keys to the user known hosts files, but will not permit
# connections to hosts with changed host keys.
echo '
Host = github.com
StrictHostKeyChecking = accept-new
' > /home/$1/.ssh/config


echo '
[core]
        hooksPath = /git-server/hooks
[branch "master"]
        remote = origin
        merge = refs/heads/master
        pushRemote = origin
' > /home/$1/.gitconfig
