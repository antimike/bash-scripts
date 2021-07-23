#!/usr/bin/env bash

qubes-gpg-client -d ~/.calcurse/caldav/calcurse_config.gpg > ~/.calcurse/caldav/config
calcurse-caldav --init=two-way
calcurse-caldav --init=two-way --authcode '4/0AY0e-g5QfQQzSLR-aaU_iRgkvxG4f4MzZYXX3cw3yfK56Xp9nE9Uex1Dn5Kh-zLhVa-hdw'
calcurse-caldav
calcurse-caldav --init=two-way --authcode '4/0AY0e-g4-knyXVF_3jglZDG1ob5F7k1tgjLRbImTFbXXGNk4NYcyYxSTO7Tak3VRfBd7SkA'
rm ~/.calcurse/caldav/oauth2_cred
rm ~/.calcurse/caldav/config

