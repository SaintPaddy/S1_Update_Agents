# S1_Update_Agents
Update SentinelOne Agents

This little script was written for my own convenience. On request I've shared it here. 
Feel free to do with it as you please.


#Setup

The following three files should be placed anywhere on your system.
- SentinelOne_Upgrade.ps1
- SentinelOne_Upgrade.ini
- SentinelOne_Upgrade.csv

##Edit the INI file.

**LOG**
With the 'LOG' setting you can configure if you want a log file to be written or not.

**SentinelMgmtUrl**
This is the URL to your management portal.

**ApiToken**
This is your API Token. Remember, your API Token does expire, so you have to renew it sometimes and update this file.
If you need help generatiing an API Token: https://support.sentinelone.com/hc/en-us/articles/360004195934-Generating-API-Tokens

**GroupIDs**
Enter the GroupIDs of the groups you wish to update. Either a single GroupID or multiple seperated by a comma.

**UpgradeVersion**
The PowerShell script will run a query and filter out all Agents with this version. Usually, you would enter here the latest version number available. 

In this example, I want all my Windows machines Agents to update to v22.1.4.10010


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


##Edit the CSV file

Enter which kind of installation files you wish you use to upgrade your Windows Agents.
The CSV file has room for x86 and x64 Agents, and MSI and EXE packages.

Personally, I like to upgrade my Agents in a few steps.
If an Agent has been offline for many months, and it comes online, I'd like to upgrade it in smaller steps.
In this example, I want all my Windows machines Agents to update to v21.5.3.235 and then to v22.1.4.10010

Please make sure that the package you are entering here, actually do exist.
Verify in your portal; https://euce1-200.sentinelone.net/sentinels/packages

```
"CHECK_VERSION","EXE_x32","EXE_x64","MSI_x32","MSI_x64"
"21.5.3.235","SentinelInstaller-x86_windows_32bit_v21_5_3_235.exe","SentinelInstaller-x64_windows_64bit_v21_5_3_235.exe","SentinelInstaller_windows_32bit_v21_5_3_235.msi","SentinelInstaller_windows_64bit_v21_5_3_235.msi"
"22.1.4.10010","SentinelOneInstaller_windows_32bit_v22_1_4_10010.exe","SentinelOneInstaller_windows_64bit_v22_1_4_10010.exe","SentinelOneInstaller_windows_32bit_v22_1_4_10010.exe","SentinelOneInstaller_windows_64bit_v22_1_4_10010.exe"
```
As far as I understood it, as of v22.1.4.10010 it doesn't make much difference anymore if you push an MSI or an EXE package. But they prefer the EXE. So that's why I use that now.

#Running the script

Start the PowerShell script.
