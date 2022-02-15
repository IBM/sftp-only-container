<!-- This should be the location of the title of the repository, normally the short name -->
# sftp-only-container

<!-- Build Status, is a great thing to have at the top of your repository, it shows that you take your CI/CD as first class citizens -->
<!-- [![Build Status](https://travis-ci.org/jjasghar/ibm-cloud-cli.svg?branch=master)](https://travis-ci.org/jjasghar/ibm-cloud-cli) -->

<!-- Not always needed, but a scope helps the user understand in a short sentance like below, why this repo exists -->
## Scope

container files and shell scripts for the IBM Developer tutorial sftp-only
container for IBM zCX (or any other appliance-like container runtime).

*TODO* add link to public site, once published.

## Usage - Start the container

### Requirements

- IBM Z Container Extension (zCX) or other remote container runtime (docker or podman) e.g. podman machines on MacOS
- volume for `/home` to contain _authorized_keys_ for ssh public key
authentication
- volume for `/Volume` to host the hub of container volumes to mount onto

### Start the container

Here is an example to start the container. The `dummy_volume` is an example of
how to add another container volume to the sftp_only container.

```
$ docker run --name sftp-only --hostname sftp-only --rm -d -p 2022:22 \
-v sftp-home:/home -v sftp-volume:/Volume -v dummy_volume:/Volume/dummy \
-e SFTP_ONLY=yes thomasw/sftp-only:latest
```

| Environment Variable | Values | description |
| --- | --- | --- |
| SFTP_ONLY | yes / **no** | **Default:** no <br/>Set to _yes_ if the container should restrict the access to sftp, and change the root to `/Volume` |
| DEBUG | **0** numeric | **Default:** 0 (for no output) <br/> 1 or higher is more verbose |

## Usage User Administration

This can be done on the running container with `docker exec` or on the `/home`
volume while stopped.

```
$ docker exec sftp-only containeradm
...
```

or

```
$ docker run --rm -v sftp-home:/home thomasw/sftp-only:latest containeradm
...
```

To get started you need to add a user and add his ssh public key like this:

```
$ docker exec sftp-only containeradm user add username
User username was added.
$ docker exec sftp-only containeradm key add \
"username:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHe4Aqe5RbyC1d7Zco+EI9Q4VUvtwcLEHHURK02pe+B test-key"
added key to user username
$
```

Here is a list of the most important commands:

| Task | Command |
| --- | --- |
| Add a user | `... containeradm user add username` or <br />`... containeradm user add username:1000:1000` |
| Delete a user | `... containeradm user del username` |
| List users | `... containeradm user list` |
| Add user to a group | `... containeradm user addgrp username groupname` |
| Remove user from a group | `... containeradm user rmgrp username groupname` |
| Add ssh public key | `... containeradm key "username:ssh-ed25119 AAAA...."` |
| List keys | `... containeradm key list username` |
| Dump the ssh config | `... containeradm showconfig` |
| Regenerate the hostkeys | `... containeradm hostkey refresh`

## License

The Dockerfiles and associated shell scripts are licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0.html)

All source files must include a Copyright and License header. The SPDX license header is  preferred because it can be easily scanned.

If you would like to see the detailed LICENSE click [here](LICENSE).

```text
#
# Copyright 2020- IBM Inc. All rights reserved
# SPDX-License-Identifier: Apache2.0
#
```

[issues]: https://github.com/IBM/sftp-only-container/issues/new
