@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   Certificate Installer - Root Trust Store
echo ============================================
echo.
echo  WARNING: This script installs certificates
echo  into your Trusted Root Certification
echo  Authorities store.
echo.
echo  This is intended for custom self-signed
echo  certificates from TRUSTED sources only.
echo.
echo  *** INSTALLING UNKNOWN CERTIFICATES IS ***
echo  ***       EXTREMELY DANGEROUS!         ***
echo.
echo  A malicious root certificate can allow
echo  attackers to intercept ALL your encrypted
echo  traffic, including passwords, banking,
echo  and personal data.
echo.
echo  Only proceed if you know and trust the
echo  source of these certificates!
echo ============================================
echo.
set /p "proceed=Do you want to continue? (Y/N): "
if /i not "%proceed%"=="Y" (
    echo Aborted.
    pause
    exit /b
)
echo.

echo Scanning for certificate and key files...
echo.

set "found=0"
set "certcount=0"
set "keycount=0"

for %%F in (*.cer *.crt *.pem *.der *.key *.p12 *.pfx) do (
    set "found=1"
    echo --------------------------------------------
    echo File: %%F
    echo --------------------------------------------

    REM Create temp PowerShell script for reliable execution
    (
        echo $file = '%%F'
        echo $ext = [System.IO.Path]::GetExtension^($file^).ToLower^(^)
        echo $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        echo.
        echo # Check for private key patterns
        echo $isKey = $false
        echo if ^($ext -eq '.key'^) { $isKey = $true }
        echo elseif ^($content -match '-----BEGIN ^(RSA ^|EC ^|ENCRYPTED ^|^)PRIVATE KEY-----'^) { $isKey = $true }
        echo elseif ^($content -match '-----BEGIN OPENSSH PRIVATE KEY-----'^) { $isKey = $true }
        echo.
        echo if ^($isKey^) {
        echo     Write-Host '[PRIVATE KEY] - Skipping ^(not a certificate^)' -ForegroundColor Yellow
        echo     Write-Host 'Type: Private Key file'
        echo     exit 1
        echo }
        echo.
        echo # Check for PKCS#12/PFX files
        echo if ^($ext -eq '.p12' -or $ext -eq '.pfx'^) {
        echo     Write-Host '[PKCS#12/PFX] - Contains certificate + private key bundle' -ForegroundColor Yellow
        echo     Write-Host 'Note: Use certutil or MMC to import PFX files with private keys'
        echo     exit 2
        echo }
        echo.
        echo # Try to load as certificate
        echo try {
        echo     $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2^($file^)
        echo     Write-Host '[CERTIFICATE]' -ForegroundColor Green
        echo     Write-Host 'Subject ^(CN^):' $cert.Subject
        echo     Write-Host 'Issuer:' $cert.Issuer
        echo     Write-Host 'Valid From:' $cert.NotBefore
        echo     Write-Host 'Valid To:' $cert.NotAfter
        echo     Write-Host 'Thumbprint:' $cert.Thumbprint
        echo     $san = $cert.Extensions ^| Where-Object { $_.Oid.FriendlyName -eq 'Subject Alternative Name' }
        echo     if ^($san^) { Write-Host 'SANs:' $san.Format^(1^) } else { Write-Host 'SANs: ^(none^)' }
        echo     exit 0
        echo } catch {
        echo     Write-Host '[UNKNOWN/INVALID] - Could not parse as certificate' -ForegroundColor Red
        echo     Write-Host 'Error:' $_.Exception.Message
        echo     exit 3
        echo }
    ) > "%TEMP%\certcheck.ps1"

    powershell -ExecutionPolicy Bypass -File "%TEMP%\certcheck.ps1"
    set "exitcode=!errorlevel!"

    echo.

    REM Only prompt for installation if it's a valid certificate (exit code 0)
    if "!exitcode!"=="0" (
        set /p "confirm=Install this certificate to Trusted Root store? (Y/N): "

        if /i "!confirm!"=="Y" (
            echo Installing %%F...
            powershell -Command "Import-Certificate -FilePath '%%F' -CertStoreLocation Cert:\CurrentUser\Root" >nul 2>&1
            if !errorlevel! equ 0 (
                echo [SUCCESS] Certificate installed.
                set /a "certcount+=1"
            ) else (
                echo [ERROR] Failed to install certificate. Try running as Administrator.
            )
        ) else (
            echo Skipped %%F
        )
    ) else if "!exitcode!"=="1" (
        set /a "keycount+=1"
        echo [Skipped - Private key]
    ) else if "!exitcode!"=="2" (
        echo [Skipped - Use different tool for PFX import]
    ) else (
        echo [Skipped - Invalid or unrecognized file]
    )
    echo.
)

REM Cleanup temp file
del "%TEMP%\certcheck.ps1" 2>nul

if "!found!"=="0" (
    echo No certificate or key files found in current directory.
    echo Supported extensions: .cer, .crt, .pem, .der, .key, .p12, .pfx
)

echo ============================================
echo Summary:
echo   Certificates installed: !certcount!
echo   Private keys found (skipped): !keycount!
echo ============================================
echo.
echo Done.
pause
