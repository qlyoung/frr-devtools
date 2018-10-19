#!/usr/bin/env python3
#
# Copyright (C) 2018  Quentin Young
#
# Generates route map entries for scale testing FRR
#
from sys import argv
from math import log, ceil
import random
import string

gen = int(argv[1])
places = ceil(log(gen, 24)) + 4
shit = set(
    ["".join(random.choices(string.ascii_lowercase, k=places)) for i in range(0, gen)]
)
shit = map(lambda x: "route-map {} permit 5".format(x), shit)
for turd in shit:
    print(turd)
