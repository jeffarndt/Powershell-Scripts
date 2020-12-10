$handbrakecli = "C:\Program Files\HandBrake\HandBrakeCLI.exe"
$outfile = "D:\OneDrive\GitHub\Logs\PlexConvert\PlexConvert.csv"
$processingFile = "D:\OneDrive\GitHub\Logs\PlexConvert\PlexProcessing.csv"
$deletingfile = "D:\OneDrive\GitHub\Logs\PlexConvert\PlexDeleting.csv"
$filelist = Get-ChildItem C:\VideoTest\* -Include *.avi,*.mov,*.mkv -recurse
#$filelist = Get-ChildItem C:\VideoTest\ -filter *.avi -recurse
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

	$Files = "$oldFile,$newfile"
	#Clear-Host
	Write-Host -------------------------------------------------------------------------------
	Write-Host Handbrake Batch Encoding
	Write-Host "Processing - $oldfile"
	Write-Host "File $i of $filecount - $progress%"
	Write-Host -------------------------------------------------------------------------------
	#Write-Host $handbrakecli $arguments
	wait-process -name HandbrakeCLI -ErrorAction SilentlyContinue
	$oldfile |  Out-File -Filepath $processingFile -NoClobber -Append
	Start-Process $handbrakecli $arguments
	$Files | out-file -filepath $outfile -NoClobber -Append
	wait-process -name HandbrakeCLI -ErrorAction SilentlyContinue
	remove-item $oldfile
	$oldfile | Out-File -FilePath $deletingfile -NoClobber -Append

	
}

<#
Done - Keep from running multiple - get process - wait until process dies to start next?
Not possible - Use graphics card for handbrake CLI?
Done - Delete original AVI, MOV, etc
Done - Work with multiple extension types
Done - Write old file - new file to a text file https://stackoverflow.com/questions/34963171/powershell-export-csv-return-numbers

Done - Start-process loop only spawn one window
#>