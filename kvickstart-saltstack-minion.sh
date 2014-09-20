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

# First and only input will be treated as a master server hostname
test $# != 1 && script_exit 1 "Need a master server as input!" || master=$1

# Installing both master and minion, but we wait with starting the daemons
curl -L https://bootstrap.saltstack.com -o bootstrap-salt.sh
sh bootstrap-salt.sh -M -X stable

# Let's create some basic configuration to allow the formula to do the rest
echo "master: $master" > /etc/salt/minion
hostname -f > /etc/salt/minion_id
