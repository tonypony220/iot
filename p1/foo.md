# Optionally set your team logins
export TEAM_LOGIN1=alice
export TEAM_LOGIN2=bob

# Optionally set which public key to install
export SSH_PUB_KEY=~/.ssh/id_ed25519.pub   # if you use ed25519

vagrant up          # brings both VMs up in order (server first, then agent)

