$handbrakecli = "C:\Program Files\HandBrake\HandBrakeCLI.exe"
$outfile = "D:\OneDrive\GitHub\Logs\PlexAVIConvert.csv"
$filelist = Get-ChildItem C:\VideoTest\ -filter *.avi -recurse
$num = $filelist | measure
$filecount = $num.count

$i = 0;

ForEach ($file in $filelist) {
	$i++;
    $oldfile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;
	$newfile = $file.DirectoryName + "\" + $file.BaseName + ".mp4";

	$progress = ($i / $filecount) *100
	$progress = [Math]::Round($progress,2)
	$arguments = "--preset-import-file C:\Users\jeffa\AppData\Roaming\HandBrake\presets.json -Z Jeff-Plex -i `"$oldfile`" -o `"$newfile`" -f mp4 --verbose=1 -nonewwindow"
	#Clear-Host
	Write-Host -------------------------------------------------------------------------------
	Write-Host Handbrake Batch Encoding
	Write-Host "Processing - $oldfile"
	Write-Host "File $i of $filecount - $progress%"
	Write-Host -------------------------------------------------------------------------------
	Write-Host $handbrakecli $arguments
	wait-process -name HandbrakeCLI -ErrorAction SilentlyContinue
	Start-Process $handbrakecli $arguments
	wait-process -name HandbrakeCLI -ErrorAction SilentlyContinue
	$oldFile,$newfile | Export-CSV -path $outfile -NoTypeInformation –Append	
	remove-item $oldfile
	
}

<#
Write old file - new file to a text file
#>

<#
Keep from running multiple - get process - wait until process dies to start next?
Use graphics card for handbrake CLI?
Delete original AVI, MOV, etc
Start-process loop only spawn one window

if((Get-Process -Name handbrakecli -ErrorAction SilentlyContinue) -eq $null){
	Write-host HandbrakeNotRunning
}
#>