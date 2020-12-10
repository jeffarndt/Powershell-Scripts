$handbrakecli = "C:\Program Files\HandBrake\HandBrakeCLI.exe"
$filelist = Get-ChildItem C:\VideoTest\ -filter *.avi -recurse
$num = $filelist | measure
$filecount = $num.count

$i = 0;

$convert = ForEach ($file in $filelist) {
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
    Start-Process $handbrakecli $arguments | wait-process
}

while (($convert | Select-Object -Expand HasExited) -contains $false) {
    Start-Sleep -Milliseconds 100
}