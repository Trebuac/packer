# Install the downloaded VirtualBox guest additions

# Default path used by Packer ('packer' username defined in Autounattend.xml)
$isopath = "C:\Users\packer\VBoxGuestAdditions.iso"

Write-Output "Mounting disk image at $isopath"
Mount-DiskImage -ImagePath $isopath

Write-Output "Import certificates"
$certdir = ((Get-DiskImage -ImagePath $isopath | Get-Volume).Driveletter + ':\cert\')
$VBoxCertUtil = ($certdir + 'VBoxCertUtil.exe')
Get-ChildItem $certdir *.cer | ForEach-Object { & $VBoxCertUtil add-trusted-publisher $_.FullName --root $_.FullName }

Write-Output "Install Additions features"
$exe = ((Get-DiskImage -ImagePath $isopath | Get-Volume).Driveletter + ':\VBoxWindowsAdditions.exe')
$parameters = '/S'
Start-Process $exe $parameters -Wait
Write-Output "Features installed"

#Dismount the image and delete the original ISO
Write-Output "Dismounting disk image $isopath"
Dismount-DiskImage -ImagePath $isopath
Write-Output "Deleting $isopath"
Remove-Item $isopath