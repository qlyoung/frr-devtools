#!/usr/bin/env python3
#
# Copyright (C) 2018  Quentin Young
#
# Convert FRR error codes to CSV
import sys
import json
import pprint

rz = sys.stdin.read().split("\n\n")
jz = [ json.loads(x) for x in rz[:-1] ]

mine = {}

# deduplicate
for el in jz:
    for key in el:
        mine[key] = el[key]

# convert to csv
for el in mine:
    print('Error,{},High,{},{},{}'.format(el, mine[el]['title'].replace(',', ' '), mine[el]['description'].replace(',', ' '), mine[el]['suggestion'].replace(',', ' ')))
