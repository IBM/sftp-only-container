#!/bin/bash
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
# We rely on having /run/pids available, as we will place the sshd pid file
# in there.
#
mkdir -p /run/pids/

source /bin/ssh-functions.sh

[ -z $DEBUG ] && DEBUG=0 || echo "Container: Debug level=${DEBUG}"

#
# This functions is called for every invocation of the container to re-construct
# the /etc/passwd and all users we need to have in there.
# This will create the group and user based on the following parameters:
# $1 ... is the username
# $2 ... is the uid
# $3 ... is the gid
#
# The password field will be set to '!locked', the ! will prevent from users
# using a password for login.
make_user() {
  IFS=" " read -r user uid gid <<< "$@"
  [ $DEBUG -ge 1 ] && echo "Container: DEBUG > make_user user=${user},uid=${uid},gid=${gid}"

  groupadd -g ${gid} ${user} 2>/dev/null
  useradd -m -u ${uid} -g ${gid} ${user} 2>/dev/null
  echo "${user}:!locked" | chpasswd -e
}

#
# This function orchestrates the recreation of all passwd entries for all users
# we need. The volume mounted on /home and the directory in there (with their
# uid:gid settings will describe which users to create)
#
init_users() {
  users=`ls /home/`
  for user in $users ; do
    if [ -d /home/${user} ]; then
      uid=`stat -c '%u' /home/${user}`
      gid=`stat -c '%g' /home/${user}`

      make_user ${user} ${uid} ${gid}

      if [ -d "/home/${user}/.groups.d" ]; then
        groups=`ls /home/${user}/.groups.d/`
        [ $DEBUG -ge 1 ] && echo "Container: DEBUG> user=${user} has this groups=(${groups})"

        for group in $groups ; do
          #TODO: Need to fix. What if a group does not exist.

          # To make sure we are not tricked into a group that the user
          # is not added to, we read it from the file
          grp=`stat -c '%G' /home/${user}/.groups.d/${group}`

          # gpasswd needs a silencer (>/dev/null) or writes a message
          # like "Adding xxx to group yyy"
          gpasswd -a ${user} ${grp} >/dev/null
        done
      fi
    fi
  done
}

#
# This functions modifies the sshd_config to support sftp only access in a chrooted
# environment.
#
set_config_sftp_only(){
    sed -i "s/Subsystem sftp    \/usr\/libexec\/openssh\/sftp-server/Subsystem sftp internal-sftp/g" /etc/ssh/sshd_config
    sed -i "s/#ChrootDirectory none/ChrootDirectory \/Volume\//g" /etc/ssh/sshd_config
    sed -i "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config
    sed -i "s/#AllowTcpForwarding yes/AllowTcpForwarding no/g" /etc/ssh/sshd_config
    echo "ForceCommand internal-sftp" >> /etc/ssh/sshd_config

    owner=`stat -c '%u' /Volume`
    if [ "${owner}" != "0" ]; then
      echo "Container: WARNING /Volume has not the proper ownership"
    fi

    owngrp=`stat -c '%g' /Volume`
    if [ "${owngrp}" != "0" ]; then
      echo "Container: WARNING /Volume has not the proper group ownership"
    fi

    perm=`stat -c '%a' /Volume`
    if [ "${perm}" != "755" ]; then
      echo "Container: WARNING /Volume has not the proper permission bits"
    fi
}

#
# Stop the SSHD Daemon
#
stop_ssh() {
  pid=`cat /run/pids/sshd.pid`
  echo "Container: stopping sshd pid=${pid}"
  kill -s TERM $pid
  wait $pid
}

#
# Start the SSHD Daemon
#
start_ssh() {
  echo "Container: starting ssh with command '$@'"
  $@ &
  pid=$!
  echo -n $pid >/run/pids/sshd.pid
  echo "Container: sshd (pid=${pid}) started..."
  wait ${pid}
  exit $?
}

#
# running the command
#

#
# First we need to recreate our /etc/passwd and all users that has to be in there
init_users

#
# If `-e SFTP_ONLY=yes` was specified we change the sshd_config to reflect that.
if [ "$SFTP_ONLY" == "yes" ]; then
  echo "Container: SFTP_ONLY is set to ${SFTP_ONLY}"
  set_config_sftp_only
fi

#
# We need to make sure we have ssh keys.
[ $DEBUG -ge 1 ] && echo "Container: DEBUG> checking host keys."
load_host_keys
if [ ! -e /etc/ssh/ssh_host_ed25519_key ]; then
  [ $DEBUG -ge 1 ] && echo "Container: DEBUG> generate host keys."
  /bin/ssh-keygen -A
  store_host_keys
fi

#
# Now let us figure out what the container is suppose to do today.
if [ "$1" == "help" ]; then
  echo "HELP:"
  echo ""
  echo "supported commands:"
  echo "sshd or nothing ... start sshd daemon"
  echo "containeradm ...... add or delete users, add keys, ..."
  echo "show-config ... show the sshd config file"
elif [ "`basename $1`" == "sshd" ];then
  trap stop_ssh SIGTERM SIGINT

  start_ssh $@
elif [ "$1" == "containeradm" ]; then
  shift
  /bin/containeradm $@
elif [ "$1" == "show-config" ]; then
  cat /etc/ssh/sshd_config
else
  [ "$SFTP_ONLY" == "yes" ] && {
    echo "Container runs in SFTP only mode. Command access restricted."
    echo "use 'containeradm' command to manage."
  } || {
     exec $@
  }

fi
