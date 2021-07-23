#!/bin/bash

echo -e "# Split SSH config\nSSH_VAULT_VM='keyvault-slave-private'\nif [ \"\$SSH_VAULT_VM\" != \"\" ]; then\n	export SSH_SOCK=~/.SSH_AGENT_\$SSH_VAULT_VM\n	rm -f \"\$SSH_SOCK\"\n	sudo -u user /bin/sh -c \"umask 177 && ncat -k -l -U '\$SSH_SOCK' -c 'qrexec-client-vm \$SSH_VAULT_VM qubes.SshAgent' &\"\nfi" | sudo tee -a /rw/config/rc.local
sudo chmod +x /rw/config/rc.local
