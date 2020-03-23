#!/bin/sh

prefix=/usr/local
# Include utilities. Use installed version if available and
# use build version if it isn't.
if [ -e ${prefix}/share/kea/scripts/admin-utils.sh ]; then
    . ${prefix}/share/kea/scripts/admin-utils.sh
else
    . /home/jenkins/workspace/kea-1.7/tarball-internal/kea/src/bin/admin/admin-utils.sh
fi

VERSION=`pgsql_version "$@"`

if [ "$VERSION" != "5.0" ]; then
    printf "This script upgrades 5.0 to 5.1. Reported version is $VERSION. Skipping upgrade.\n"
    exit 0
fi

psql "$@" >/dev/null <<EOF

START TRANSACTION;

-- Put the auth key in hexadecimal (double size but far more user friendly).
ALTER TABLE hosts ALTER COLUMN auth_key TYPE VARCHAR(32);

-- Set 5.1 schema version.
UPDATE schema_version
    SET version = '5', minor = '1';

-- Schema 5.1a specification ends here.

-- Commit the script transaction
COMMIT;

EOF

exit $RESULT

