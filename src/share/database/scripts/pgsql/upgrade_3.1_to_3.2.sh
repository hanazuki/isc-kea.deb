#!/bin/sh

# Include utilities. Use installed version if available and
# use build version if it isn't.
if [ -e ${prefix}/share/kea/scripts/admin-utils.sh ]; then
    . ${prefix}/share/kea/scripts/admin-utils.sh
else
    . /home/wlodek/dev/kea/src/bin/admin/admin-utils.sh
fi

VERSION=`pgsql_version "$@"`

if [ "$VERSION" != "3.1" ]; then
    printf "This script upgrades 3.1 to 3.2. Reported version is $VERSION. Skipping upgrade.\n"
    exit 0
fi

psql "$@" >/dev/null <<EOF

START TRANSACTION;

-- Remove constraints which perform too restrictive checks on the inserted
-- host reservations. We want to be able to insert host reservations which
-- include no specific IPv4 address or those that have repeating subnet
-- identifiers, e.g. IPv4 reservations would typically include 0 (or null)
-- IPv6 subnet identifiers.
ALTER TABLE hosts DROP CONSTRAINT key_dhcp4_ipv4_address_subnet_id;
ALTER TABLE hosts DROP CONSTRAINT key_dhcp4_identifier_subnet_id;
ALTER TABLE hosts DROP CONSTRAINT key_dhcp6_identifier_subnet_id;

-- Create partial indexes instead of the constraints that we have removed.

-- IPv4 address/IPv4 subnet identifier pair is unique if subnet identifier is
-- not null and not 0.
CREATE UNIQUE INDEX hosts_dhcp4_ipv4_address_subnet_id ON hosts
       (ipv4_address ASC, dhcp4_subnet_id ASC)
    WHERE ipv4_address IS NOT NULL AND ipv4_address <> 0;

-- Client identifier is unique within an IPv4 subnet when subnet identifier is
-- not null and not 0.
CREATE UNIQUE INDEX hosts_dhcp4_identifier_subnet_id ON hosts
        (dhcp_identifier ASC, dhcp_identifier_type ASC, dhcp4_subnet_id ASC)
    WHERE (dhcp4_subnet_id IS NOT NULL AND dhcp4_subnet_id <> 0);

-- Client identifier is unique within an IPv6 subnet when subnet identifier is
-- not null and not 0.
CREATE UNIQUE INDEX hosts_dhcp6_identifier_subnet_id ON hosts
        (dhcp_identifier ASC, dhcp_identifier_type ASC, dhcp6_subnet_id ASC)
    WHERE (dhcp6_subnet_id IS NOT NULL AND dhcp6_subnet_id <> 0);

-- Set 3.2 schema version.
UPDATE schema_version
    SET version = '3', minor = '2';

-- Schema 3.2 specification ends here.

-- Commit the script transaction
COMMIT;

EOF

exit $RESULT

