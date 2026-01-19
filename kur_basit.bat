@echo off
REM ================================================================
REM BASİT KURULUM - Hata ayıklama olmadan minimum adımlar
REM Kullanım: kur_basit.bat ABC_Firma
REM ================================================================

SET MUSTERI=%1

IF "%MUSTERI%"=="" (
    echo.
    echo Kullanim: kur_basit.bat MUSTERI_ADI
    echo.
    exit /b 1
)

echo.
echo ================================================================
echo BASIT KURULUM: %MUSTERI%
echo ================================================================
echo.

REM 1. Klasör oluştur
echo [1/4] Klasor olusturuluyor...
IF NOT EXIST "%MUSTERI%" mkdir "%MUSTERI%"

REM 2. Dosyaları kopyala
echo [2/4] Dosyalar kopyalaniyor...
copy /Y docker-compose.minimal.yml "%MUSTERI%\docker-compose.yml" >nul
copy /Y superset_config.py "%MUSTERI%\" >nul
copy /Y .env "%MUSTERI%\" >nul
copy /Y ofelia.ini "%MUSTERI%\" >nul

REM 3. dbt kopyala
echo [3/4] dbt kopyalaniyor...
IF EXIST dbt_project xcopy /E /I /Y /Q dbt_project "%MUSTERI%\dbt_project" >nul
IF EXIST dbt_profiles xcopy /E /I /Y /Q dbt_profiles "%MUSTERI%\dbt_profiles" >nul
mkdir "%MUSTERI%\logs" 2>nul

REM 4. .env düzenle
cd "%MUSTERI%"

echo.
echo ================================================================
echo ONEMLI: .env dosyasini acin ve ERP bilgilerini girin!
echo ================================================================
echo.
pause

notepad .env

echo.
echo [4/4] Docker baslatiliyor...
docker-compose up -d

echo.
echo ================================================================
echo TAMAM! http://localhost:8088 (admin / admin123)
echo ================================================================
echo.

cd ..
