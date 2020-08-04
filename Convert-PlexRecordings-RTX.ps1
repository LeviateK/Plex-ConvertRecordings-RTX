param ($inProcessPath)

$KeepGoing = $True
$env:GPU_FORCE_64BIT_PTR = 1
Import-Module Recycle -Force
write-host
write-host
write-host
write-host
write-host
write-host

function VerifyPlexRunning
{
    $PlexProcess = @(Get-Process "Plex Media Server")
    if ($PlexProcess)
    {
        write-host $(Get-Date) : Plex Is Running -ForegroundColor Cyan
        # Check Sub-Processes
    }
    else
    {
        write-host $(Get-Date) : Plex NOT Running - Starting Up... -ForegroundColor Yellow
        Start-Process -FilePath "C:\Program Files (x86)\Plex\Plex Media Server\Plex Media Server.exe" -Verbose
    }
}

function ShowMeTheProgress ($array, $iteration)
{
    
    $CurrentOp = ($array.IndexOf($iteration)+1)
    $Percent = ($CurrentOp/$array.count)*100
    Write-Progress -Activity "Converting Plex Recordings" -PercentComplete $Percent -CurrentOperation "Video File $CurrentOp  of $($array.count)"
}

function Test-FileLock ($Path) 
{
  
  $oFile = New-Object System.IO.FileInfo $Path
  if($Path.FullName -like "*comskipped*" -or $Path.FullName -like "*.grab*")
  {
    write-host $(Get-Date) : Temporary File Detected -ForegroundColor Yellow
    return $True
  }else{
  
  if ((Test-Path -Path $Path) -eq $false) {
    return $false
  }
  try 
  {
    $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    if ($oStream) 
    {
      $oStream.Close()
    }
    $false
  } catch 
  {
    # file is locked by a process.
    return $true
  }
  }
}

function VerifyFile ($NewFile) # newvideo.directoryname; newvideo.name
{
    <# -- Original Verify
    $shell = New-Object -ComObject "Shell.Application"
    $ObjDir = $shell.NameSpace($NewFile.DirectoryName)
    $ObjFile = $ObjDir.parsename($NewFile.Name)
    $Bitrate = $ObjDir.GetDetailsOf($ObjFile, '28')
    if ([string]::IsNullOrEmpty($Bitrate))
    {
        return $False
    }else {
    write-host Bitrate: $($Bitrate)
    Return $True }
    #>

    # FFPROBE Verify

    $StreamInfo = ffprobe -v quiet -print_format json -show_format -show_streams $NewFile | ConvertFrom-Json
    $VideoStream = $StreamInfo.streams | ? {$_.codec_type -eq 'video'}
    $AudioStream = @($StreamInfo.streams | ? {$_.codec_type -eq 'audio'})
    write-host
    write-host ** New File Facts ** -ForegroundColor Cyan
    write-host Video: $VideoStream.codec_long_name : $VideoStream.display_aspect_ratio : $VideoStream.width x $VideoStream.height
    if ($AudioStream.Count -eq 2)
    {
        write-host Audio Track 1: $AudioStream[0].codec_long_name : $AudioStream[0].channel_layout : $AudioStream[0].channels CH : $AudioStream[0].bit_rate BR : $AudioStream[0].sample_rate SR
        write-host Audio Track 2: $AudioStream[1].codec_long_name : $AudioStream[1].channel_layout : $AudioStream[1].channels CH : $AudioStream[1].bit_rate BR : $AudioStream[1].sample_rate SR
    }else
    {
        write-host Audio: $AudioStream.codec_long_name : $AudioStream.channel_layout : $AudioStream.channels CH : $AudioStream.bit_rate BR : $AudioStream.sample_rate SR
    }
    write-host
    if ($AudioStream.Count -eq 2 -and ([float]$AudioStream[0].bit_rate -gt 0 -and [float]$AudioStream[1].bit_rate -gt 0 -and (![string]::IsNullOrEmpty($VideoStream.tags.DURATION) -or ([float]$VideoStream.duration -gt 0))))
    {
        return $True
    }
    elseif ([float]$AudioStream[0].bit_rate -gt 0 -and (![string]::IsNullOrEmpty($VideoStream.tags.DURATION) -or ([float]$VideoStream.duration -gt 0)))
    {
        return $True
    }
    else
    {
        return $False
    }
        

}

