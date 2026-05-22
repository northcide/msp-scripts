#file to download
#Url can be OneDrive, or Dropbox but you have to ensure its a direct download link
$DownloadURL = "https://dl.google.com/tag/s/appguid%3D%7B65E60E95-0DE9-43FF-9F3F-4F7D2DFF04B5%7D%26iid%3D%7B65E60E95-0DE9-43FF-9F3F-4F7D2DFF04B5%7D%26lang%3Den%26browser%3D4%26usagestats%3D1%26appname%3DGoogle%2520Earth%2520Pro%26needsadmin%3DTrue%26brand%3DGGGE/earth/client/GoogleEarthProSetup.exe"
#location to save on the computer. Path must exist or it will error
$DownloadPath = "c:\temp\googleearthprowin-7.3.6-x64.exe"
#arguments for the silent install only on is used depending on if you are installing an MSI or an EXE
#for MSI only edit the end section of the variable
$ArgumentsMSI ='/I ' + '"' + $DownloadPath + '" ' + 'OMAHA=1'
$ArgumentsEXE ='OMAHA=1'
#set to 'true' for MSI and 'false' for exe
$MSI = 'false'
#Log File Path
$LogPath = 'c:\temp\PSInstallLog.txt'

$tempfolder = Get-Item -Path "C:\temp"

If($tempfolder)
{}
Else
{New-Item -Path "C:\temp" -ItemType "directory"}

#Start Logging to a Text File
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $LogPath

#downloads the file from the URL
Invoke-WebRequest -Uri $DownloadURL -OutFile $DownloadPath

if($MSI -eq 'true')
{
	#Install MSI
	Write-Host $ArgumentsMSI
        write-host "Starting Install"
	Start-Process -FilePath "msiexec.exe" -Wait -ArgumentList $ArgumentsMSI
    
}
else
{
	#Install EXE
	Write-Host $ArgumentsEXE
	Start-Process -FilePath $DownloadPath -Wait -ArgumentList $ArgumentsEXE
}

#Stop Logging
Stop-Transcript

exit 0
