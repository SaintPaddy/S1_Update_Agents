<#
https://github.com/SaintPaddy/
2022-01-18 Added 'Process-Exception' in the hopes to get more details
2021-09-14 Initial version.
#>


# Log file; The folder to write logging to
$LogOutputFolder = (Get-Item $PSCommandPath ).DirectoryName+"\Logs"

# Log file; in case we wish to output logging into a logfile
$LogOutputFile = $LogOutputFolder+"\"+(Get-Item $PSCommandPath ).BaseName+"_$(Get-Date -Format "yyyy-MM-dd_HH-mm").txt"

# CSV file; File containing the versions to upgrade to, and their MSI/EXE files
$CsvDataFile  = (Get-Item $PSCommandPath ).DirectoryName+"\"+(Get-Item $PSCommandPath ).BaseName+".csv"

# INI file; contains the variables to run this script
$INIDataFile  = (Get-Item $PSCommandPath ).DirectoryName+"\"+(Get-Item $PSCommandPath ).BaseName+".ini"




# Generate logging in case have LOG variable enabled
function doLog
{
	if ($LOG -eq $true){
		foreach($a in $input)
		{
			#Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") # $a"
			"$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") # $a" | Out-File -append $LogOutputFile
		}
	}
}

function CleanUpLogFiles
{
    if (Test-Path -Path $LogOutputFolder -PathType Container) {
        Get-ChildItem -Path "$((Get-Item $PSCommandPath ).DirectoryName)\Logs\" -File -Filter "$((Get-Item $PSCommandPath).BaseName)*.txt" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) -and $_.Length -eq 152 } | Remove-Item -Force
        Get-ChildItem -Path "$((Get-Item $PSCommandPath ).DirectoryName)\Logs\" -File -Filter "$((Get-Item $PSCommandPath).BaseName)*.txt" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } | Remove-Item -Force
    }
}

# INI file; Load the data
function P-do-Load-IniFile
{
	"P-do-Load-IniFile | Start" | doLog
	try {
		if (-not(Test-Path -Path $INIDataFile -PathType Leaf)) {
			"P-do-Load-IniFile | INIDataFile does not exist. Script terminated." | doLog
			Exit 1
		}
	} catch {
		"P-do-Load-IniFile | Error: Accessing INIDataFile. Script terminated." | doLog
		Exit 1
	}
	
	$ini = @{}

	# Create a default section if none exist in the file. Like a java prop file.
	$section = "NO_SECTION"
	$ini[$section] = @{}

	switch -regex -file $INIDataFile {
		"^\[(.+)\]$" {
			$section = $matches[1].Trim()
			$ini[$section] = @{}
		}
		"^\s*([^#].+?)\s*=\s*(.*)" {
			$name,$value = $matches[1..2]
			#skip comments that start with semicolon:
			if (!($name.StartsWith(";"))) {
				$ini[$section][$name] = $value.Trim()
			}
		}
	}
	"P-do-Load-IniFile | Finished" | doLog
	$ini
}

