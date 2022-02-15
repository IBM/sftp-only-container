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


store_host_key() {
  read -r keyname to loc other <<<$@

  [ -e /etc/ssh/ssh_host_${keyname}_key ] && \
    cp -p -f /etc/ssh/ssh_host_${keyname}_key* /home/.sshd/
}

load_host_key() {
  read -r keyname to loc other <<<$@

  [ -e /home/.sshd/ssh_host_${keyname}_key ] && \
    cp -p -n /home/.sshd/ssh_host_${keyname}_key* /etc/ssh/

}
#
#
#
store_host_keys() {
  keys="dsa rsa ecdsa ed25519"
  for key in $keys ; do
    store_host_key $key
  done
}

load_host_keys(){
  keys="dsa rsa ecdsa ed25519"
  for key in $keys ; do
    load_host_key $key
  done
}
