# This script is intended to be run in a TEMPLATE or STANDALONE VM
# in order to setup Split-SSH in client VMs.
#!/bin/bash

if [ -f /etc/fedora-release ] 
then
# For Fedora (RPM) systems
sudo dnf install openssh-askpass nmap-ncat -y
elif [ -f /etc/debian_version ]
then
# For Debian-based systems
sudo apt-get install nmap-netcat ssh-askpass -y
fi

echo -e "#!/bin/sh\n# Qubes Split SSH script\n# For template VMs\nnotify-send \"[\`qubesdb-read /name\`] SSH agent access from: \$QREXEC_REMOTE_DOMAIN\"\nncat -U \$SSH_AUTH_SOCK" | sudo tee /etc/qubes-rpc/qubes.SshAgent
