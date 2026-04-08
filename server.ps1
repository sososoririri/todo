$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:3001/")
$listener.Start()
Write-Host "Server running at http://localhost:3001/"

$root = $PSScriptRoot

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response

    $path = $req.Url.LocalPath.TrimStart('/')
    if ($path -eq '' -or $path -eq '/') { $path = 'index.html' }

    $file = Join-Path $root $path

    if (Test-Path $file -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        $mime = switch ($ext) {
            ".html" { "text/html; charset=utf-8" }
            ".css"  { "text/css; charset=utf-8" }
            ".js"   { "application/javascript; charset=utf-8" }
            ".json" { "application/json; charset=utf-8" }
            ".svg"  { "image/svg+xml" }
            ".png"  { "image/png" }
            ".ico"  { "image/x-icon" }
            default { "application/octet-stream" }
        }
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $res.ContentType = $mime
        $res.ContentLength64 = $bytes.Length
        $res.StatusCode = 200
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        # SPA fallback
        $fallback = Join-Path $root "index.html"
        $bytes = [System.IO.File]::ReadAllBytes($fallback)
        $res.ContentType = "text/html; charset=utf-8"
        $res.ContentLength64 = $bytes.Length
        $res.StatusCode = 200
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
    }
    $res.OutputStream.Close()
}
