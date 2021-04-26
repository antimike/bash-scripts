#!/bin/env python3
# from BeautifulSoup import BeautifulSoup
from collections import namedtuple
# from subprocess import Popen, PIPE
# import asyncio, pexpect
import shlex, urllib
import os, sys
import doi, re
import requests, bs4

arxiv_re = re.compile("^(https://|//)?arxiv.org")
arxiv_extractor = re.compile("^(https://|//)?arxiv.org/abs/(.*)")
special_chars = {
    'ADD_FORALL': '+',
    'REMOVE_FORALL': '-',
    'ADD': '#',
    'REMOVE': '~',
    'ADD_GROUP': '*',
    'SET_ATTR': ':'
}

def debug(fn):
    def wrapped(*args, debug=False, **kwargs):
        if debug:
            print('*'*25, '\tENTERING {}'.format(fn.__name__))
            print('*'*25, '\tARGS: {}'.format(args), '\tKWARGS: {}'.format(kwargs))
            ret = fn(*args, **kwargs)
            print('*'*25, 'EXITING {}'.format(fn.__name__))
        else:
            ret = fn(*args, **kwargs)
        return ret
    return wrapped

Opts = namedtuple('Opts', ['tags', 'attrs'])
Opts.from_tags = lambda *tags: Opts(set(tags), {})
Opts.from_attrs = lambda **attrs: Opts(set(), attrs)

Operator = namedtuple('Operator', ['get_state', 'reducer', 'mods'])

class Func:
    @staticmethod
    def Print(*args, start=25*'-', end=25*'-'):
        print(start)
        for arg in args:
            print(arg)
        print(end)
        return args
    @staticmethod
    def Const(const, expect_spread=True):
        return Func(lambda *args: const)
    @staticmethod
    def Id(expect_spread=True):
        return Func(lambda *args: args, expect_spread=expect_spread)
    @staticmethod
    def _match_spread(internal, expect_spread=False, accept_spread=True):
        if not (expect_spread^accept_spread):
            return internal
        elif expect_spread:
            return lambda *args: internal(list(args))
        elif accept_spread:
            return lambda args: internal(*args)
    def print(self, start=25*'-', end=25*'-'):
        self.compose_left(Func.Print)
        return self
    def __init__(self, fn, accept_spread=True, expect_spread=True):
        # if expect_spread:
            # _fn = lambda 
        self._fns = [Func._match_spread(fn, accept_spread=accept_spread, expect_spread=False)]
        self._spread_args = expect_spread
    def _match_spread_right(self, f, accept_spread):
        return Func._match_spread(f, expect_spread=self._spread_args, accept_spread=accept_spread)
    def _match_spread_left(self, f, accept_spread):
        return Func._match_spread(f, expect_spread=False, accept_spread=accept_spread)
    def map_args(self, mp):
        return self.compose_right(lambda args: map(mp, *args), accept_spread=False)
    def compose_right(self, mp, accept_spread=True):
        self._fns.insert(0, self._match_spread_right(mp, accept_spread))
        return self
    def compose_left(self, mp, accept_spread=True, expect_spread=False):
        self._fns.append(Func._match_spread(mp, accept_spread=accept_spread, expect_spread=expect_spread))
        return self
    def parallel_with(self, *others):
        for other in others:
            other._spread_args = self._spread_args
        _others = [Func._match_spread(other, expect_spread=self._spread_args, accept_spread=other._spread_args)
                   for other in others]
        internal = lambda *args: list([self(*args), *[other(*args) for other in _others]])
        return Func(internal, accept_spread=self._spread_args, expect_spread=self._spread_args)
    def spread(self):
        self._spread_args = True
        return self
    def unspread(self):
        self._spread_args = False
        return self
    def iterate_over(self, generator, accept_spread=True, debug=False):
        if callable(generator):
            _g = Func._match_spread(
                generator, accept_spread=accept_spread, expect_spread=self._spread_args)
        else:
            _g = Func.Const(generator, expect_spread=self._spread_args)
        def wrapped(*args):
            ret = []
            items = _g(*args)
            if debug:
                Func.Print([], end='')
            while True:
                try:
                    ret.append(n := self(next(items)))
                    if debug:
                        Func.Print(n, start='', end='')
                except StopIteration:
                    break
            if debug:
                Func.Print([], end='')
            return ret
        return Func(wrapped, expect_spread=self._spread_args, accept_spread=self._spread_args)
    def __call__(self, *args):
        # initial = self._fns[0]
        # tail = self._fns[1:]
        if not self._spread_args:
            if len(args) > 1:
                raise Exception("Too many arguments provided")
        # args = initial(args)
        for f in self._fns:
            args = f(args)
        return args


