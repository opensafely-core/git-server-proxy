FROM alpine:3.11.6

RUN apk add --no-cache \
  openssh \
  git \
  python3

# Generate the server's public/private key pair.
RUN ssh-keygen -A
RUN mkdir /git-server/

RUN mkdir /root/.ssh

COPY setup /setup
WORKDIR /setup

# This config allows SSH access to github via port 443
RUN cp /setup/ssh-config /root/.ssh/config
RUN chmod -R 700 /root/.ssh/

RUN ls -l make_git_user.sh
# Set up two users.  The ability of `git-read-only` to push is
# suppressed by git hooks
RUN addgroup git
RUN ./make_git_user.sh git-read-write
RUN ./make_git_user.sh git-read-only

# Set up hooks. These (a) prevent `git-read-only` from pushing; (b)
# forward successful pushes onto github
RUN git config --global core.hooksPath /setup/hooks

# The sshd_config file has been edited as follows:
# 1. enable authorization via public/private key pairs
# 2. disable authorization via password
COPY setup/sshd_config /etc/ssh/sshd_config

# The start script handles first-time setup,
# and launches the SSH server.
COPY start.sh start.sh

# SSH port:
EXPOSE 22

CMD ["sh", "start.sh"]
