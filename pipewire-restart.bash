#!/bin/bash
# Unfucks pipewire / ALSA on Fedora 34 Macbook Pro

systemctl --user restart pipewire pipewire-pulse
systemctl --user daemon-reload
