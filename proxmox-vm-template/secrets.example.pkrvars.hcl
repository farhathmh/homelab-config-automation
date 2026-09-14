# Proxmox VE API Endpoint
proxmox_api_url = "https://10.10.10.10:8006/api2/json"

# Proxmox API Token ID (format: user@realm!tokenid)
proxmox_api_token_id = "packer@pve!packer-token"

# Proxmox API Token Secret
proxmox_api_token_secret = "00000000-0000-0000-0000-000000000000"

# Target Proxmox node name
proxmox_node = "pve1"

# Serial port socket for terminal monitoring via 'qm terminal <vmid>' (set false on main/prod if disabled)
enable_serial_console = true

