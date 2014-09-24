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

# First and only input will be treated as a master server hostname
test $# != 1 && script_exit 1 "Need a master server as input!" || OPT_MASTER=$1

# Installing both master and minion, but we wait with starting the daemons
curl -o install_salt.sh -L https://bootstrap.saltstack.com
sh install_salt.sh -A "$OPT_MASTER" -X $SALT_VERSION

