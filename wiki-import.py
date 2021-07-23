#!/bin/env python3
# from BeautifulSoup import BeautifulSoup
from collections import namedtuple
from functools import wraps
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
    def Print(wrapped_fn=None, start=25*'-', end=25*'-', info=None):
        info = info or wrapped_fn.__name__
        def wrapper(*args):
            print(start)
            if info is not None:
                print(info)
            for arg in args:
                print(arg)
            print(end)
            return args
        ret = Func(wrapper)
        return ret if not callable(wrapped_fn) else ret.compose_left(Func.unspread(wrapped_fn))
    @staticmethod
    def Const(const):
        return Func(lambda arg: const)
    @staticmethod
    def Id():
        return Func(lambda arg: arg)
    @staticmethod
    def wrap_take_first(fn):
        return Func(Func.take_first(Func.take_first(fn)))
    @staticmethod
    def take_first(fn):
        @wraps(fn)
        def wrapped(it):
            return fn(list(it)[0]) if any(it) else f()
        return wrapped
    @staticmethod
    def wrap_unspread(fn):
        return Func(Func.unspread(Func.unspread(fn)))
    @staticmethod
    def unspread(fn):
        @wraps(fn)
        def wrapped(arg):
            return fn(*arg)
        return wrapped
    def print(self, start=25*'-', end=25*'-'):
        self.compose_left(Func.Print(start, end)).compose_right(Func.Print(start, end))
        return self
    def __init__(self, fn):
        self._fns = [fn]
    def map_args(self, mp, eval=True):
        ret = self.compose_right(lambda args: map(mp, args))
        return ret.compose_left(list) if eval else ret
    def compose_right(self, mp):
        self._fns.insert(0, mp)
        return self
    def compose_left(self, mp):
        self._fns.append(mp)
        return self
    def parallel_with(self, *others):
        return Func(lambda *args: [self(*args), *[other(*args) for other in others]])
    def spread(self):
        self.compose_right(Func.Id())
        return self
    def gather(self):
        return Func.unspread(self)
    def iterate_over(self, generator):
        if not callable(generator):
            generator = Func.Const(generator)
        @wraps(self)
        def wrapped(args):
            ret = []
            items = generator(args)
            while True:
                try:
                    ret.append(self(next(items)))
                except StopIteration:
                    break
            return ret
        return Func(wrapped)
    def __call__(self, *args):
        for f in self._fns:
            args = f(args)
        return args


split_tags('a b c')
split_tags(test_tags)
list(Func.unspread(iter)([test_tags]))
split_tags = Func(Func.unspread(str.split)).compose_left(set)\
    .iterate_over(Func.unspread(iter)).compose_left(Func.unspread(set.union))

add_tags = Func(Func.unspread(Func.Print(wrapped_fn=set.update, info='Set update:')))\
    .map_args(Func.Print(wrapped_fn=split_tags, info='Split tags:'), eval=False)\
    .map_args(Func.Print(wrapped_fn=lambda opts: opts.tags, info='Project opts:').gather(), eval=False)

Func.wrap_unspread(set.update).print().map_args(split_tags).print()(test_tags, test_update)

test_tags = {'a', 'b c', 'd e f'}
test_update = {'g h', 'i'}
test_opts = Opts({'boopy', 'shadoopy boo'}, {'title': 'awesomesauce'})
test_opts.tags
add_tags(test_opts, Opts.from_tags('yay!'))
add_tags(test_tags, {1, 2, 3})
add_tags._fns

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


