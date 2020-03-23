#!/bin/sh

# Copyright (C) 2019 Internet Systems Consortium, Inc. ("ISC")
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This script is primarily used for MySQL unit tests, which need to
# ensure an empty, but schema correct database for each test.  It
# deletes ALL transient data from an existing Kea MySQL schema,
# including leases, reservations, etc... Use at your own peril.
# Reference tables will be left in-tact.

prefix=/usr/local
# Include utilities. Use installed version if available and
# use build version if it isn't.
if [ -e ${prefix}/share/kea/scripts/admin-utils.sh ]; then
    . ${prefix}/share/kea/scripts/admin-utils.sh
else
    . /home/jenkins/workspace/kea-1.7/tarball-internal/kea/src/bin/admin/admin-utils.sh
fi

# First argument is must be the expected schema version <major>.<minor>
exp_version="$1"
shift;

# Remaining arguments are used as pgsql command line arguments

# If the existing schema doesn't match, the fail
VERSION=`pgsql_version "$@"`
if [ "$VERSION" = "" ]; then
    printf "Cannot wipe data, schema version could not be detected.\n"
    exit 1
fi

if [ "$VERSION" != "$exp_version" ]; then
    printf "Cannot wipe data, wrong schema version. Expected $exp_version, found version $VERSION.\n"
    exit 1
fi

# Delete transient data from tables.  We're using delete instead
# of truncate because it is much faster since our unit tests
# create very little data.
psql "$@" >/dev/null <<EOF
START TRANSACTION;
DELETE FROM hosts CASCADE;
DELETE FROM dhcp4_options;
DELETE FROM ipv6_reservations;
DELETE FROM dhcp6_options;
DELETE FROM lease4;
DELETE FROM lease4_stat;
DELETE FROM lease6;
DELETE FROM lease6_stat;
DELETE FROM logs;
COMMIT;
EOF

RESULT=$?

exit $RESULT
