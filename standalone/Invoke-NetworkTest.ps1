Add-Type -AssemblyName PresentationFramework

function Test-Ping {
    param ([string]$Target)
    Test-Connection -ComputerName $Target -Count 1 -Quiet
}

function Get-Gateway {
    if ($env:OS -eq "Windows_NT") {
        (Get-NetRoute -DestinationPrefix 0.0.0.0/0).NextHop
    } else {
        (netstat -rn | Select-String 'default' | ForEach-Object { $_.ToString().Split() })
    }
}

function Get-PublicIP {
    try {
        (Invoke-RestMethod -Uri "http://ipinfo.io/ip").Trim()
    } catch {
        "Unable to retrieve public IP"
    }
}

Function Get-WiFiSignalStrength{

(netsh wlan show interfaces) -Match '^\s+Signal' -Replace '^\s+Signal\s+:\s+',''

}

Function Get-WiFiSSID{

$SSID = [string](netsh wlan show interface | sls “\sSSID”) | sls “\:.+”| %{$_.Matches.Value}

$SSID.TrimStart(": ")

}


function Get-ComputerInfo {
    @{
        UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        ComputerName = $env:COMPUTERNAME
        SerialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
        IPv4Addresses = (Get-NetIPAddress -AddressFamily IPv4).IPAddress -join ", "
        DnsServers = (Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses -join ", "
        SSID = Get-WiFiSSID
        WiFiSignalStrength = Get-WiFiSignalStrength
        PublicIP = Get-PublicIP
    }
}

function Show-Results {
    param (
        [string]$GoogleStatus,
        [string]$DnsStatus,
        [array]$GatewayStatuses,
        [hashtable]$ComputerInfo
    )
    $window = New-Object System.Windows.Window
    $window.Title = "Network Test"
    $window.SizeToContent = "WidthAndHeight"
    $window.WindowStartupLocation = "CenterScreen"
    $window.Padding = "10"

    $stackPanel = New-Object System.Windows.Controls.StackPanel

    $infoText = New-Object System.Windows.Controls.TextBlock
    $infoText.Text = "Currently logged on user: $($ComputerInfo.UserName)`nComputer Name: $($ComputerInfo.ComputerName)`nComputer Serial Number: $($ComputerInfo.SerialNumber)`nIPv4 Addresses: $($ComputerInfo.IPv4Addresses)`nIPv4 DNS Servers: $($ComputerInfo.DnsServers)`nWiFi SSID: $($ComputerInfo.SSID)`nWiFi Signal Strength: $($ComputerInfo.WiFiSignalStrength)`nPublic IP: $($ComputerInfo.PublicIP)`n"
    $infoText.FontWeight = "Bold"
    $stackPanel.Children.Add($infoText)

    $googleText = New-Object System.Windows.Controls.TextBlock
    $googleText.Text = "Ping to google.com was $GoogleStatus."
    $googleText.FontWeight = "Bold"
    $googleText.Foreground = if ($GoogleStatus -eq "successful") { "Green" } else { "Red" }
    $stackPanel.Children.Add($googleText)

    $dnsText = New-Object System.Windows.Controls.TextBlock
    $dnsText.Text = "Ping to 8.8.8.8 was $DnsStatus."
    $dnsText.FontWeight = "Bold"
    $dnsText.Foreground = if ($DnsStatus -eq "successful") { "Green" } else { "Red" }
    $stackPanel.Children.Add($dnsText)

    foreach ($gatewayStatus in $GatewayStatuses) {
        $gatewayText = New-Object System.Windows.Controls.TextBlock
        $gatewayText.Text = "Ping to gateway ($($gatewayStatus.Gateway)) was $($gatewayStatus.Status)."
        $gatewayText.FontWeight = "Bold"
        $gatewayText.Foreground = if ($gatewayStatus.Status -eq "successful") { "Green" } else { "Red" }
        $stackPanel.Children.Add($gatewayText)
    }

    $copyButton = New-Object System.Windows.Controls.Button
    $copyButton.Content = "Copy to Clipboard"
    $copyButton.Margin = "10"
    $copyButton.Add_Click({
        $textToCopy = $infoText.Text + "`n" + $googleText.Text + "`n" + $dnsText.Text + "`n" + ($gatewayStatuses | ForEach-Object { "Ping to gateway ($($_.Gateway)) was $($_.Status)." }) -join "`n"
        [System.Windows.Clipboard]::SetText($textToCopy)
        [System.Windows.MessageBox]::Show("Text copied to clipboard.")
    })
    $stackPanel.Children.Add($copyButton)

    $window.Content = $stackPanel
    $window.ShowDialog() | Out-Null
}

$google = "google.com"
$dns = "8.8.8.8"
$gateways = Get-Gateway
$computerInfo = Get-ComputerInfo

$googleStatus = if (Test-Ping -Target $google) { "successful" } else { "unsuccessful" }
$dnsStatus = if (Test-Ping -Target $dns) { "successful" } else { "unsuccessful" }

$gatewayStatuses = @()
foreach ($gateway in $gateways) {
    $status = if (Test-Ping -Target $gateway) { "successful" } else { "unsuccessful" }
    $gatewayStatuses += [PSCustomObject]@{ Gateway = $gateway; Status = $status }
}





Show-Results -GoogleStatus $googleStatus -DnsStatus $dnsStatus -GatewayStatuses $gatewayStatuses -ComputerInfo $computerInfo
