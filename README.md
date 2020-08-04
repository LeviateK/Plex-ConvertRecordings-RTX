# Plex-ConvertRecordings-RTX
PowerShell Script that scans directory for .ts files and converts them using CPU-GPU Split or Full GPU Decode/Encode on NVIDIA RTX
Output file will be an .mkv with 1 Track Copied Source Audio and Another Track AAC with proper LFE Filtering
RTX GPUs have the ability to use FFMPEGs lookahead feature for even faster encoding.

Requires:
1) FFMPEG installed & directory added to PATH system variable
