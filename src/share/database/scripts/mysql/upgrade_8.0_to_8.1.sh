#!/bin/sh

prefix=/usr/local
# Include utilities. Use installed version if available and
# use build version if it isn't.
if [ -e ${prefix}/share/kea/scripts/admin-utils.sh ]; then
    . ${prefix}/share/kea/scripts/admin-utils.sh
else
    . /home/jenkins/workspace/kea-1.7/tarball-internal/kea/src/bin/admin/admin-utils.sh
fi

VERSION=`mysql_version "$@"`

if [ "$VERSION" != "8.0" ]; then
    printf "This script upgrades 8.0 to 8.1. Reported version is $VERSION. Skipping upgrade.\n"
    exit 0
fi

mysql "$@" <<EOF

# Add lifetime bounds
ALTER TABLE dhcp4_shared_network
    ADD COLUMN min_valid_lifetime INT(10) DEFAULT NULL,
    ADD COLUMN max_valid_lifetime INT(10) DEFAULT NULL;

ALTER TABLE dhcp4_subnet
    ADD COLUMN min_valid_lifetime INT(10) DEFAULT NULL,
    ADD COLUMN max_valid_lifetime INT(10) DEFAULT NULL;

ALTER TABLE dhcp6_shared_network
    ADD COLUMN min_preferred_lifetime INT(10) DEFAULT NULL,
    ADD COLUMN max_preferred_lifetime INT(10) DEFAULT NULL,
    ADD COLUMN min_valid_lifetime INT(10) DEFAULT NULL,
    ADD COLUMN max_valid_lifetime INT(10) DEFAULT NULL;

ALTER TABLE dhcp6_subnet
    ADD COLUMN min_preferred_lifetime INT(10) DEFAULT NULL,
    ADD COLUMN max_preferred_lifetime INT(10) DEFAULT NULL,
    ADD COLUMN min_valid_lifetime INT(10) DEFAULT NULL,
    ADD COLUMN max_valid_lifetime INT(10) DEFAULT NULL;

# Create dhcp4_server insert trigger
DELIMITER $$
CREATE TRIGGER dhcp4_server_AINS AFTER INSERT ON dhcp4_server
    FOR EACH ROW
    BEGIN
        CALL createAuditEntryDHCP4('dhcp4_server', NEW.id, "create");
    END $$
DELIMITER ;

# Create dhcp4_server update trigger
DELIMITER $$
CREATE TRIGGER dhcp4_server_AUPD AFTER UPDATE ON dhcp4_server
    FOR EACH ROW
    BEGIN
        CALL createAuditEntryDHCP4('dhcp4_server', NEW.id, "update");
    END $$
DELIMITER ;

# Create dhcp4_server delete trigger
DELIMITER $$
CREATE TRIGGER dhcp4_server_ADEL AFTER DELETE ON dhcp4_server
    FOR EACH ROW
    BEGIN
        CALL createAuditEntryDHCP4('dhcp4_server', OLD.id, "delete");
    END $$
DELIMITER ;

# Create dhcp6_server insert trigger
DELIMITER $$
CREATE TRIGGER dhcp6_server_AINS AFTER INSERT ON dhcp6_server
    FOR EACH ROW
    BEGIN
        CALL createAuditEntryDHCP6('dhcp6_server', NEW.id, "create");
    END $$
DELIMITER ;

# Create dhcp6_server update trigger
DELIMITER $$
CREATE TRIGGER dhcp6_server_AUPD AFTER UPDATE ON dhcp6_server
    FOR EACH ROW
    BEGIN
        CALL createAuditEntryDHCP6('dhcp6_server', NEW.id, "update");
    END $$
DELIMITER ;

# Create dhcp6_server delete trigger
DELIMITER $$
CREATE TRIGGER dhcp6_server_ADEL AFTER DELETE ON dhcp6_server
    FOR EACH ROW
    BEGIN
        CALL createAuditEntryDHCP6('dhcp6_server', OLD.id, "delete");
    END $$
DELIMITER ;

# Put the auth key in hexadecimal (double size but far more user friendly).
ALTER TABLE hosts
    MODIFY COLUMN auth_key VARCHAR(32) NULL;

# Update the schema version number
UPDATE schema_version
SET version = '8', minor = '1';

# This line concludes database upgrade to version 8.1.

EOF

RESULT=$?

exit $?
