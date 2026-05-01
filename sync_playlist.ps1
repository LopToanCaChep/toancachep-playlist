$ErrorActionPreference = "Stop"

$CsvPath = ".\quan_ly_de_thi.csv"
$SourceBaseDir = ".\01_Kho_De_Goc"
$DestDeDir = ".\de"
$HtmlPath = ".\index.html"

Write-Host "1. Dang doc file cau hinh CSV..." -ForegroundColor Cyan
if (-not (Test-Path $CsvPath)) {
    Write-Host "Khong tim thay file $CsvPath!" -ForegroundColor Red
    exit
}

# Đọc CSV
$csvData = Import-Csv $CsvPath -Encoding UTF8

Write-Host "2. Don dep thu muc 'de' cu..." -ForegroundColor Cyan
if (Test-Path $DestDeDir) {
    Remove-Item -Path "$DestDeDir\*" -Recurse -Force
} else {
    New-Item -ItemType Directory -Path $DestDeDir -Force | Out-Null
}

$examsJsonArr = @()

Write-Host "3. Bat dau xu ly va copy de thi..." -ForegroundColor Cyan
foreach ($row in $csvData) {
    if ($row.Trang_Thai -ne "Hien") {
        Write-Host " Bo qua: $($row.Ten_De) (Trang thai: $($row.Trang_Thai))" -ForegroundColor DarkGray
        continue
    }

    $sourcePath = Join-Path $SourceBaseDir $row.File_Goc
    if (-not (Test-Path $sourcePath)) {
        Write-Host " LOI: Khong tim thay file goc cho $($row.Ten_De) ($sourcePath)" -ForegroundColor Red
        continue
    }

    $destFileName = ""
    $hasPassword = "false"
    $fileVal = "null"

    if ([string]::IsNullOrWhiteSpace($row.Mat_Khau)) {
        # Không mật khẩu
        $destFileName = "$($row.ID).html"
        $fileVal = "'de/$destFileName'"
        Write-Host " Copy: $($row.Ten_De) -> $destFileName" -ForegroundColor Green
    } else {
        # Có mật khẩu -> Mã hóa SHA256 để bảo mật
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($row.Mat_Khau)
        $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        $hashString = [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
        
        $destFileName = "de_$hashString.html"
        $hasPassword = "true"
        Write-Host " Copy (CO MAT KHAU): $($row.Ten_De) -> Ten file da bi ma hoa" -ForegroundColor Yellow
    }

    $destPath = Join-Path $DestDeDir $destFileName
    Copy-Item -Path $sourcePath -Destination $destPath -Force

    # Map icon logic
    $icon = "∫"
    $iconStyle = ""
    if ($row.Lop -eq "11") { $icon = "π"; $iconStyle = "blue" }
    elseif ($row.Dang -eq "hk") { $icon = "Σ"; $iconStyle = "orange" }

    # Format JSON object string
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

Write-Host "4. Cap nhat giao dien Playlist Hub (index.html)..." -ForegroundColor Cyan
$examsJsonStr = $examsJsonArr -join ",`n"

$htmlContent = Get-Content $HtmlPath -Raw
# Dùng Regex để thay thế mảng EXAMS
$pattern = "(?s)const EXAMS = \[.*?\];"
$replacement = "const EXAMS = [`n$examsJsonStr`n];"
$newHtmlContent = $htmlContent -replace $pattern, $replacement

Write-Host "DA HOAN TAT DONG BO LOCAL!" -ForegroundColor Cyan

# Phân hệ đưa lên GitHub
Write-Host "5. Dong bo len GitHub..." -ForegroundColor Cyan
if (-not (Test-Path ".git")) {
    Write-Host " Chua khoi tao Git, dang khoi tao..." -ForegroundColor DarkGray
    git init
    git branch -M main
}

git add .
git commit -m "Auto-sync Playlist Hub $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

# Kiểm tra xem đã có remote origin chưa
$remote = git remote -v
if (-not $remote) {
    Write-Host " CHUA CAU HINH GITHUB REPO. Vui long them remote origin thu cong truoc." -ForegroundColor Red
} else {
    Write-Host " Dang day code len GitHub..." -ForegroundColor Yellow
    git push -u origin main
    Write-Host "DA DAY LEN GITHUB THANH CONG!" -ForegroundColor Green
}

