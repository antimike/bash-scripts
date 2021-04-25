#!/bin/env python3
# from BeautifulSoup import BeautifulSoup
import sys, doi, requests, re, bs4, urllib

arxiv_re = "^(https://|//)?arxiv.org"
arxiv_extractor = "^(https://|//)?arxiv.org/abs/(.*)"

args = sys.argv[1:]

url = sys.argv[1]
def scrape_url_for_refs(url):
    page = requests.get(url)
    parsed_page = bs4.BeautifulSoup(page.content)
    links = parsed_page.findAll('a', attrs={'href': re.compile('')})
    doi_ids_from_url = [doi_id for link in links
               if (doi_id := doi.find_doi_in_text(link.get('href'))) is not None]
    arxiv_ids_from_url = [urllib.parse.unquote(arxiv_url.match(2)) for link in links
                 if (arxiv_url := re.match(arxiv_extractor, link)) is not None]
