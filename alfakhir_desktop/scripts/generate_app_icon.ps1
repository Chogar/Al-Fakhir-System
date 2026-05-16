# Icône Windows professionnelle : PNG 512px + app_icon.ico + copie install.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$logoJpg = Join-Path $Root "assets\images\restaurant_logo.jpg"
$pngOut = Join-Path $Root "assets\images\app_icon_source.png"
$icoRunner = Join-Path $Root "windows\runner\resources\app_icon.ico"
$icoInstall = Join-Path (Split-Path $Root -Parent) "install\Al-Fakhir.ico"

Add-Type -AssemblyName System.Drawing

function New-RoundedRectPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = [Math]::Min($r, [Math]::Min($w / 2, $h / 2))
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
  $bounds = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
  $path = New-RoundedRectPath -x 0 -y 0 -w $size -h $size -r $corner
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
  $plateRect = New-Object System.Drawing.Rectangle([int]$plateX, [int]$plateY, $plateD, $plateD)

  $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(48, 0, 0, 0))
  $shadowRect = New-Object System.Drawing.Rectangle([int]($plateX + 2), [int]($plateY + 4), $plateD, $plateD)
  $g.FillEllipse($shadowBrush, $shadowRect)
  $shadowBrush.Dispose()

  $ringPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 201, 162, 36)), ([Math]::Max(2, $size / 128))
  $g.DrawEllipse($ringPen, $plateRect)
  $ringPen.Dispose()

  $plateBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $innerPlate = New-Object System.Drawing.Rectangle([int]($plateX + 3), [int]($plateY + 3), ($plateD - 6), ($plateD - 6))
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

function Save-MultiSizeIconFile([System.Drawing.Image]$logo, [string]$icoPath) {
  if (-not ("MultiSizeIconWriter" -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class MultiSizeIconWriter {
  public static void Save(string path, IEnumerable<Bitmap> sources) {
    using (var fs = File.Create(path))
    using (var bw = new BinaryWriter(fs)) {
      bw.Write((ushort)0);
      bw.Write((ushort)1);
      var images = new List<byte[]>();
      var entries = new List<Tuple<int,int,int>>();
      foreach (var bmp in sources) {
        using (var ms = new MemoryStream()) {
          bmp.Save(ms, ImageFormat.Png);
          var data = ms.ToArray();
          images.Add(data);
          entries.Add(Tuple.Create(bmp.Width, bmp.Height, data.Length));
        }
      }
      bw.Write((ushort)entries.Count);
      int offset = 6 + entries.Count * 16;
      foreach (var e in entries) {
        bw.Write((byte)(e.Item1 >= 256 ? 0 : e.Item1));
        bw.Write((byte)(e.Item2 >= 256 ? 0 : e.Item2));
        bw.Write((byte)0);
        bw.Write((byte)0);
        bw.Write((ushort)1);
        bw.Write((ushort)32);
        bw.Write((uint)e.Item3);
        bw.Write((uint)offset);
        offset += e.Item3;
      }
      foreach (var data in images) bw.Write(data);
    }
  }
}
"@
  }
  $sizes = @(16, 24, 32, 48, 64, 128, 256)
  $bitmaps = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
  foreach ($s in $sizes) {
    $bitmaps.Add((New-PolishedIconBitmap $s $logo))
  }
  try {
    $dir = Split-Path $icoPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [MultiSizeIconWriter]::Save($icoPath, $bitmaps)
  } finally {
    foreach ($b in $bitmaps) { $b.Dispose() }
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

  Save-MultiSizeIconFile $logo $icoRunner
  Write-Host "ICO exe : $icoRunner" -ForegroundColor Green

  Save-MultiSizeIconFile $logo $icoInstall
  Write-Host "ICO raccourci : $icoInstall" -ForegroundColor Green

  $bmp512.Dispose()
} finally {
  if ($logo -ne $null) { $logo.Dispose() }
}