while ($KeepGoing)
{
    write-host $(Get-Date) : Checking for new recordings...
    $oldVideos = @(Get-ChildItem -Include @("*.ts") -Path $inProcessPath -Recurse;)
    if ($oldVideos.count -gt 0)
    {
        write-host $(Get-Date) : Recordings to Convert: $oldVideos.count.ToString() -ForegroundColor Cyan
        foreach ($oldvideo in $oldVideos)
        {
            $IsFileLocked = Test-FileLock $oldvideo
            if ($IsFileLocked)
            {
                # File is Locked, Ignore and Continue
                write-host $(Get-Date) : Still Recording : $oldvideo.Name -ForegroundColor Yellow
                start-sleep -seconds 120
                VerifyPlexRunning
            }else
            {
                #Get-Date
                ShowMeTheProgress $oldVideos $oldvideo
                $newVideo = [io.path]::ChangeExtension($oldVideo.FullName, '.mkv')
                write-host $(Get-Date) : Converting $oldvideo.Name -ForegroundColor Yellow
                # Use ffprobe to determine which command to run
                $StreamInfo = ffprobe -v quiet -print_format json -show_format -show_streams $oldvideo | ConvertFrom-Json
                $VideoStream = $StreamInfo.streams | ? {$_.codec_type -eq 'video'}
                $AudioStream = @($StreamInfo.streams | ? {$_.codec_type -eq 'audio'})
                $AudioMapOrder = ""
                $HQAudio = $AudioStream | ? { $_.channels -gt 2}
                if ($AudioStream.count -eq 2 -and $HQAudio.index -eq 2)
                {
                   $a = 2
                }
                else
                {
                   $a = 1
                }
                
                    if ($VideoStream.codec_time_base -eq '1001/60000' -or $VideoStream.field_order -eq 'progressive')
                    {
                        write-host CPU-GPU Split -ForegroundColor DarkCyan
                        ffmpeg.exe -vsync 0 -c:v mpeg2_cuvid -i $oldvideo -vf "fade,hwupload_cuda" -ss 0 -map 0:0 -map 0:$a -map 0:$a -c:a:0 copy -c:a:1 aac -b:a:1 128k -filter:a:1 "pan=stereo|FL=0.5*FC+0.707*FL+0.707*BL+0.5*LFE|FR=0.5*FC+0.707*FR+0.707*BR+0.5*LFE" -c:v hevc_nvenc -preset fast -rc:v cbr_hq -rc-lookahead:v 32 -refs:v 16 -b_ref_mode:v middle -max_muxing_queue_size 512 -fflags +genpts $newVideo -loglevel 0 -stats -hide_banner -y
                    }
                    else
                    {
                        write-host ALL GPU FIREPOWER -ForegroundColor Green
                        ffmpeg.exe -vsync 0 -hwaccel cuvid -c:v mpeg2_cuvid -i $oldvideo -ss 0 -map 0:0 -map 0:$a -map 0:$a -c:a:0 copy -c:a:1 aac -b:a:1 128k -filter:a:1 "pan=stereo|FL=0.5*FC+0.707*FL+0.707*BL+0.5*LFE|FR=0.5*FC+0.707*FR+0.707*BR+0.5*LFE" -c:v hevc_nvenc -preset fast -rc:v cbr_hq -rc-lookahead:v 32 -refs:v 16 -b_ref_mode:v middle -max_muxing_queue_size 512 -fflags +genpts $newVideo -loglevel 0 -stats -hide_banner -y
                    }
                
                Start-sleep -Seconds 5
                if (VerifyFile $newVideo)
                {
                    write-host $(Get-Date) : Conversion Complete!
                    write-host $(Get-Date) : $newVideo -ForegroundColor Green
                    Remove-Item $oldvideo -Force
                }else 
                {
                    write-host $(Get-Date) : Check New File -ForegroundColor Yellow
                }
                write-host Sleeping...
                start-sleep -seconds 15
                VerifyPlexRunning
                write-host
            }
        }
        Write-Progress -Completed -Activity "Converting Plex Recordings"
    }else
    {
        write-host $(Get-Date) : Waiting for something new to convert... -ForegroundColor Magenta
        Start-Sleep -Seconds 60
        VerifyPlexRunning
        Start-Sleep -Seconds 60
    }
}