#!/usr/bin/env python3
#
# Converts zlog_err() to zlog_ferr(), generating the error definitions file as
# it goes.
#
# Usage:
#    convferr.py <source directory>
import re
import glob
import os

header = """/*
 * {0}-specific error messages.
 * Copyright (C) 2018  Cumulus Networks, Inc.
 *                     {1}
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; see the file COPYING; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include <zebra.h>
"""

def process_file(f, dfilec, dfileh, dname):
    with open(f, "r") as src:
        def repl(am):
            print("Processing: {}\n\n".format(am.group(0)))
            newcode = input('New code (Y/n):')
            ecode = ''

            if len(newcode) > 0 and newcode.lower()[0] == 'n':
                refcode = input('Use existing code: ')
                ecode = dname.upper() + '_ERR_' + refcode
            else:
                refcode = input('Error suffix: ')
                reftitl = input('Error title: ')
                refdesc = input('Error description: ')
                refsugg = input('Suggestion: ')

                ecode = dname.upper() + '_ERR_' + refcode
                dfileh.write('\t{},\n'.format(ecode))
                dfilec.write('\t{{\n\t\t.code = {},\n\t\t.title = "{}",\n\t\t.description = "{}",\n\t\t.suggestion = "{}",\n\t}},\n'.format(ecode, reftitl, refdesc, refsugg))
                dfileh.flush()
                dfilec.flush()

            replaced_zerr = re.sub('zlog_err\(', 'zlog_ferr\({}, '.format(ecode), am.group(0))
            print("Replacing zerr call with: {}".format(replaced_zerr))
            return replaced_zerr

        pattern = re.compile('zlog_err\([^;]*\);', re.MULTILINE | re.DOTALL)
        outfile = re.sub(pattern, repl, src.read())

    with open(f, "w") as src:
        src.write(outfile)


if __name__ == '__main__':
    print("Please enter the following information.")
    uname = input("Real name: ")
    dname = input("Daemon name: ")
    fname = input("Destination file basename (e.g. bgp_errors): ")

    dfilec = open(fname + '.c', 'w')
    dfileh = open(fname + '.h', 'w')

    header = header.format(dname, uname)

    dfileh.write(header)
    dfilec.write(header)

    dfileh.write('#ifndef __{0}_H__\n#define __{0}_H__\n\n'.format(fname))
    dfileh.write('#include "ferr.h"\n\n')
    dfileh.write('enum {}_ferr_refs {{\n'.format(dname.lower()))

    dfilec.write('#include "{}.h"\n#include "ferr.h"\n\n'.format(fname))
    dfilec.write('static struct ferr_ref ferr_{}_err[] = {{\n'.format(dname.lower()))

    for f in glob.glob('*.c'):
        print("Processing {}".format(f))
        s = input("Skip? (y/N): ")
        if len(s) > 0 and s[0] == 'y':
            continue

        try:
            process_file(f, dfilec, dfileh, dname)
        except KeyboardInterrupt:
            break

    dfilec.write('};\n\n')
    bs = """
void {0}_error_init(void)
{{
	ferr_ref_init();

	ferr_ref_add(ferr_{0}_err);
}}
""".format(dname.lower())
    dfilec.write(bs)
    dfilec.close()
    dfileh.write('}};\n\nextern void {}_error_init(void);\n'.format(dname.lower()))
    dfileh.close()


