<#
.SYNOPSIS
    将目录内的所有 .opus 文件转换为 .ogg 格式。

.PARAMETER Path
    要处理的目录，默认为当前目录。

.PARAMETER Recurse
    是否递归处理子目录。

.PARAMETER Reencode
    是否使用 Vorbis 重新编码（默认直接复制 Opus 流，无损且快速）。

.PARAMETER Overwrite
    是否覆盖已存在的 .ogg 文件。

.EXAMPLE
    .\Convert-OpusToOgg.ps1 -Path "D:\Music" -Recurse
#>
[CmdletBinding()]
param(
    [string]$Path = ".",
    [switch]$Recurse,
    [switch]$Reencode,
    [switch]$Overwrite
)

# ---- 1. 检查 ffmpeg ----
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    Write-Error "未找到 ffmpeg，请先安装并加入 PATH（https://ffmpeg.org/download.html）"
    exit 1
}

# ---- 2. 检查目录 ----
if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    Write-Error "目录不存在: $Path"
    exit 1
}
$root = (Resolve-Path -LiteralPath $Path).Path

# ---- 3. 收集 opus 文件 ----
$files = Get-ChildItem -LiteralPath $root -Filter *.opus -File -Recurse:$Recurse
if (-not $files) {
    Write-Host "未找到 .opus 文件。" -ForegroundColor Yellow
    exit 0
}

Write-Host "共找到 $($files.Count) 个 .opus 文件，开始转换..." -ForegroundColor Cyan

# ---- 4. 根据模式构造 ffmpeg 参数 ----
if ($Reencode) {
    # 使用 Vorbis 重新编码
    $codecArgs = @('-c:a', 'libvorbis', '-q:a', '5')
    $modeDesc  = "重新编码为 Vorbis (q=5)"
} else {
    # 直接复制 Opus 流（无损、快速）
    $codecArgs = @('-c:a', 'copy')
    $modeDesc  = "无损重封装 (copy)"
}
Write-Host "模式: $modeDesc`n" -ForegroundColor DarkGray

# ---- 5. 逐个转换 ----
$ok = 0
$skipped = 0
$failed = 0

foreach ($file in $files) {
    $outFile = [System.IO.Path]::ChangeExtension($file.FullName, '.ogg')

    if ((Test-Path -LiteralPath $outFile) -and -not $Overwrite) {
        Write-Host "[跳过] 已存在: $outFile" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    Write-Host "[转换] $($file.Name)" -ForegroundColor Green

    $ffArgs = @(
        '-hide_banner', '-loglevel', 'error',
        '-y',
        '-i', $file.FullName,
        '-vn'
    ) + $codecArgs + @($outFile)

    & ffmpeg @ffArgs

    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $outFile)) {
        $ok++
    } else {
        Write-Warning "转换失败: $($file.FullName)"
        $failed++
        if (Test-Path -LiteralPath $outFile) {
            Remove-Item -LiteralPath $outFile -Force
        }
    }
}

# ---- 6. 汇总 ----
Write-Host "`n===== 完成 =====" -ForegroundColor Cyan
Write-Host ("成功: {0}  跳过: {1}  失败: {2}" -f $ok, $skipped, $failed)