# Скрипт резервирования и ротации логов 
# Для работы скрипта необходимо, что-бы в папке скрипта находилась папка с 7zip.

[string] $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition    
[string] $pathToZipExe = $scriptPath + '\7-Zip\7z.exe'


[string] $strBackupLogPath = $args[0].ToString()
[string] $strSrv = $args[1].ToString()
[string] $strSourceLogPath = $args[2].ToString()
[int] $intDays = [int] $args[3]

# sample:
# [string] $strBackupLogPath = '\\server\share\folder'
# [string] $strSrv = 'server'
# [string] $strSourceLogPath = 'c$\inetpub\logs'
# [int] $intDays = 5

[psobject[]] $arrFiles

#$('\\' + $strSrv + $strSourceLogPath)

$arrFiles = Get-ChildItem $('\\' + $strSrv + '\' +$strSourceLogPath) -Recurse | Where-Object {($_.LastWriteTime -lt  (get-date).AddDays(-1)) -and  ($_.LastWriteTime -ge  (get-date).AddDays((($intDays + 1) * -1)))} 

Foreach($objfile in $arrFiles)
{
    If (!$objfile.PSIsContainer)
    {
        $DirectoryPath = $strBackupLogPath + $objfile.DirectoryName.ToString().Replace('\\','\')
        $FileArchive = $DirectoryPath + '\' + $objfile.Name + '.zip'

        If(!(Test-Path $DirectoryPath))
        {
            New-Item $DirectoryPath -Type Directory
        }
        
        If(!(Test-Path $FileArchive)) 
        {
            [Array] $arguments = 'a', '-tzip', $FileArchive, $objfile.FullName
            &$pathToZipExe $arguments
            $(Get-Item $FileArchive).CreationTime = $objfile.CreationTime
            $(Get-Item $FileArchive).LastWriteTime = $objfile.LastWriteTime
            $(Get-Item $FileArchive).LastAccessTime = $objfile.LastAccessTime
        }
    }
 }

Get-ChildItem -Path $strBackupLogPath -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt (get-date).AddDays((($intDays + 1) * -1)) } | Remove-Item -Force
Get-ChildItem -Path $strBackupLogPath -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
