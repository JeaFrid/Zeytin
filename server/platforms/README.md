## Zeytin Platform-Specific Installers

### Debian/Ubuntu
```bash
wget -qO install.sh https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/install.sh && sudo bash install.sh
```

### Fedora/RHEL/CentOS
```bash
wget -qO install.sh https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/platforms/install_fedora.sh && sudo bash install.sh
```

### Arch Linux
```bash
wget -qO install.sh https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/platforms/install_arch.sh && sudo bash install.sh
```

### macOS
```bash
curl -fsSL https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/platforms/install_macos.sh | bash
```

### Windows (PowerShell as Administrator)
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/platforms/install_windows.ps1" -OutFile "install.ps1"; .\install.ps1
```
