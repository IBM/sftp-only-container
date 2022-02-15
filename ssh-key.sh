#!/bin/bash
# THIS IS TO BE RUN AS USER *** NOT AS ROOT
#
# Under Apache 2.0 License see LICENSE file.
#
# Copyright IBM 2021,2022
# SPDX-License-Identifier: Apache2.0
#
# Authors:
#  - Thomas Weinzettl <thomasw@ae.ibm.com>
#
#===============================================================================

#
# The ssh directory must exist and has to have permissions
# u:rwx g:--- o:--- aka 700
#
fix_ssh_dir() {
  # this helps us to capture othersuff someone could send over what we do not
  # want to pass to chmod.
  IFS=" " read -r sshdir otherstuff <<<"$@"

  if [ ! -d $sshdir ]; then
    mkdir -p $sshdir
  fi

  chmod 700 $sshdir
}

#
# Add a public ssh key to the authorized_keys file, but only if it is a real
# key file.
add_key() {
  # key needs to capture all the rest. In this case it is save, as we stuff it
  # into a temp keyfile and check it with ssh-keygen -lf, so garbage keys
  # won't pass the test.
  IFS=" " read -r sshdir key <<<"$@"

  [ $DEBUG -gt 1 ] \
    && echo "ssh-key ($USER) DEBUG: add_key dir=${sshdir} key=${key:0:24}"

  fix_ssh_dir $sshdir

  # We want a temp keyfile, just to check if the key we got passed over is
  # acutally a ssh public key.
  keyfile=`mktemp /tmp/keyfile.XXXXXXXX`
  echo "$key" >>$keyfile

  # -lf will verify the keys and hash them. It will come back with none-0
  # return code if the key is not valid.
  ssh-keygen -lf $keyfile >/dev/null 2>&1 || {
    echo "ERROR: add_key ${key:0:24}... is not a valid public ssh key."
    rm $keyfile
    exit 1
  }

  authorized_keys=${sshdir}/authorized_keys
  # if the keyfile is there we make it writable for short.
  [ -e $authorized_keys ] && chmod 600 $authorized_keys
  # let us not trust the temp file, as someone could have written to it. We
  # take the key that we have written into the temp file.
  echo ${key} >> $authorized_keys
  chmod 644 $keyfile
  rm $keyfile

  # lets make the keyfile read-only again
  chmod 400 $authorized_keys
  echo "added key to user $USER"
}

#
# List all the keys for the current user.
list_keys(){
  # we make sure we do not pass othergarbage to ssh-keygen
  IFS=" " read -r sshdir othergarbage <<<"$@"

  [ $DEBUG -ge 1 ] && echo "DEBUG: list_keys dir=${sshdir} "

  fix_ssh_dir $sshdir
  authorized_keys=${sshdir}/authorized_keys
  [ -e $authorized_keys ] \
    && ssh-keygen -lf $authorized_keys \
    || echo "No keys found."
}

#
# We will not allow to run this as root, so that no-one introduces a ssh
# key to a root user.
effective_user=`id -u`
if [ "${effective_user}" -le 0 ]; then
  echo "$0 : please run as user"
  echo "$0 : Current user is root, this is not permited."
  exit 1
fi

#
# Here comes the main program ...
function=$1
shift

if [ -z $function ]; then
  echo "usage: ssh-key.sh [command]"
  echo " "
  echo "add .... add a key to a user"
  echo "list ... list the keys of a user"
elif [ "$function" == "add" ]; then
  add_key $HOME/.ssh "$@"
elif [ "$function" == "list" ]; then
  list_keys $HOME/.ssh
fi