test_opts = Opts({'boopy', 'shadoopy boo'}, {'title': 'awesomesauce'})
test_opts.tags
add_tags(test_opts, Opts.from_tags('gah'))
remove_tags(test_opts, Opts.from_tags('gah', 'shadoopy'))


split_tags = Func(str.split, expect_spread=True, accept_spread=True)\
    .compose_left(set, accept_spread=True, expect_spread=True)\
    .iterate_over(iter, accept_spread=True, debug=False)\
    .compose_left(set.union, accept_spread=True)

add_tags({1, 2, 3}, {2, 3, 4, 5})
add_tags = Func(set.update, accept_spread=True, expect_spread=True).print()\
    .compose_right(split_tags, accept_spread=True).print()\
    .map_args(lambda opts: opts.tags).print()
    # .map_args(Func.Print)
add_tags = Func(Func.Print).compose_left(add_tags)

split_tags._fns[0](['boo'])
split_tags._spread_args
args = ['boo']

# add_tags = Func(set.update).map_args(split_tags).map_args(lambda opts: opts.tags)
# remove_tags = Func(set.difference_update).map_args(lambda opts: opts.tags)
# add_attrs = Func(dict.update).map_args(lambda opts: opts.attrs)
# remove_attrs = Func(dict.pop
# remove_one_attr = Func(dict.pop).compose_right(lambda d, k: (d, k, None)).compose_right(lambda opts, k: (opts.attrs, k))
# remove_attrs = remove_one_attr.iterate_over(lambda old, new: ((old, k) for k in new.attrs.keys()))

test_opts.attrs
gen_fn = Func(lambda old, new: iter(new.attrs.keys()))
remove_attrs = remove_one_attr.compose_right()
td.keys().intersect(rem)

# tup = (test_opts, Opts.from_tag('blah'))
# list(map(lambda opts: opts.tags, tup))
# try_transform(lambda args: map(lambda opts: opts.tags, args), lambda arg: mp(arg))


operators = {
    '+': Operator(Opts.from_tag, lift(set.union)),
    '-': Operator()
}
special_chars_ = {
    '+': [apply_to_previous_doc(tags_adder), tags_adder],
    '-': [apply_to_previous_doc(tags_remover), tags_remover],
    '#': [apply_to_previous_doc(tags_adder)],
    '~': [apply_to_previous_doc(tags_remover)],
    ':': [apply_to_previous_doc(attr_adder(':')), attr_adder(':')],
    '^': [apply_to_previous_doc(attr_remover('^')), attr_remover('^')],
    '.': [apply_to_previous_doc(attr_adder)],
    '\\': [apply_to_previous_doc(attr_remover)]
}

ParsedArgs = namedtuple('ParsedArgs', ['docs', 'opts'])

