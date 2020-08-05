# Plex-ConvertRecordings-RTX
PowerShell Script that scans directory for .ts files and converts them using CPU-GPU Split or Full GPU Decode/Encode on NVIDIA RTX

Output file will be an .mkv with 1 Track Copied Source Audio and Another Track AAC with proper LFE Filtering

RTX GPUs have FFMPEGs lookahead feature support for even faster encoding.

Requires:
1) FFMPEG installed & directory added to PATH system variable

Usage:
Convert-PlexRecordings-RTX.ps1 -inProcessPath C:\Plex

This is NOT a post-processing script, but a standalone script that can be run interactively or via scheduled task

Currently, this has only been used on Windows.

Notes:
1) Source TS file will be removed forcefully after successful conversion.  If you wish to keep it, comment out line 166 (Remove-Item)
2) Script checks for files being recorded and ignores them
3) You can target your entire Plex Librbary, or split the script up against sub-libraries (initial search is faster)
4) Script ensures Plex is running
5) Script outputs relevant new file facts to ensure a good quality conversion (it cannot make up for poor reception)
6) Because I really can't tell the difference and opt for speed & small file sizes, I use ffmpeg preset 'fast'.  Feel free to experiment (Lines 153 and 158).

Benchmarks:
1) HD TV Episode on RTX 2060 Super: 750fps, 12.5x speed
2) SD TV Episode on RTX 2060 Super: 1200fps, 40x speed

Any comments/questions/issues, let me know.
Cheers!
