Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
install-module PSWarranty
/* 
Set-WarrantyAPIKeys -DellClientID 'ClientID' -DellClientSecret 'Secret'
*/
$serialnumber = (Get-CimInstance win32_bios).serialnumber
$Warranty = ((Get-Warrantyinfo -DeviceSerial $serialnumber).enddate).tostring()
Ninja-Property-Set WarrantyStatus $Warranty
