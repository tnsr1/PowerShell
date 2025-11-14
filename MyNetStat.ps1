# интервал автообновления в секундах
$interval = 5
$lastUpdate = Get-Date

function Show-Connections {
    $list = @()
    $conns = Get-NetTCPConnection -State Established
    foreach ($c in $conns) {
        try {
            $proc = Get-Process -Id $c.OwningProcess -ErrorAction Stop

            # Определяем направление
            $direction = if ($c.LocalAddress -eq "127.0.0.1" -or $c.LocalAddress -eq "::1") {
                "Loopback"
            } elseif ($c.LocalPort -lt 1024) {
                "Inbound"
            } else {
                "Outbound"
            }

            $list += [PSCustomObject]@{
                ProcessName = $proc.ProcessName
                PID         = $c.OwningProcess
                Path        = $proc.Path
                Direction   = $direction
                Local       = "$($c.LocalAddress):$($c.LocalPort)"
                Remote      = "$($c.RemoteAddress):$($c.RemotePort)"
            }
        } catch {}
    }

    Clear-Host
    $list | Sort-Object ProcessName | Format-Table -AutoSize
    Write-Host "`n[Space] обновить сейчас, [Esc] выйти, автообновление каждые $interval сек."
}

Show-Connections

while ($true) {
    # Проверяем нажатие клавиши
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq 'Escape') { break }
        if ($key.Key -eq 'Spacebar') {
            Show-Connections
            $lastUpdate = Get-Date
        }
    }

    # Автообновление по таймеру
    if ((Get-Date) - $lastUpdate -gt (New-TimeSpan -Seconds $interval)) {
        Show-Connections
        $lastUpdate = Get-Date
    }

    Start-Sleep -Milliseconds 200
}
