#!/bin/sh

# Copyright (C) 2014-2020 Internet Systems Consortium, Inc. ("ISC")
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This script replaces /usr/local, ${prefix}/var and other automake/autoconf
# variables with their actual content.
#
# Invocation:
#
# ./path_replacer.sh input-file.in output-file
#
# This script is initially used to generate configuration files, but it is
# generic and can be used to generate any text files.

# shellcheck disable=SC2034
# SC2034: ... appears unused. Verify use (or export if used externally).

# Exit with error if commands exit with non-zero and if undefined variables are
# used.
set -eu

prefix="/usr/local"
sysconfdir="${prefix}/etc"
localstatedir="${prefix}/var"
exec_prefix="${prefix}"
libdir="${exec_prefix}/lib"

echo "Replacing \@prefix\@ with ${prefix}"
echo "Replacing \@libdir\@ with ${libdir}"
echo "Replacing \@sysconfdir\@ with ${sysconfdir}"
echo "Replacing \@localstatedir\@ with ${localstatedir}"

echo "Input file: $1"
echo "Output file: $2"

sed -e "s+\@libdir\@+${libdir}+g; s+\@localstatedir\@+${localstatedir}+g; s+\@prefix\@+${prefix}+g; s+\@sysconfdir\@+${sysconfdir}+g" "${1}" > "${2}"