# Function to kick off the upgrade command
function P-do-VersionUpgrade
{
	Param(
		[Parameter(Mandatory=$true,position=0,HelpMessage="The uuid of the SentinelOne Agent")]
		[string[]]
		$AgentUuid,

		[Parameter(Mandatory=$true,position=1,HelpMessage="The filename of the file we want to use for the upgrade")]
		[string[]]
		$UpgradeFile
	)
	"P-do-VersionUpgrade | Start" | doLog

	# HTTP; Connect to SentinelOne management portal, and send upgrade command
	try {
		$postParams = @{
			data= @{
				isScheduled=$false;
				fileName="$UpgradeFile";
				osType="windows";
				packageType="AgentAndRanger";
			};
			filter= @{
				uuid="$AgentUuid";
			};
		} | ConvertTo-Json -Compress
		"P-do-VersionUpgrade | postParams = $postParams" | doLog
		$r = Invoke-WebRequest "$($ini.Settings.SentinelMgmtUrl)/web/api/v2.1/agents/actions/update-software" -ContentType "application/json" -Method POST -Body $postParams -UseBasicParsing -ErrorAction:Stop -TimeoutSec 300 `
		-Headers @{'Authorization' = "ApiToken $($ini.Settings.ApiToken)"}
	} catch {
		"P-do-VersionUpgrade | Error: Connection failure. Script terminated." | doLog
		Process-Exception -Exception $_.Exception
		#$_.Exception.Message
		#$_.Exception.ItemName
		#Start-Sleep -s 100
		Exit 1
	}

	# HTTP; Check status code
	if ($r.StatusCode -ne 200) {
		"P-do-VersionUpgrade | Error: Status code is $($r.StatusCode). Script terminated." | doLog
		#Start-Sleep -s 10
		Exit 1
	}

	"P-do-VersionUpgrade | Finished" | doLog
}

# Function to walk through versions and kick off upgrade
function P-do-VersionCheck
{
	Param(
		[Parameter(Mandatory=$true,position=0,HelpMessage="The uuid of the SentinelOne Agent")]
		[ValidateNotNullOrEmpty ()]
		[string[]]
		$AgentUuid,

		[Parameter(Mandatory=$true,position=1,HelpMessage="The custom tag, identifies if we need an MSI or EXE and 32 of 64bit")]
		[string[]]
		$CSVUpgradeType,

		[Parameter(Mandatory=$true,position=2,HelpMessage="The current version of the installed SentinelOne Agent")]
		[string[]]
		$VersionString
	)

	$Version = [Version]::new($VersionString)
	"P-do-VersionCheck | Start" | doLog

	"P-do-VersionCheck |  Checking version $Version" | doLog

	if ($global:SqlDataArr -eq $null){
		P-do-CSV-Import
	}
	#$global:SqlDataArr | ForEach-Object {
	foreach($line in $global:SqlDataArr){
		"P-do-VersionCheck | $AgentUuid Checking $Version against $($line.CHECK_VERSION)" | doLog
		#"CHECK_VERSION = $($line.CHECK_VERSION)"
		#"EXE_x32 = $($line.EXE_x32)"
		#"EXE_x64 = $($line.EXE_x64)"
		#"MSI_x32 = $($line.MSI_x32)"
		#"MSI_x64 = $($line.MSI_x64)"

		if ( $Version -lt [Version]::new($($line.CHECK_VERSION))) {
			"P-do-VersionCheck |   $AgentUuid YAY! Upgrade to $($line.CHECK_VERSION) using $($line.$CSVUpgradeType)" | doLog
			P-do-VersionUpgrade $AgentUuid $($line.$CSVUpgradeType)
			break;
		}
	}

	"P-do-VersionCheck | Finished" | doLog
}

# CSV file; Load the data
$SqlDataArr = $null
function P-do-CSV-Import
{
	"P-do-CSV-Import | Start" | doLog
	try {
		if (-not(Test-Path -Path $CsvDataFile -PathType Leaf)) {
			"P-do-CSV-Import | CsvDataFile does not exist. Script terminated." | doLog
			Exit 1
		}
		$global:SqlDataArr = import-csv $CsvDataFile
	} catch {
		"P-do-CSV-Import | Error: Accessing CsvDataFile. Script terminated." | doLog
		Exit 1
	}
	"P-do-CSV-Import | Finished" | doLog
}

function Process-Exception {
    [CmdletBinding()]
    param (
        [System.Exception] $Exception
    )
    $dateTime = Get-Date
    #for now: write-host [string] instead of -Message [string]
    "Date and time:`t" + $dateTime + "`r`n"     | doLog
    "Exception Source:`t" + $Exception.Source   | doLog
    "Error Code:`t"+ $Exception.NativeErrorCode | doLog
    "Exception Message:" + $Exception.Message   | doLog
	"Exception ItemName:" + $Exception.ItemName | doLog
    "Stack Trace:`t" + $Exception.StackTrace + "`r`n`r`n" | doLog

	$reader = New-Object System.IO.StreamReader($Exception.Response.GetResponseStream())
	$reader.BaseStream.Position = 0
	$reader.DiscardBufferedData()
	$reader.ReadToEnd() | ConvertFrom-Json | doLog
}

#check Administrator privileges
#$user = [Security.Principal.WindowsIdentity]::GetCurrent();
#$admin=(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
#if ($admin -eq $false) {
#	"Please run the script as Administrator"
#	#Start-Sleep -s 20
#	Exit 1
#}

# Set TLS version
# https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# Load the settings in the INI file
$LOG = $false
$ini = P-do-Load-IniFile

# Set LOG mode
$LOG = $(If ($ini.Settings.LOG -eq 1) { $true } Else { $false })

# If LOG mode is turned On, check if folder exists
if ($LOG -eq $true){
	if ( -Not (Test-Path -Path $LogOutputFolder -PathType Container)) {
		New-Item -ItemType Directory -Force -Path "$LogOutputFolder" | Out-Null
		if ( -Not (Test-Path -Path $LogOutputFolder -PathType Container)) {
			Write-Host "Error, could not create folder $LogOutputFolder"
			Start-Sleep -s 60
			Exit 1
		}
	}
}

# Clean up old log files
CleanUpLogFiles

# HTTP; Connect to SentinelOne management portal, provide headers and values
try {
	$r = Invoke-WebRequest "$($ini.Settings.SentinelMgmtUrl)/web/api/v2.1/agents?limit=100&groupIds=$($ini.Settings.GroupIDs)&agentVersionsNin=$($ini.Settings.UpgradeVersion)&isActive=true&osTypes=windows" -UseBasicParsing -ErrorAction:Stop -TimeoutSec 300 `
	-Headers @{'Authorization' = "ApiToken $($ini.Settings.ApiToken)"}
} catch {
	"Error: Connection failure. Script terminated." | doLog
	Process-Exception -Exception $_.Exception
	Exit 1
}

# HTTP; Check status code
if ($r.StatusCode -ne 200) {
	"Error: Status code is $($r.StatusCode). Script terminated." | doLog
	Exit 1
}

# Convert the Content from JSON
$jsonObj = ConvertFrom-Json $([String]::new($r.Content))

# Check the amount of Hosts found
$totalItems = $jsonObj.pagination.totalItems -as [int]
if ( $totalItems -eq 0) {
	"Error: Search yielded 0 results. Script terminated." | doLog
	Exit 1
}

# Walk through all returend hosts - echo data on screen - kick off version check
$i = 1;
$jsonObj.data | Sort-Object {$_.lastActiveDate} | ForEach-Object {
	""													| doLog
	"---------- Result "+$i+"/"+$totalItems+" ----------" | doLog
	""													| doLog
	"siteName: $($_.siteName)"							| doLog
	"computerName: $($_.computerName)"					| doLog
	"lastActiveDate: $($_.lastActiveDate)"				| doLog
	"osName: $($_.osName)"								| doLog


	# Check which Agent version we need, then build a string. This string is the Header value (column name) of the CSV import file
	# $CSVUpgradeType = "$(If ($_.installerType -Match "msi") {"MSI"} Else {"EXE"})_$(If ($_.osArch -Match "64") {"x64"} Else {"x32"})"
	# 2022-08-08: If the version is bigger then 22.1.4.10010 we always install the EXE version and can ignore the MSI. As of now it doesn't matter anymore.
	$CSVUpgradeType = "$(If ( [Version]::new($_.agentVersion) -lt [Version]::new("22.1.4.10010")) { If ($_.installerType -Match "msi") {"MSI"} Else {"EXE"} } Else {"EXE"})_$(If ($_.osArch -Match "64") {"x64"} Else {"x32"})"

	P-do-VersionCheck $($_.uuid) $CSVUpgradeType $($_.agentVersion) 

	$i += 1;
}
"--------------------------------" | doLog


"" | doLog
"" | doLog
"Script completed" | doLog
"" | doLog
"" | doLog

Exit 0