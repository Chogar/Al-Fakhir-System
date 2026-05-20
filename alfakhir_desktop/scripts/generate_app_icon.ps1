# Icône Windows professionnelle : PNG 512px + app_icon.ico + copie install.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$logoJpg = Join-Path $Root "assets\images\restaurant_logo.jpg"
$pngOut = Join-Path $Root "assets\images\app_icon_source.png"
$icoRunner = Join-Path $Root "windows\runner\resources\app_icon.ico"
$icoInstall = Join-Path (Split-Path $Root -Parent) "install\Al-Fakhir.ico"

Add-Type -AssemblyName System.Drawing

function New-GraphicsPath-RoundedRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = [Math]::Min($r, $w / 2, $h / 2)
  $path.AddArc($x, $y, $d * 2, $d * 2, 180, 90)
  $path.AddArc($x + $w - $d * 2, $y, $d * 2, $d * 2, 270, 90)
  $path.AddArc($x + $w - $d * 2, $y + $h - $d * 2, $d * 2, $d * 2, 0, 90)
  $path.AddArc($x, $y + $h - $d * 2, $d * 2, $d * 2, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-PolishedIconBitmap([int]$size, [System.Drawing.Image]$logo) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.Clear([System.Drawing.Color]::Transparent)

  $corner = $size * 0.22
  $bounds = New-Object System.Drawing.RectangleF 0, 0, $size, $size
  $path = New-GraphicsPath-RoundedRect 0, 0, $size, $size, $corner
  $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $bounds,
    [System.Drawing.Color]::FromArgb(255, 232, 58, 46),
    [System.Drawing.Color]::FromArgb(255, 176, 28, 22),
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
  )
  $g.FillPath($brush, $path)
  $brush.Dispose()

  $plateD = [int]($size * 0.78)
  $plateX = ($size - $plateD) / 2
  $plateY = ($size - $plateD) / 2
  $plateRect = New-Object System.Drawing.Rectangle $plateX, $plateY, $plateD, $plateD

  $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(48, 0, 0, 0))
  $shadowRect = New-Object System.Drawing.Rectangle ($plateX + 2), ($plateY + 4), $plateD, $plateD
  $g.FillEllipse($shadowBrush, $shadowRect)
  $shadowBrush.Dispose()

  $ringPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 201, 162, 36)), ([Math]::Max(2, $size / 128))
  $g.DrawEllipse($ringPen, $plateRect)
  $ringPen.Dispose()

  $plateBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $innerPlate = New-Object System.Drawing.Rectangle ($plateX + 3), ($plateY + 3), ($plateD - 6), ($plateD - 6)
  $g.FillEllipse($plateBrush, $innerPlate)
  $plateBrush.Dispose()

  if ($logo -ne $null) {
    $logoSize = [int]($plateD * 0.72)
    $lx = $plateX + ($plateD - $logoSize) / 2
    $ly = $plateY + ($plateD - $logoSize) / 2
    $g.SetClip($innerPlate)
    $g.DrawImage($logo, $lx, $ly, $logoSize, $logoSize)
    $g.ResetClip()
  } else {
    $fontSize = $size * 0.22
    $font = New-Object System.Drawing.Font "Segoe UI", $fontSize, [System.Drawing.FontStyle]::Bold
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $textBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 214, 45, 32))
    $g.DrawString("AF", $font, $textBrush, $innerPlate, $sf)
    $textBrush.Dispose()
    $font.Dispose()
  }

  $path.Dispose()
  $g.Dispose()
  return $bmp
}

function Save-IconFile([System.Drawing.Bitmap]$bmp256, [string]$icoPath) {
  $dir = Split-Path $icoPath -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $ptr = $bmp256.GetHicon()
  try {
    $icon = [System.Drawing.Icon]::FromHandle($ptr)
    $clone = New-Object System.Drawing.Icon $icon, 256, 256
    $fs = [System.IO.File]::Open($icoPath, [System.IO.FileMode]::Create)
    $clone.Save($fs)
    $fs.Close()
    $clone.Dispose()
    $icon.Dispose()
  } finally {
    [void][System.Runtime.InteropServices.Marshal]::DestroyIcon($ptr)
  }
}

$logo = $null
if (Test-Path $logoJpg) {
  $logo = [System.Drawing.Image]::FromFile($logoJpg)
}

try {
  $dirPng = Split-Path $pngOut -Parent
  if (-not (Test-Path $dirPng)) { New-Item -ItemType Directory -Force -Path $dirPng | Out-Null }

  $bmp512 = New-PolishedIconBitmap 512 $logo
  $bmp512.Save($pngOut, [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "PNG : $pngOut" -ForegroundColor Green

  $bmp256 = New-PolishedIconBitmap 256 $logo
  Save-IconFile $bmp256 $icoRunner
  Write-Host "ICO exe : $icoRunner" -ForegroundColor Green

  Save-IconFile $bmp256 $icoInstall
  Write-Host "ICO raccourci : $icoInstall" -ForegroundColor Green

  $bmp512.Dispose()
  $bmp256.Dispose()
} finally {
  if ($logo -ne $null) { $logo.Dispose() }
}
