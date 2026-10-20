param([string]$Out, [int]$X = 0, [int]$Y = 0, [int]$W = 0, [int]$H = 0)
Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr v);'
[W.U]::SetProcessDpiAwarenessContext([IntPtr]-4) | Out-Null  # Per-Monitor V2: 물리 픽셀 좌표
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$all = [System.Windows.Forms.SystemInformation]::VirtualScreen
if ($W -eq 0) { $X = $all.X; $Y = $all.Y; $W = $all.Width; $H = $all.Height }
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($X, $Y, 0, 0, $bmp.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"virtual screen $all; saved ${W}x${H}"
foreach ($s in [System.Windows.Forms.Screen]::AllScreens) { "$($s.DeviceName) $($s.Bounds)" }
