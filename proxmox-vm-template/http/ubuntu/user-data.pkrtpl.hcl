#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  storage:
    layout:
      name: direct
  identity:
    hostname: ubuntu-2604
    username: ${ssh_username}
    password: "$6$YmGKQ3k4NkV8n/od$5qsXm9kfH19AzvLo7jl52iphx13p88Pawyunjf6agcCXGA.qJOo5J9Leop1Ggd/OsIVCGhPZFYVE2xp4hzpow0"
  ssh:
    install-server: true
    allow-pw: true
    authorized-keys:
      - "${ssh_public_key}"
  packages:
    - qemu-guest-agent
  late-commands:
    - "echo '${ssh_username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${ssh_username}"
    - "chmod 440 /target/etc/sudoers.d/${ssh_username}"
  shutdown: reboot
