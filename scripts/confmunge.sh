#!/bin/bash -e
# Copyright (C) 2018  Cumulus Networks, Inc
# Quentin Young
#
# This script automatically converts FRR configuration files to work around the
# issue of static routes being absorbed into vrf config blocks that have an
# implicit exit.
#
# Ex:
# ---
#   vrf blue
#      ip route 1.2.3.4/22 192.168.0.1
#   !
#   ip route 1.2.3.4/22 blackhole
#
# In the above configuration, the blackhole static is part of the vrf context
# block because indentation has no semantic meaning for FRR under normal
# circumstances.
#
# As shipped in the 'frr' package in Cumulus Linux 3.6.2.

FRRCONF=/etc/frr/frr.conf
FRRCONFBAK=/etc/frr/frr.conf.deb_bak
if grep -q '^ip route ' $FRRCONF && grep -q '^vrf ' $FRRCONF; then
  echo "Modifying your frr.conf file to support static route commands inside vrf context blocks."
  echo "A copy of your original $FRRCONF will be saved at $FRRCONFBAK."
  cat $FRRCONF > $FRRCONFBAK
  MUNGED=`mktemp`
  echo "Reading from $FRRCONF"
  echo "Writing to $MUNGED"
  mawk 'match($0, /^ip route .*/) { statics[FNR] = substr($0, RSTART, RLENGTH); next }
        match($0, /^vrf .*/) {
                if (!vrfline)
                        vrfline = FNR;
        }
	{ others[FNR] = $0 }
        END {
                for (i = 0; i <= NR; i++) {
                        if (others[i])
                                print others[i]
                        if (i == vrfline - 1) {
                                for (j in statics) {
                                        print statics[j];
                                }
                        }
                }
        }' $FRRCONF > $MUNGED
  echo "Moving $MUNGED to $FRRCONF"
  mv $MUNGED $FRRCONF
fi
