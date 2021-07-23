#!/usr/bin/env python3

import json
import subprocess as sp
import os

file = open('/home/user/.dotfiles/repos.json')
repos = json.load(file)
for repo in repos.values():
    os.chdir(repo)
    gitprocess = sp.Popen(['git', 'pull'],
                          stdout=sp.PIPE,
                          stdin=sp.PIPE,
                          stderr=sp.PIPE)
    stdout, stderr = gitprocess.communicate()

bashprocess = sp.Popen(repos['Bash'] + '/setup.sh',
                        stdout=sp.PIPE,
                        stderr=sp.PIPE)
stdout, stderr = bashprocess.communicate()
