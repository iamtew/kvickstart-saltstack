#! /usr/bin/env bash
# -*- mode: shell; tab-width: 2; sublime-rulers: [100]; -*-

SALT_VERSION='git v2014.7.0rc2'

set -o nounset # disallow usage of unset variables
set -o errexit # exit on errors

# Exit the script, requires first argument to be the exit code, and then you can pass a string that
# will be shown to the user.
script_exit ()
{
	local retval=$1
	shift 1
	echo "Exiting: $*"
	exit "$retval"
}
trap script_exit SIGTERM

# As we're installing packages and changing system settings let's require root permissions
test "$UID" != 0 && script_exit 1 "Not running as 'root'!"

# Installing both master and minion, but we wait with starting the daemons
curl -o install_salt.sh -L https://bootstrap.saltstack.com
sh install_salt.sh -M -X -P $SALT_VERSION

# We need git, so let's install it
yum -y install git

# Create some directories we need
mkdir -p /etc/salt/{master,minion}.d
mkdir -p /srv/saltstack/{salt,pillar,formulas}


# Download the 'Salting the Salt Master' formula
pushd /srv/saltstack/formulas
git clone https://github.com/saltstack-formulas/salt-formula
popd


# Let's create some basic configuration to allow the formula to do the rest
echo "master: $HOSTNAME" > /etc/salt/minion
hostname -f > /etc/salt/minion_id


cat << MASTER > /etc/salt/master
file_roots:
  base:
    - /srv/saltstack/salt
    - /srv/saltstack/formulas/salt-formula

pillar_roots:
  base:
    - /srv/saltstack/pillar
MASTER

cat << TOP > /srv/saltstack/salt/top.sls
base:
  '$HOSTNAME':
    - salt.master
    - salt.minion
TOP

cat << SALT > /srv/saltstack/pillar/salt.sls
salt:
  master:
    worker_threads: 2
    fileserver_backend:
      - roots
    file_roots:
      base:
        - /srv/saltstack/salt
        - /srv/saltstack/formulas/salt-formula
    pillar_roots:
      base:
        - /srv/saltstack/pillar
  minion:
    master: localhost
SALT

# Start our daemons
/sbin/service salt-master start
/sbin/service salt-minion start

# Sleep for a bit and accept the key
sleep 5
salt-key --accept="$HOSTNAME" --yes
