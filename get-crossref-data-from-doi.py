#!/usr/bin/env python3
"""
A wrapper around the module 'crossrefapi'
Gets bibliographic information from Crossref's API for the passed list of DOIs
"""

from crossref.restful import Works
import sys
import doi
import json
import logging
import os
import time
from tempfile import mkstemp


logging.basicConfig(filename='{}/get-crossref-data.log'.format(os.environ['BASH_REPO']), encoding='utf-8', level=logging.DEBUG)

args = sys.argv[1:]
retrieved = []
works = Works()

def crossref_doi_query(args):
    totry = args
    master_start = time.time()
    logging.info('-'*80)
    logging.info("\t{}: Received arguments from stdin:".format(master_start))
    logging.info("\t\t{}".format(args))
    while any(args):
        try:
            next_doi, start = totry.pop(), time.time()
            logging.debug('Looking up {} on Crossref'.format(next_doi))
            retrieved = works.doi(next_doi)
            logging.debug('Found Crossref data for {} in time {}'.format(next_doi, time.time() - start))
            print(retrieved)
            yield retrieved
        except Exception:
            logging.warning('Exception thrown during Crossref lookup of {}'.format(next_doi))
        finally:
            logging.debug('Finished processing command-line args in total time {}; exiting generator function'.format(time.time() - master_start))

fd, path = mkstemp()
with open(path, 'w') as file:
    file.write(json.dumps([obj for obj in crossref_doi_query(sys.argv[1:])], sort_keys=True, indent=4))
os.close(fd)
print(path)

