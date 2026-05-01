$ErrorActionPreference = "Stop"

# ===========================================================
# PLAYLIST HUB - SYNC SCRIPT (Auto-Discovery v2)
# Toan Ca Chep - 2026
# ===========================================================

$CsvPath = ".\quan_ly_de_thi.csv"
$KhoDeGoc = ".\01_Kho_De_Goc"
$TestWebDir = "..\Test_Web"
$DestDeDir = ".\de"
$HtmlPath = ".\index.html"

# ============== PHASE 0: AUTO-DISCOVERY ==============
Write-Host ""
Write-Host "=========================================" -ForegroundColor Magenta
Write-Host "  ROBOT QUET DE TU DONG (Auto-Discovery)" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta

# Dam bao thu muc 01_Kho_De_Goc ton tai
if (-not (Test-Path $KhoDeGoc)) {
    New-Item -ItemType Directory -Path $KhoDeGoc -Force | Out-Null
}

# Doc CSV hien tai de biet nhung de nao da co
$csvExists = Test-Path $CsvPath
if ($csvExists) {
    $csvData = Import-Csv $CsvPath -Encoding UTF8
} else {
    $csvData = @()
}

# Lay danh sach File_Goc da co trong CSV de kiem tra trung lap
$existingFiles = @()
foreach ($row in $csvData) {
    $existingFiles += $row.File_Goc
}

# Tim so ID lon nhat hien tai de tu dong tang
$maxIdNum = 0
foreach ($row in $csvData) {
    if ($row.ID -match 'de_(\d+)') {
        $num = [int]$Matches[1]
        if ($num -gt $maxIdNum) { $maxIdNum = $num }
    }
}

# Map ten dang de thi sang ten hien thi
$dangMap = @{
    "THPTQG" = "thptqg"
    "CKII"   = "hk"
    "CKI"    = "hk"
    "HKII"   = "hk"
    "HKI"    = "hk"
    "GK"     = "hk"
}
$dangDisplayMap = @{
    "THPTQG" = "Thi thử THPTQG"
    "CKII"   = "Cuối kỳ II"
    "CKI"    = "Cuối kỳ I"
    "HKII"   = "Học kỳ II"
    "HKI"    = "Học kỳ I"
    "GK"     = "Giữa kỳ"
}

$newEntriesAdded = $false

# Quet tat ca thu muc trong Test_Web
Write-Host ""
Write-Host "Dang quet thu muc Test_Web..." -ForegroundColor Cyan
$folders = Get-ChildItem -Path $TestWebDir -Directory | Where-Object { $_.Name -match '^\d{8}_[Dd]e_\d{1,2}_' }

