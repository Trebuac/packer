# Install the attached VirtualBox guest additions

# Default drive letter used by Packer when mounting the VBoxWindowsAdditions iso
$driveLetter = "F"

Write-Output "Import certificates"
$certdir = ($driveLetter + ':\cert\')
$VBoxCertUtil = ($certdir + 'VBoxCertUtil.exe')
Get-ChildItem $certdir *.cer | ForEach-Object { & $VBoxCertUtil add-trusted-publisher $_.FullName --root $_.FullName }

Write-Output "Install Additions features"
$exe = ($driveLetter + ':\VBoxWindowsAdditions.exe')
$parameters = '/S'
Start-Process $exe $parameters -Wait
Write-Output "Features installed..."