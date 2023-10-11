# S1_Update_Agents
Update SentinelOne Agents

This little script was written for my own convenience. On request I've shared it here. 
Feel free to do with it as you please.

# The summer of 2023
Finally, after years of requesting this and people in the community upvoting the feature request, SentinelOne finally released this functionality into their management portal. 

# What?
This PowerShell script will connect to your SentinelOne management portal using the information in the INI file.
Then it will query the `Online` Windows Agents, of the Groups specified in the INI file, and retrieve a list of those Agents that are not running the specified version.
Then it will send Upgrade commands to all of those Agents.

Personally I start this script every hour with a 'Scheduled Task' on one of my servers.
This makes sure that every devices that comes online, will be checked every hour to see if it's running the version I want it to run. And it will be upgraded if it doesn't. 


# Setup

The following three files should be placed anywhere on your system, in the same folder.
- SentinelOne_Upgrade.ps1
- SentinelOne_Upgrade.ini
- SentinelOne_Upgrade.csv

## Edit the INI file.

**LOG**

With the 'LOG' setting you can configure if you want a log file to be written or not.

**SentinelMgmtUrl**

This is the URL to your management portal (without trailing slash).

**ApiToken**

This is your API Token. Remember, your API Token does expire, so you have to renew it sometimes and update this file.
If you need help generatiing an API Token: https://support.sentinelone.com/hc/en-us/articles/360004195934-Generating-API-Tokens

**GroupIDs**

Enter the GroupIDs of the groups you wish to update. Either a single GroupID or multiple seperated by a comma.

**UpgradeVersion**

Enter the version number that you do not want to look for.
Meaning, if you want to upgrade Agents that are not running v22.1.4.10010 .. Enter that here. Either a single version number or multiple seperated by a comma.
Usually, you would enter here the latest version number available. Because that is the version you wish to upgrade too, so you don't need to look for Agents running this version. 

In this example, I want all my Windows Agents to update to v22.1.4.10010


```
[Settings]
;LOG-mode.  0 = Off , 1 = On
LOG=1

;The URL of your management console (without trailing slash)
SentinelMgmtUrl=https://euce1-200.sentinelone.net

;The API Token
ApiToken=YhbqEZbOOoknGnyAXeiAjSxsKzmyyfVY3BS8RiHBlsJfgh5U8qcKxQU1aak4

;The Group IDs to query, ie. the groups you want to update
GroupIDs=89457617522766,1193983122553,16631200501692

;The version number(s) to exclude in the Search Query (versions to be seperated by a comma)
UpgradeVersion=22.1.4.10010
```


## Edit the CSV file

Enter which kind of installation files you wish you use to upgrade your Windows Agents.
The CSV file has room for x86 and x64 Agents, and MSI and EXE packages.

Personally, I like to upgrade my Agents in a few steps.
If an Agent has been offline for many months, and it comes online, I'd like to upgrade it in smaller steps.
In this example, I want all my Windows machines Agents to update to v21.5.3.235 and then to v22.1.4.10010

Please make sure that the packages you are refering to here, actually do exist.
Verify in your portal; https://euce1-200.sentinelone.net/sentinels/packages

```
"CHECK_VERSION","EXE_x32","EXE_x64","MSI_x32","MSI_x64"
"21.5.3.235","SentinelInstaller-x86_windows_32bit_v21_5_3_235.exe","SentinelInstaller-x64_windows_64bit_v21_5_3_235.exe","SentinelInstaller_windows_32bit_v21_5_3_235.msi","SentinelInstaller_windows_64bit_v21_5_3_235.msi"
"22.1.4.10010","SentinelOneInstaller_windows_32bit_v22_1_4_10010.exe","SentinelOneInstaller_windows_64bit_v22_1_4_10010.exe","",""
```
As far as I understood it, as of v22.1.4.10010 it doesn't make much difference anymore if you push an MSI or an EXE package. But they prefer the EXE. That is why the PowerShell script will ignore the MSI option in the CSV file as of v22.1.4.10010

# Running the script

Start the PowerShell script.





# Example of the log file

```
2022-09-09 18:27:57 # 
2022-09-09 18:27:57 # ---------- Result 1/21 ----------
2022-09-09 18:27:57 # 
2022-09-09 18:27:57 # siteName: MyTestSite
2022-09-09 18:27:57 # computerName: NL-BP78G20J
2022-09-09 18:27:57 # lastActiveDate: 2022-08-17T15:15:57.717636Z
2022-09-09 18:27:57 # osName: Windows 10 Enterprise
2022-09-09 18:27:57 # P-do-VersionCheck | Start
2022-09-09 18:27:57 # P-do-VersionCheck |  Checking version 21.7.5.1080
2022-09-09 18:27:57 # P-do-CSV-Import | Start
2022-09-09 18:27:57 # P-do-CSV-Import | Finished
2022-09-09 18:27:57 # P-do-VersionCheck | 72bbfb80cdb00be63b4395a0dd Checking 21.7.5.1080 against 21.5.3.235
2022-09-09 18:27:57 # P-do-VersionCheck | 72bbfb80cdb00be63b4395a0dd Checking 21.7.5.1080 against 22.1.4.10010
2022-09-09 18:27:57 # P-do-VersionCheck |   72bbfb80cdb00be63b4395a0dd YAY! Upgrade to 22.1.4.10010 using SentinelOneInstaller_windows_64bit_v22_1_4_10010.exe
2022-09-09 18:27:57 # P-do-VersionUpgrade | Start
2022-09-09 18:27:57 # P-do-VersionUpgrade | postParams = {"filter":{"uuid":"72bbfb80cdb00be63b4395a0dd"},"data":{"isScheduled":false,"packageType":"AgentAndRanger","fileName":"SentinelOneInstaller_windows_64bit_v22_1_4_10010.exe","osType":"windows"}}
2022-09-09 18:27:58 # P-do-VersionUpgrade | Finished
2022-09-09 18:27:58 # P-do-VersionCheck | Finished
2022-09-09 18:27:58 # 
2022-09-09 18:27:58 # ---------- Result 2/21 ----------
.... etc ....
2022-09-09 18:28:03 # 
2022-09-09 18:28:03 # Script completed
2022-09-09 18:28:03 # 
2022-09-09 18:28:03 # 
```
