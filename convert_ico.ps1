Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("assets/icon/app_icon.png")
$bmp = New-Object System.Drawing.Bitmap($img, 256, 256)
$icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
$stream = New-Object System.IO.FileStream("windows/runner/resources/app_icon.ico", [System.IO.FileMode]::Create)
$icon.Save($stream)
$stream.Close()
Write-Host "ICO converted successfully!"
