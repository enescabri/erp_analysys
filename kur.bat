@echo off
setlocal EnableDelayedExpansion

REM ================================================================
REM ERP ANALİZ PAKETİ - TEK KOMUTLA KURULUM
REM ================================================================
REM Kullanım: kur.bat ABC_Firma
REM ================================================================

SET MUSTERI_ADI=%~1

IF "%MUSTERI_ADI%"=="" (
    echo.
    echo [HATA] Musteri adi belirtilmedi!
    echo.
    echo Kullanim:
    echo    kur.bat ABC_Firma
    echo.
    exit /b 1
)

echo.
echo ================================================================
echo YENİ MUSTERİ KURULUMU: %MUSTERI_ADI%
echo ================================================================
echo.

REM Ana klasörden müşteri klasörü oluştur
IF NOT EXIST "%MUSTERI_ADI%" (
    echo [1/7] Klasor olusturuluyor...
    mkdir "%MUSTERI_ADI%"
) ELSE (
    echo [1/7] Klasor zaten mevcut: %MUSTERI_ADI%
)

REM Gerekli dosyaları kopyala
echo [2/7] Dosyalar kopyalaniyor...

IF EXIST "docker-compose.minimal.yml" (
    copy /Y "docker-compose.minimal.yml" "%MUSTERI_ADI%\docker-compose.yml" >nul
) ELSE (
    echo [HATA] docker-compose.minimal.yml bulunamadi!
    exit /b 1
)

copy /Y "superset_config.py" "%MUSTERI_ADI%\" >nul 2>&1
copy /Y ".env" "%MUSTERI_ADI%\" >nul 2>&1
copy /Y ".gitignore" "%MUSTERI_ADI%\" >nul 2>&1
copy /Y "ofelia.ini" "%MUSTERI_ADI%\" >nul 2>&1

REM dbt klasörlerini kopyala
echo [3/7] dbt klasorleri kopyalaniyor...

IF EXIST "dbt_project" (
    xcopy /E /I /Y /Q "dbt_project" "%MUSTERI_ADI%\dbt_project" >nul
) ELSE (
    echo [UYARI] dbt_project klasoru bulunamadi!
)

IF EXIST "dbt_profiles" (
    xcopy /E /I /Y /Q "dbt_profiles" "%MUSTERI_ADI%\dbt_profiles" >nul
) ELSE (
    echo [UYARI] dbt_profiles klasoru bulunamadi!
)

REM logs klasörü oluştur
mkdir "%MUSTERI_ADI%\logs" 2>nul

REM .env dosyasını düzenle
echo [4/7] Yapilandirma dosyasi hazirlaniyor...
cd "%MUSTERI_ADI%"

REM Müşteri adını .env dosyasına yaz
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content .env -Raw) -replace 'MUSTERI_ADI=Ornek_Firma', 'MUSTERI_ADI=%MUSTERI_ADI%' | Set-Content .env -NoNewline"

REM Rastgele SECRET_KEY oluştur
echo [5/7] Guvenlik anahtari olusturuluyor...
FOR /F "delims=" %%i IN ('powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))"') DO SET SECRET_KEY=%%i

powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content .env -Raw) -replace 'SECRET_KEY=DEGISTIR[^\r\n]*', 'SECRET_KEY=!SECRET_KEY!' | Set-Content .env -NoNewline"

echo.
echo ================================================================
echo ONEMLI: .env DOSYASINI DUZENLEYIN!
echo ================================================================
echo.
echo Asagidaki bilgileri doldurun:
echo   - ERP_DB_HOST     (ERP veritabani adresi)
echo   - ERP_DB_NAME     (ERP veritabani adi)
echo   - ERP_DB_USER     (Kullanici adi)
echo   - ERP_DB_PASSWORD (Sifre)
echo.
echo Duzenlemek icin: notepad .env
echo.

REM .env dosyasını aç
start /wait notepad .env

echo.
SET /P DEVAM=".env dosyasini duzenlediniz mi? (E/H): "

IF /I NOT "!DEVAM!"=="E" (
    echo.
    echo [BILGI] Kurulum duraklatildi.
    echo.
    echo .env dosyasini duzenledikten sonra:
    echo    cd %MUSTERI_ADI%
    echo    docker-compose up -d
    echo.
    cd ..
    exit /b 0
)

echo.
echo [6/7] Docker servisleri baslatiliyor...
docker-compose up -d

IF ERRORLEVEL 1 (
    echo.
    echo [HATA] Docker baslatilirken hata olustu!
    echo Lutfen docker-compose.yml dosyasini kontrol edin.
    echo.
    cd ..
    exit /b 1
)

echo.
echo [7/7] Superset'in hazir olmasi bekleniyor (30-60 saniye)...
timeout /t 5 /nobreak >nul

echo.
echo ================================================================
echo KURULUM TAMAMLANDI!
echo ================================================================
echo.
echo Erisim Adresleri:
echo    Superset: http://localhost:8088
echo    Kullanici: admin
echo    Sifre: admin123 (.env'den degistirilebilir)
echo.
echo Sonraki Adimlar:
echo    1. Tarayicidan Superset'e giris yapin
echo    2. Database baglantisi ekleyin (ClickHouse)
echo    3. Ilk dashboard'unuzu olusturun
echo.
echo Loglari gormek icin:
echo    docker-compose logs -f superset
echo.
echo Durdurmak icin:
echo    docker-compose down
echo.
echo ================================================================
echo.

cd ..
