#! /bin/sh
# Copyright (C) 2008-2012 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Make sure the suggested 'distcleancheck_listfiles' in the manual works.
# The example Makefile.am we use is from the FAQ entry 'distcleancheck'.

required=cc
. ./defs || Exit 1

cat >>configure.ac << 'END'
AC_PROG_CC
AC_OUTPUT
END

cat > Makefile.am << 'END'
# This Makefile.am is bogus.  See @node{distcleancheck} in the manual
# for how to fix it properly.
bin_PROGRAMS = foo
foo_SOURCES = foo.c
dist_man_MANS = foo.1

# We write './foo.1' inside the rule on purpose, to avoid VPATH rewriting
# done by some 'make' implementations.
foo.1: foo$(EXEEXT)
	echo man page for foo$(EXEEXT) > ./foo.1

## Ignore warnings about overridden variables
AUTOMAKE_OPTIONS = -Wno-override
distcleancheck_listfiles = \
  find . -type f -exec sh -c 'test -f $(srcdir)/$$1 || echo $$1' \
       sh '{}' ';'
END

cat >foo.c <<'END'
int main () { return 0; }
END

$ACLOCAL
$AUTOCONF
$AUTOMAKE

./configure
$MAKE
$MAKE distcheck

# Now ensure that we really needed the override.
sed '/distcleancheck_listfiles/,$d' Makefile.am > t
mv -f t Makefile.am
$AUTOMAKE
./configure
$MAKE
$MAKE distcheck 2>stderr && { cat srderr >&2; Exit 1; }
cat stderr >&2

grep 'ERROR:.*files left in build directory after distclean' stderr
grep '^\./foo\.1$' stderr

: