# -*- coding: utf-8 -*-
# completers.py - custom argument completers module for fedpkg
#
# Copyright (C) 2019 Red Hat Inc.
# Author(s): Ondrej Nosek <onosek@redhat.com>,
#            Dominik Rumian <drumian@redhat.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.  See http://www.gnu.org/copyleft/gpl.html for
# the full text of the license.

from argcomplete.completers import ChoicesCompleter


class CustomCompleterWrapper(object):
    """
    Class that allows passing additional arguments to custom completer methods.
    Completer methods should provide ChoicesCompleter (or other similar object
    from 'argcomplete.completers' class) as their results.
    """
    def __init__(self, method, *args, **kwargs):
        self.method = method
        self.args = args
        self.kwargs = kwargs

    def fetch_completer(self):
        return self.method(*self.args, **self.kwargs)


def distgit_namespaces(cli):
    if cli.config.has_option(cli.name, 'distgit_namespaces'):
        return ChoicesCompleter(cli.config.get(cli.name, 'distgit_namespaces').split())
    else:
        return None
