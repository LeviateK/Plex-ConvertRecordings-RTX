# Plex-ConvertRecordings-RTX
PowerShell Script that scans directory for .ts files and converts them using CPU-GPU Split or Full GPU Decode/Encode on NVIDIA RTX

Output file will be an .mkv with 1 Track Copied Source Audio and Another Track AAC with proper LFE Filtering

RTX GPUs have the ability to use FFMPEGs lookahead feature for even faster encoding.

Requires:
1) FFMPEG installed & directory added to PATH system variable

Usage:
Convert-PlexRecordings-RTX.ps1 -inProcessPath C:\Plex

Notes:
1) Source TS file will be removed forcefully after successful conversion.  If you wish to keep it, comment out line 166 (Remove-Item)
2) Script checks for files being recorded and ignores them
3) You can target your entire Plex Librbary, or split the script up against sub-libraries (initial search is faster)
4) Script ensures Plex is running
5) Script outputs relevant new file facts to ensure a good quality conversion (it cannot make up for poor reception)

Any comments/questions/issues, let me know.
Cheers!
