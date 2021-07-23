#!/bin/env python3

import doi
import sys

if doi.validate_doi(to_check := sys.argv[1]) is None:
    to_check = doi.find_doi_in_text(to_check)
if to_check is not None:
    print("'{}'".format(to_check))
else:
    raise Exception("No DOI was found in the passed string")
