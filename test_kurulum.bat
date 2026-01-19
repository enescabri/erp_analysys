@echo off
REM ================================================================
REM KURULUM TESTİ - Gerçek müşteri klasörü oluşturmadan test eder
REM ================================================================

echo.
echo ================================================================
echo KURULUM TESTI BASLIYOR
echo ================================================================
echo.

REM 1. Gerekli dosyaların varlığını kontrol et
echo [1/5] Gerekli dosyalar kontrol ediliyor...

SET HATALAR=0

IF NOT EXIST "docker-compose.minimal.yml" (
    echo   [HATA] docker-compose.minimal.yml bulunamadi!
    SET /A HATALAR+=1
) ELSE (
    echo   [OK] docker-compose.minimal.yml
)

IF NOT EXIST "superset_config.py" (
    echo   [HATA] superset_config.py bulunamadi!
    SET /A HATALAR+=1
) ELSE (
    echo   [OK] superset_config.py
)

IF NOT EXIST ".env" (
    echo   [HATA] .env bulunamadi!
    SET /A HATALAR+=1
) ELSE (
    echo   [OK] .env
)

IF NOT EXIST "ofelia.ini" (
    echo   [HATA] ofelia.ini bulunamadi!
    SET /A HATALAR+=1
) ELSE (
    echo   [OK] ofelia.ini
)

IF NOT EXIST "dbt_project" (
    echo   [UYARI] dbt_project klasoru bulunamadi!
) ELSE (
    echo   [OK] dbt_project/
)

IF NOT EXIST "dbt_profiles" (
    echo   [UYARI] dbt_profiles klasoru bulunamadi!
) ELSE (
    echo   [OK] dbt_profiles/
)

echo.
echo [2/5] PowerShell komutu test ediliyor...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '[OK] PowerShell calisiyor'"

echo.
echo [3/5] SECRET_KEY uretme testi...
FOR /F "delims=" %%i IN ('powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))"') DO SET TEST_KEY=%%i

IF DEFINED TEST_KEY (
    echo   [OK] SECRET_KEY uretildi: %TEST_KEY:~0,20%...
) ELSE (
    echo   [HATA] SECRET_KEY uretilemedi!
    SET /A HATALAR+=1
)

echo.
echo [4/5] Docker kontrol ediliyor...
docker --version >nul 2>&1
IF ERRORLEVEL 1 (
    echo   [UYARI] Docker bulunamadi veya calismiyour!
    echo   Lutfen Docker Desktop'i baslatın.
) ELSE (
    FOR /F "tokens=*" %%i IN ('docker --version') DO echo   [OK] %%i
)

docker-compose --version >nul 2>&1
IF ERRORLEVEL 1 (
    echo   [UYARI] docker-compose bulunamadi!
) ELSE (
    FOR /F "tokens=*" %%i IN ('docker-compose --version') DO echo   [OK] %%i
)

echo.
echo [5/5] Test klasoru olusturma...
IF EXIST "TEST_KURULUM_DENEME" (
    echo   Eski test klasoru siliniyor...
    rmdir /s /q "TEST_KURULUM_DENEME"
)

mkdir "TEST_KURULUM_DENEME"
copy /Y "docker-compose.minimal.yml" "TEST_KURULUM_DENEME\docker-compose.yml" >nul 2>&1

IF EXIST "TEST_KURULUM_DENEME\docker-compose.yml" (
    echo   [OK] Test klasor basariyla olusturuldu
    rmdir /s /q "TEST_KURULUM_DENEME"
) ELSE (
    echo   [HATA] Dosya kopyalama basarisiz!
    SET /A HATALAR+=1
)

echo.
echo ================================================================
echo TEST SONUCU
echo ================================================================

IF %HATALAR%==0 (
    echo.
    echo   [BASARILI] Tum kontroller gecti!
    echo.
    echo   Kurulumu baslatmak icin:
    echo      kur.bat MUSTERI_ADI
    echo.
) ELSE (
    echo.
    echo   [BASARISIZ] %HATALAR% adet hata bulundu!
    echo   Lutfen hatalari duzeltin ve tekrar deneyin.
    echo.
)

echo ================================================================
echo.
