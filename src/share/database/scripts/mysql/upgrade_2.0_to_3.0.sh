#!/bin/sh

# Include utilities. Use installed version if available and
# use build version if it isn't.
if [ -e ${prefix}/share/kea/scripts/admin-utils.sh ]; then
    . ${prefix}/share/kea/scripts/admin-utils.sh
else
    . /home/wlodek/dev/kea_rel_1.4/src/bin/admin/admin-utils.sh
fi

VERSION=`mysql_version "$@"`

if [ "$VERSION" != "2.0" ]; then
    printf "This script upgrades 2.0 to 3.0. Reported version is $VERSION. Skipping upgrade.\n"
    exit 0
fi

mysql "$@" <<EOF
CREATE TABLE IF NOT EXISTS hosts (
host_id INT UNSIGNED NOT NULL AUTO_INCREMENT ,
dhcp_identifier VARBINARY(128) NOT NULL ,
dhcp_identifier_type TINYINT NOT NULL ,
dhcp4_subnet_id INT UNSIGNED NULL ,
dhcp6_subnet_id INT UNSIGNED NULL ,
ipv4_address INT UNSIGNED NULL ,
hostname VARCHAR(255) NULL ,
dhcp4_client_classes VARCHAR(255) NULL ,
dhcp6_client_classes VARCHAR(255) NULL ,
PRIMARY KEY (host_id) ,
INDEX key_dhcp4_identifier_subnet_id (dhcp_identifier ASC, dhcp_identifier_type ASC) ,
INDEX key_dhcp6_identifier_subnet_id (dhcp_identifier ASC, dhcp_identifier_type ASC, dhcp6_subnet_id ASC) 
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS ipv6_reservations (
reservation_id INT NOT NULL AUTO_INCREMENT ,
address VARCHAR(39) NOT NULL ,
prefix_len TINYINT(3) UNSIGNED NOT NULL DEFAULT 128 ,
type TINYINT(4) UNSIGNED NOT NULL DEFAULT 0 ,
dhcp6_iaid INT UNSIGNED NULL ,
host_id INT UNSIGNED NOT NULL ,
PRIMARY KEY (reservation_id) ,
INDEX fk_ipv6_reservations_host_idx (host_id ASC) ,
CONSTRAINT fk_ipv6_reservations_Host
FOREIGN KEY (host_id )
REFERENCES hosts (host_id )
ON DELETE NO ACTION
ON UPDATE NO ACTION
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS dhcp4_options (
option_id INT UNSIGNED NOT NULL AUTO_INCREMENT ,
code TINYINT UNSIGNED NOT NULL ,
value BLOB NULL ,
formatted_value TEXT NULL ,
space VARCHAR(128) NULL ,
persistent TINYINT(1) NOT NULL DEFAULT 0 ,
dhcp_client_class VARCHAR(128) NULL ,
dhcp4_subnet_id INT NULL ,
host_id INT UNSIGNED NULL ,
PRIMARY KEY (option_id) ,
UNIQUE INDEX option_id_UNIQUE (option_id ASC) ,
INDEX fk_options_host1_idx (host_id ASC) ,
CONSTRAINT fk_options_host1
FOREIGN KEY (host_id )
REFERENCES hosts (host_id )
ON DELETE NO ACTION
ON UPDATE NO ACTION
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS dhcp6_options (
option_id INT UNSIGNED NOT NULL AUTO_INCREMENT ,
code INT UNSIGNED NOT NULL ,
value BLOB NULL ,
formatted_value TEXT NULL ,
space VARCHAR(128) NULL ,
persistent TINYINT(1) NOT NULL DEFAULT 0 ,
dhcp_client_class VARCHAR(128) NULL ,
dhcp6_subnet_id INT NULL ,
host_id INT UNSIGNED NULL ,
PRIMARY KEY (option_id) ,
UNIQUE INDEX option_id_UNIQUE (option_id ASC) ,
INDEX fk_options_host1_idx (host_id ASC) ,
CONSTRAINT fk_options_host10
FOREIGN KEY (host_id )
REFERENCES hosts (host_id )
ON DELETE NO ACTION
ON UPDATE NO ACTION
) ENGINE = INNODB;

DELIMITER $$
CREATE TRIGGER host_BDEL BEFORE DELETE ON hosts FOR EACH ROW
-- Edit trigger body code below this line. Do not edit lines above this one
BEGIN
DELETE FROM ipv6_reservations WHERE ipv6_reservations.host_id = OLD.host_id;
END
$$
DELIMITER ;

UPDATE schema_version SET version='3', minor='0';
EOF

RESULT=$?

exit $?
