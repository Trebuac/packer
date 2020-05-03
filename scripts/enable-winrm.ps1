# basic config for winrm
winrm quickconfig -q

# allow unencrypted traffic, and configure auth to use basic username/password auth
winrm s "winrm/config/service" '@{AllowUnencrypted="true"}'
winrm s "winrm/config/service/auth" '@{Basic="true"}'

# update firewall rules to open the right port and to allow remote administration (add rules instead of enabling the existing as group and name properties depends of the locale)
netsh advfirewall firewall add rule profile=any name="Allow WinRM HTTP" dir=in localport=5985 protocol=TCP action=allow
netsh advfirewall firewall add rule profile=any name="Allow WinRM HTTPS" dir=in localport=5986 protocol=TCP action=allow

# Set service  and restart winrm
Restart-Service winrm
