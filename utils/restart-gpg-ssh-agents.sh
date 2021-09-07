#!/bin/bash
# Restarts gpg-agent and sets SSH_AUTH_SOCK to allow SSH auth with GPG creds stored in smartcard

export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpg-connect-agent updatestartuptty /bye

exit $?
