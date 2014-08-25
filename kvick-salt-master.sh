#! /usr/bin/env bash

# Installing both master and minion, but we wait with starting the daemons
curl -L https://bootstrap.saltstack.com -o bootstrap-salt.sh
sh bootstrap-salt.sh -M -X stable

# We need git, so let's install it
yum -y install git

# Create some directories we need
mkdir -p /srv/{salt,pillar,formulas}


# Download the 'Salting the Salt Master' formula
pushd /srv/formulas
git clone https://github.com/saltstack-formulas/salt-formula
popd


# Let's create some basic configuration to allow the formula to do the rest
cat << MINION > /etc/salt/minion
master: 127.0.0.1
MINION

cat << MASTER > /etc/salt/master
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
    - salt.minon
TOP


# Start our daemons
/sbin/service salt-master start
/sbin/service salt-minion start