def map_args(fn, inner=lambda arg: arg, outer=lambda ret: ret):
    def wrapped(*args, **kwargs):
        return outer(


def unitary_curry(fn):
    def wrapper(*args, **kwargs):
        return lambda arg: fn(arg, *args, **kwargs)
    return wrapper

def split_tags(fn):
    def wrapper(opts, *args, **kwargs):
        opts.tags = sum([list(map(str.strip, tag.split())) for tag in opts.tags], [])
        return fn(opts, *args, **kwargs)
    return wrapper

@unitary_curry
def apply_to_previous_doc(reducer, parsed):
    def wrapper(update, original):
        if len(parsed.docs) > 0:
            reducer(update, docs[-1].opts)
    return wrapper

@split_tags
def tags_adder(update, original):
    for tag in update.tags:
        if tag is None or len(tag) == 0:
            pass
        elif tag not in original.tags:
            original.tags.extend(tag)

@split_tags
def tags_remover(update, original):
    for tag in update.tags:
        if tag is None or len(tag) == 0:
            pass
        elif tag in original.tags:
            original.tags.remove(tag)

def attr_adder(update, original):
    original.attrs.update(update.attrs)

def attr_remover(update, original):
    for attr in update.attrs.keys():
        original.attrs.pop(attr, None)

def update_attrs(update, original):
    original.attrs.update(update.attrs)

# def split_tags(tags):
    # return [[word.strip() for word in tag.split()] for tag in tags]

def download_doi(doi_id):
    os.system('rm -rf {}'.format(PapisDoc.TMP_DIR))
    os.system('scidownl -D {} -o {}'.format(doi_id, PapisDoc.TMP_DIR))

def get_arxiv_id(url):
    try:
        return arxiv_extractor.match(url).group(2)
    except AttributeError:
        return None

class PapisDoc:
    TMP_DIR = '/tmp/paper/'
    def __init__(self, doc_type, doc_id, tags=[], **kwargs):
        if doc_type in ['arxiv', 'doi']:
            self.doc_type, self.doc_id = doc_type, doc_id
        else:
            raise ValueError
        self._tags = []
        self.add_tags(tags)
        self._attrs = {}
        self.add_attrs(kwargs)
        self._docs = []
    @property
    def opts(self):
        return Opts(self._tags, self._attrs)
    @property
    def attrs(self):
        return self._attrs
    @attrs.setter
    def add_attrs(self, attrs):
        self._attrs.update({k: v for k, v in attrs.items() if not
                            (k is None or v is None or len(k) == 0 or len(v) == 0)})
    @property
    def tags(self):
        return '"{}"'.format(' '.join(self._tags))
    def add_tags(self, tags):
        tags = split_tags(tags)
        for tag in tags:
            if tag is None or len(tag) == 0:
                pass
            elif tag not in self._tags:
                self._tags.extend(tag)
    def remove_tags(self, tags):
        tags = split_tags(tags)
        for tag in tags:
            if tag is None or len(tag) == 0:
                pass
            elif tag in self._tags:
                self._tags.remove(tag)
    def get_docs(self):
        if self.doc_type == 'doi':
            self._docs.extend(download_doi(self.doc_id))
    @property
    def papis_add_command(self):
        base = ' '.join(['papis add', *self._docs])
        doc_type = '--from {} {}'.format(self.doc_type, self.doc_id)
        set_tags = '--set tags {}'.format(self.tags)
        opts = ['--set {} {}'.format(k, v) for k, v in self._attrs.items()]
        return ' \\\n'.join([base, doc_type, set_tags, *opts])
    def add_to_library(self):
        os.system(self.papis_add_command)


args = sys.argv[1:]
# url = args.pop()

doi_ids, arxiv_ids, tags = {}, {}, []
# group = None
attrs = {'source_url': url}
docs = []
failed = []

# def apply_attr(key, attr):

def apply_tag(tag):
    def apply_previous_doc(action):
        if not len(docs):
            return
        elif 'ADD' in action:
            docs[-1].add_tags = [tag]
        elif 'REMOVE' in action:
            docs[-1].remove_tags = [tag]
    def apply_global(action):
        if 'ADD' in action:
            tags.append(tag)
        elif 'REMOVE' in action and tag in tags:
            tags.remove(tag)
        if 'GROUP' in action:
            attrs['group'] = tag
    actions = [k for k, v in special_chars.items() if v in tag]
    if 'SET_ATTR' in actions:
        docs[-1].add_attrs = {}
    for v in special_chars.values():
        tag = tag.replace(v, '')
    for action in actions:
        apply_previous_doc(action)
        apply_global(action)

for arg in args:
    if (doi_id := doi.find_doi_in_text(arg)) is not None:
        doc_type, doc_id = 'doi', doi_id
    elif (arxiv_url := arxiv_extractor.match(arg)) is not None:
        doc_type, doc_id = 'arxiv', arxiv_url.group(2)
    else:
        apply_tag(arg)

def try_transform(fn, transformation):
    def wrapped(*args):
        try:
            return fn(*args)
        except:
            return fn(transformation(args))
    return wrapped
def try_multiple(*fns):
    def wrapped(*args):
        success = False
        for fn in fns:
            try:
                ret = fn(*args)
                success = True
                break
            except:
                continue
        if success:
            return ret
        else:
            raise
    return wrapped


