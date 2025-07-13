#! /usr/bin/python3
# -*- python -*-
# -*- coding: utf-8 -*-
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2007 Red Hat, Inc.
#

from six.moves import range


def hexbitmask(l, nr_entries):
    hexbitmask = []
    bit = 0
    mask = 0
    for entry in range(nr_entries):
        if entry in l:
            mask |= (1 << bit)
        bit += 1
        if bit == 32:
            bit = 0
            hexbitmask.insert(0, mask)
            mask = 0

    if bit < 32 and mask != 0:
        hexbitmask.insert(0, mask)

    return hexbitmask

def bitmasklist(line, nr_entries):
    hexmask = line.strip().replace(",", "")
    bitmasklist = []
    entry = 0
    bitmask = bin(int(hexmask, 16))[2::]
    for i in reversed(bitmask):
        if int(i) & 1:
            bitmasklist.append(entry)
        entry += 1
        if entry == nr_entries:
            break
    return bitmasklist
