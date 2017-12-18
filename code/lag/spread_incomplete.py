#!/usr/bin/env python3
"""Add a second entry for incomplete games in a Retrosheet log

The new entry mirrors the original one except that the date and park
fields are adjusted and the second field (game id) is set to "I".

usage: spread_incomplete.py [FILE ...]
"""

import sys
import csv
import fileinput

outfh = csv.writer(sys.stdout)
for line in csv.reader(fileinput.input()):
    outfh.writerow(line)

    completion_info = line[13]
    if completion_info:
        date, park, *_ = completion_info.split(",")
        line[0] = date
        line[1] = "I"
        if park:
            line[16] = park
        outfh.writerow(line)
