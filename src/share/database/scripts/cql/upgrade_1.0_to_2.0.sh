#!/bin/sh

prefix=/usr/local
# Include utilities. Use installed version if available and
# use build version if it isn't.
if [ -e ${prefix}/share/kea/scripts/admin-utils.sh ]; then
    . ${prefix}/share/kea/scripts/admin-utils.sh
else
    . /home/jenkins/workspace/kea-1.7/tarball-internal/kea/src/bin/admin/admin-utils.sh
fi

version=$(cql_version "$@")

if [ "${version}" != "1.0" ]; then
    printf "This script upgrades 1.0 to 2.0. Reported version is %s. Skipping upgrade.\n" "${version}"
    exit 0
fi

cqlsh "$@" <<EOF
-- This line starts database upgrade to version 2.0

-- -----------------------------------------------------
-- Table \`host_reservations\`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS host_reservations (
    id BIGINT,
    host_identifier BLOB,
    host_identifier_type INT,
    host_ipv4_subnet_id INT,
    host_ipv6_subnet_id INT,
    host_ipv4_address INT,
    host_ipv4_next_server INT,
    host_ipv4_server_hostname VARCHAR,
    host_ipv4_boot_file_name VARCHAR,
    hostname VARCHAR,
    user_context VARCHAR,
    host_ipv4_client_classes VARCHAR,
    host_ipv6_client_classes VARCHAR,
    -- reservation
    reserved_ipv6_prefix_address VARCHAR,
    reserved_ipv6_prefix_length INT,
    reserved_ipv6_prefix_address_type INT,
    iaid INT,
    -- option
    option_universe INT,
    option_code INT,
    option_value BLOB,
    option_formatted_value VARCHAR,
    option_space VARCHAR,
    option_is_persistent BOOLEAN,
    option_client_class VARCHAR,
    option_subnet_id INT,
    option_user_context VARCHAR,
    option_scope_id INT,
    PRIMARY KEY ((id))
);

CREATE INDEX IF NOT EXISTS host_reservationsindex1 ON host_reservations (host_identifier);
CREATE INDEX IF NOT EXISTS host_reservationsindex2 ON host_reservations (host_identifier_type);
CREATE INDEX IF NOT EXISTS host_reservationsindex3 ON host_reservations (host_ipv4_subnet_id);
CREATE INDEX IF NOT EXISTS host_reservationsindex4 ON host_reservations (host_ipv6_subnet_id);
CREATE INDEX IF NOT EXISTS host_reservationsindex5 ON host_reservations (host_ipv4_address);
CREATE INDEX IF NOT EXISTS host_reservationsindex6 ON host_reservations (reserved_ipv6_prefix_address);
CREATE INDEX IF NOT EXISTS host_reservationsindex7 ON host_reservations (reserved_ipv6_prefix_length);

-- -----------------------------------------------------
-- Table \`host_identifier_type\`
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS host_identifier_type (
    type INT,
    name VARCHAR,
    PRIMARY KEY ((type))
);

-- Insert currently defined type names.
INSERT INTO host_identifier_type (type, name) VALUES (0, 'hw-address');
INSERT INTO host_identifier_type (type, name) VALUES (1, 'duid');
INSERT INTO host_identifier_type (type, name) VALUES (2, 'circuit-id');
INSERT INTO host_identifier_type (type, name) VALUES (3, 'client-id');
INSERT INTO host_identifier_type (type, name) VALUES (4, 'flex-id');

-- -----------------------------------------------------
-- Table \`dhcp_option_scope\`
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS dhcp_option_scope (
    scope_id INT,
    scope_name VARCHAR,
    PRIMARY KEY ((scope_id))
);

INSERT INTO dhcp_option_scope (scope_id, scope_name) VALUES (0, 'global');
INSERT INTO dhcp_option_scope (scope_id, scope_name) VALUES (1, 'subnet');
INSERT INTO dhcp_option_scope (scope_id, scope_name) VALUES (2, 'client-class');
INSERT INTO dhcp_option_scope (scope_id, scope_name) VALUES (3, 'host');

DELETE FROM schema_version WHERE version=1;
INSERT INTO schema_version (version, minor) VALUES(2, 0);

-- This line concludes database upgrade to version 2.0
EOF

exit $?