foreach ($folder in $folders) {
    # Kiem tra thu muc 03_Outputs
    $outputDir = Join-Path $folder.FullName "03_Outputs"
    if (-not (Test-Path $outputDir)) { continue }

    $isBulk = $false
    # Parse ten thu muc
    if ($folder.Name -match '^\d{8}_[Dd]e_(\d{1,2})_([A-Za-z]+)_(\d+)$') {
        # Kieu 1: 20260501_de_11_HKII_05
        $lop = $Matches[1]
        $dangRaw = $Matches[2].ToUpper()
        $soDe = $Matches[3]
        $isBulk = $false
    }
    elseif ($folder.Name -match '^\d{8}_[Dd]e_(\d{1,2})_([A-Za-z]+)$') {
        # Kieu 2 (Bulk): 20260501_De_12_HKII
        $lop = $Matches[1]
        $dangRaw = $Matches[2].ToUpper()
        $isBulk = $true
    }
    else {
        Write-Host " Khong doc duoc ten thu muc: $($folder.Name) -> Bo qua" -ForegroundColor DarkGray
        continue
    }

    # Tim cac file *.html phu hop (De_XX.html hoac *_Unified*.html)
    $htmlFiles = Get-ChildItem -Path $outputDir -Filter "*.html" -File | Where-Object { $_.Name -match '.*_Unified.*\.html|De_\d+.*\.html' }
    if ($htmlFiles.Count -eq 0) { continue }

    if (-not $isBulk) {
        # Neu khong phai bulk, chi lay file moi nhat
        $htmlFiles = @($htmlFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
    }

    foreach ($htmlFile in $htmlFiles) {
        $currentSoDe = $soDe
        if ($isBulk) {
            # Trich xuat so de tu ten file, vi du: De_01.html
            if ($htmlFile.Name -match 'De_(\d+)') {
                $currentSoDe = $Matches[1]
            } else {
                continue
            }
        }

        # Tao ten file ngan gon cho Kho De Goc
        $shortName = "${lop}_${dangRaw}_${currentSoDe}.html"

        # Kiem tra: De nay da co trong CSV chua?
        $alreadyInCsv = $existingFiles -contains $shortName

        $khoDestPath = Join-Path $KhoDeGoc $shortName

        if ($alreadyInCsv) {
            # Da co trong CSV -> Kiem tra xem file nguon co moi hon khong
            if (Test-Path $khoDestPath) {
                $sourceTime = $htmlFile.LastWriteTime
                $destTime = (Get-Item $khoDestPath).LastWriteTime
                if ($sourceTime -gt $destTime) {
                    Copy-Item -Path $htmlFile.FullName -Destination $khoDestPath -Force
                    Write-Host " CAP NHAT: $shortName (file nguon moi hon)" -ForegroundColor Yellow
                }
                else {
                    Write-Host " Da co, khong thay doi: $shortName" -ForegroundColor DarkGray
                }
            }
            else {
                # File bi mat trong Kho -> Copy lai
                Copy-Item -Path $htmlFile.FullName -Destination $khoDestPath -Force
                Write-Host " KHOI PHUC: $shortName (file bi mat trong Kho)" -ForegroundColor Yellow
            }
        }
        else {
            # Hoan toan moi -> Copy va them vao CSV
            Copy-Item -Path $htmlFile.FullName -Destination $khoDestPath -Force

            $maxIdNum++
            $newId = "de_{0:D2}" -f $maxIdNum

            $dangVal = "hk"
            if ($dangMap.ContainsKey($dangRaw)) { $dangVal = $dangMap[$dangRaw] }

            $dangDisplay = $dangRaw
            if ($dangDisplayMap.ContainsKey($dangRaw)) { $dangDisplay = $dangDisplayMap[$dangRaw] }

            # Dem so cau tu file HTML (dem so slide)
            $htmlRaw = Get-Content $htmlFile.FullName -Raw -Encoding UTF8
            $slideCount = ([regex]::Matches($htmlRaw, 'class="slide"')).Count
            # Tru 2 (slide title va slide ket qua)
            $soCau = [Math]::Max($slideCount - 2, 0)

            $newLine = "$newId,Đề $currentSoDe - $dangDisplay,$lop,$dangVal,$soCau,90,$shortName,Hien,"
            Add-Content -Path $CsvPath -Value $newLine -Encoding UTF8
            $newEntriesAdded = $true
            $existingFiles += $shortName

            Write-Host " MOI: $shortName -> $newId (Lop $lop, $dangDisplay, $soCau cau)" -ForegroundColor Green
        }
    }
}

# Reload CSV sau khi da them dong moi
if ($newEntriesAdded) {
    Write-Host ""
    Write-Host "Da tu dong them de moi vao CSV!" -ForegroundColor Green
}
$csvData = Import-Csv $CsvPath -Encoding UTF8

# ============== PHASE 1: BUILD ==============
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  BUILD" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "1. Don dep thu muc 'de'..." -ForegroundColor Cyan
if (Test-Path $DestDeDir) {
    Remove-Item -Path "$DestDeDir\*" -Recurse -Force
}
else {
    New-Item -ItemType Directory -Path $DestDeDir -Force | Out-Null
}

$examsJsonArr = @()

Write-Host "2. Xu ly va copy de thi..." -ForegroundColor Cyan
foreach ($row in $csvData) {
    if ($row.Trang_Thai -ne "Hien") {
        Write-Host " Bo qua (AN): $($row.Ten_De)" -ForegroundColor DarkGray
        continue
    }

    $sourcePath = Join-Path $KhoDeGoc $row.File_Goc
    if (-not (Test-Path $sourcePath)) {
        Write-Host " LOI: Khong tim thay file $($row.File_Goc)" -ForegroundColor Red
        continue
    }

    $destFileName = ""
    $hasPassword = "false"
    $fileVal = "null"

    if ([string]::IsNullOrWhiteSpace($row.Mat_Khau)) {
        $destFileName = "$($row.ID).html"
        $fileVal = "'de/$destFileName'"
        Write-Host " OK: $($row.Ten_De) -> $destFileName" -ForegroundColor Green
    }
    else {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($row.Mat_Khau)
        $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        $hashString = [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
        $destFileName = "de_$hashString.html"
        $hasPassword = "true"
        Write-Host " OK (MAT KHAU): $($row.Ten_De) -> Ma hoa" -ForegroundColor Yellow
    }

    $destPath = Join-Path $DestDeDir $destFileName
    Copy-Item -Path $sourcePath -Destination $destPath -Force

    # Map icon
    $icon = [char]0x222B  # integral sign
    $iconStyle = ""
    if ($row.Lop -eq "11") {
        $icon = [char]0x03C0  # pi
        $iconStyle = "blue"
    }
    elseif ($row.Lop -eq "10") {
        $icon = [char]0x0394  # delta
        $iconStyle = "blue"
    }
    elseif ($row.Dang -eq "hk") {
        $icon = [char]0x03A3  # sigma
        $iconStyle = "orange"
    }

    # Bóc tách số đề để làm icon
    if ($row.Ten_De -match '(\d{1,2})') {
        $icon = $Matches[1]
    }

    $jsonObj = @"
  {
    id: '$($row.ID)',
    file: $fileVal,
    hasPassword: $hasPassword,
    title: '$($row.Ten_De)',
    grade: '$($row.Lop)',
    type: '$($row.Dang)',
    questions: $($row.So_Cau),
    duration: $($row.Thoi_Gian),
    icon: '$icon',
    iconStyle: '$iconStyle'
  }
"@
    $examsJsonArr += $jsonObj
}

Write-Host "3. Cap nhat index.html..." -ForegroundColor Cyan
$examsJsonStr = $examsJsonArr -join ",`n"
$htmlContent = Get-Content $HtmlPath -Raw -Encoding UTF8
$pattern = "(?s)const EXAMS = \[.*?\];"
$replacement = "const EXAMS = [`n$examsJsonStr`n];"
$newHtmlContent = $htmlContent -replace $pattern, $replacement
Set-Content -Path $HtmlPath -Value $newHtmlContent -Encoding UTF8

# ============== PHASE 2: GITHUB PUSH ==============
Write-Host ""
Write-Host "4. Dong bo len GitHub..." -ForegroundColor Cyan
if (-not (Test-Path ".git")) {
    Write-Host " Khoi tao Git..." -ForegroundColor DarkGray
    git init
    git branch -M main
}

git add .
git commit -m "Auto-sync Playlist Hub $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

$remote = git remote -v
if (-not $remote) {
    Write-Host " CHUA CAU HINH GITHUB. Vui long them remote origin." -ForegroundColor Red
}
else {
    Write-Host " Dang day len GitHub..." -ForegroundColor Yellow
    git push -u origin main
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "  HOAN TAT! DA DAY LEN GITHUB THANH CONG" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
}

Write-Host ""
