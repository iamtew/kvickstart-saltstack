#! /usr/bin/env bash
# -*- mode: shell; tab-width: 2; sublime-rulers: [100]; -*-

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
test "$(id -u)" != 0 && script_exit 1 "Not running as 'root'!"

# Installing both master and minion, but we wait with starting the daemons
curl -L https://bootstrap.saltstack.com -o bootstrap-salt.sh
sh bootstrap-salt.sh -M -X stable

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
echo "master: $(hostname -f)" > /etc/salt/minion.d/minion
hostname -f > /etc/salt/minion_id


cat << MASTER > /etc/salt/master.d/master
file_roots:
  base:
    - /srv/salt
    - /srv/formulas/salt-formula

pillar_roots:
  base:
    - /srv/pillar
MASTER

cat << TOP > /srv/salt/top.sls
base:
  '$(hostname -f)':
    - salt.master
    - salt.minion
TOP

cat << SALT > /srv/pillar/salt.sls
salt:
  master:
    worker_threads: 2
    fileserver_backend:
      - roots
    file_roots:
      base:
        - /srv/salt
        - /srv/formulas/salt-formula
    pillar_roots:
      base:
        - /srv/pillar
  minion:
    master: localhost
SALT

# Start our daemons
/sbin/service salt-master start
/sbin/service salt-minion start

# Sleep for a bit and accept the key
sleep 5
salt-key --accept="$(hostname -f)" --yes
