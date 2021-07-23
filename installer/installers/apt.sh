INFO="`apt show "${NAME}" | yq e '.Type = "apt"' -`"
INSTALL="'sudo apt-get install "${NAME}" -y'"
