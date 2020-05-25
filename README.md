# git-server-docker

A Docker image that provides a Git SSH proxy server for the OpenSAFELY
project, suitable for installing in a DMZ.

Clients must connect as either the `git-read-write` user, or the
`git-read-only` user.  Only the former is able to push. Whenever it
does so, any changes are forwarded onto its respective origin.

Repositories must be explicitly set up as mirrors by an administrator
(described below).

All git client operations are transparently preceded by the mirror
updating itself, so it always stays in sync with its origin.

The security benefits over simply allowing direct access to Github
(for example), are therefore:

1. Only users with a public key explicitly enabled by an adminstrator
   can access the git server

2. Only git repos which have been explicitly mirrored by an
   administrator can be pulled or pushed

3. Only users with a public key which has been explicity granted write
   permission can push to these repos

# Implementation

The docker image is built to have exactly two users with any shell
access. These are the `git-read-write` user and the `git-read-only`
user.

Their login shell is `git-shell-wrapper.py`. This is [a thin
wrapper](setup/git-shell-wrapper.py) around `git-shell` which is [the
restricted shell provided by git](https://git-scm.com/docs/git-shell)
for interactive with a server over ssh.  The wrapper ensures the
mirror is always up to date by running `git fetch` before every
command. This shell is not interactive.

Public keys are copied from `read-only-keys/` and `read-write-keys/`
to the respective users' `~/.ssh/authorized_keys` on container startup
(thus necessitating a restart when new keys are added).

Two git hooks are configured in each user's `~/.gitconfig`.  First,
the `pre-receive` hook, which is called before a `push` command is
executed. This refuses to continue unless the username is
`git-read-write`.

Second, the `post-receive` hook handles forwarding any successful
`push` onto the origin (in our case, usually Github).


# Usage

Create three directories: `read-only-keys/`, `read-write-keys/`, and
`repos/`.  These will not hold highly-sensitive information.

Edit `docker-compose.yml` so the `volumes` point to these locations
(i.e. change the part before each colon). The default is for them to
be subdirectories of the current directory when you start docker,
which you should do now:

    $ docker-compose up -d

This is now running, but without public keys set up, and no mirrored repos.

## Mirror a new repo

To set up a mirror of a new repo, clone it thus:

    $ git clone --mirror git@github.com:<org>/<repo>.git <repos_directory>/<repo>.git
    $ docker restart git-server

## Add public keys for git users


The public keys for users who should have read-only access should be
copied to the `read-only-keys/` directory,
and for users who should have read-write access should be copied to
the `read-write-keys/` directory.

In both cases the key should have a  `.pub` extension.

A user whose public key is in `read-write-keys` will also be forwarded
to Github on a successful push. This means that this user should also
have its public keys configured in Github, and this user will be the
user whose account is associated with pushed commits.

After new keys have been added to `read-only-keys/` or
`read-write-keys/`, the docker container should be restarted.

Example:

    curl https://github.com/sebbacon.keys > read-only-keys/sebbacon.pub
    docker restart git-server

## Use a mirror

Clone a repo from the mirror as the read-only user:

    $ git clone ssh://git-read-only@<git_server>:2222/git-server/repos/<repo>.git

This should fail, because it's using the read-only account:

    $ git push ssh://git-read-only@<git_server>:2222/git-server/repos/<repo>.git

But if you push as the read-write user, it succeeds, and changes are
forward into the mirrored repo:

    $ git push ssh://git-read-write@<git_server>:2222/git-server/repos/<repo>.git


# Acknowledgements

Originally based on [this repo](https://github.com/jkarlosb/git-server-docker)
