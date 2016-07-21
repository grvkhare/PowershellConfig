$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $MyInvocation.MyCommand.Path
$directorypath = 'C:\Users\536300\Downloads\Powershell\To\'

$InstallLog = $directorypath + "\Log\GlobalConfigFileMove_Log_" + (get-date -uformat "%Y%m%d").ToString() + "_" + (get-date).Hour + "_" + (get-date).Minute + ".log"

Function Log
{
    param ([string] $Content)
    $LogContent = ((get-date).Hour).ToString() + ":" + ((get-date).Minute).ToString() + ":" + ((get-date).Second).ToString() + "=>" + $Content
    Write-Host $LogContent
    Add-content $InstallLog $LogContent
}


$PSPath = 'C:\Users\536300\Downloads\Powershell\To\'



# Input Parameters for Global Configuration files move
# ----------------------------------------------------

$GLSourceDir = 'C:\Users\536300\Downloads\Powershell\To\Source\'
$GLTargetDir = 'C:\Users\536300\Downloads\Powershell\To\Target\'

$csvpath = $PSPath+"MappingConfig.csv"
$MappingGl = Import-Csv $csvpath
$Count = $MappingGl.count

#Write-Host $csvpath
#Write-Host $MappingGl
#Write-Host $Count


#----------------------------------------- Global Configuration files move-Start --------------------------------------------------------------

$txtFile = $PSPath+"GlobalConfigFileList.txt"
$confFile = $PSPath+"Unmatched_GlobalConfigfiles.txt"


Try
{

if((Test-Path -Path $GLTargetDir))
{

# Moving Global config files from old location to new location:
# -------------------------------------------------------------

Log "Info-->Moving Global Config files into target location - Started"

$Folder = get-content $txtFile

 Foreach ($Folders in $Folder)
 {
     $MyFolder = $GLSourceDir + $Folders

         Move-Item $MyFolder $GLTargetDir
   
   
 }

Log "Info-->Moving Global Config files into target location - Finished"

Write-Host 'Global Config files are moved from old location to new location'

# Check unmatched global config files from the directory based on the input value:
# --------------------------------------------------------------------------------

for ($i=0; $i -le $Count-1; $i++) 
{
$FindString = $MappingGl[$i].OldValue

$RFindString = [Regex]::Escape($FindString)

#Write-Host $FindString

$PathArray = @()

Get-ChildItem $GLTargetDir| 
   Where-Object { $_.Attributes -ne "Directory"} | 
      ForEach-Object { 
         If (!(Get-Content $_.FullName | Select-String -Pattern $RFindString)) {
            $PathArray += $_.FullName
            }
}

Add-Content -Path $confFile -Value "`r`nThe following global config files are not matching with the input value: '$FindString' "
Add-Content -Path $confFile -Value "`n------------------------------------------------------------------------"

$PathArray | % {$_} | Add-Content $confFile
}

# Check matching global config files from the directory based on the input value:
# --------------------------------------------------------------------------------
 
for ($i=0; $i -le $Count-1; $i++)
{
$FindString = $MappingGl[$i].NewValue
 
$RFindString = [Regex]::Escape($FindString)
 
#Write-Host $FindString
 
$PathArray = @()
 
Get-ChildItem $GLTargetDir|
 
Where-Object { $_.Attributes -ne “Directory”} |
ForEach-Object {
If (Get-Content $_.FullName | Select-String -Pattern $RFindString) {
$PathArray += $_.FullName

}
}
Add-Content -Path $confFile -Value "`r`nThe following global config files are matching with the input value: '$FindString' "
Add-Content -Path $confFile -Value "`n------------------------------------------------------------------------"
$PathArray | % {$_} | Add-Content $confFile
}


# Updating global config files with new values:
# ---------------------------------------------

for ($i=0; $i -le $Count; $i++) 
{
$FindString = $MappingGl[$i].OldValue
$ReplaceString = $MappingGl[$i].NewValue

#Write-Host $ReplaceString

$FindString = [Regex]::Escape($FindString)

$files = Get-ChildItem $GLTargetDir| where {$_.extension -eq ".dtsConfig"};

Write-Host $files
foreach($file in $files)
{

	(Get-Content $file.PSPath) | 
	Foreach-Object {$_ -replace $FindString, $ReplaceString} | 
	Set-Content $file.PSPath

}

}



Log "Info-->Global Config files are updated with new connection string,package path and provider"

Write-Host 'Global Config files are updated with new values'

}
}
Catch
{
Log "Error occured: $_"
}

#----------------------------------------- Global Configuration files move-End --------------------------------------------------------------

