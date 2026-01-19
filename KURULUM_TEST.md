# ✅ KURULUM TESTİ - BAT DOSYASI SORUN GİDERME

## 🔍 Düzeltilen Sorunlar

### ❌ Eski Sorunlar:
1. **Türkçe karakter sorunu** → ASCII karakterlere çevrildi
2. **PowerShell execution policy** → `-ExecutionPolicy Bypass` eklendi
3. **Delayed expansion** → `EnableDelayedExpansion` eklendi
4. **Hata kontrolü** → Her adımda kontrol eklendi
5. **Dosya varlık kontrolü** → `IF EXIST` kontrolleri eklendi

### ✅ Yeni Özellikler:
- Otomatik `.env` açma (`start /wait notepad .env`)
- Hata durumunda geri dönme
- Detaylı mesajlar
- `logs/` klasörü otomatik oluşturma

---

## 🧪 MANUEL TEST ADIMLARI

### Adım 1: Gerekli Dosyaları Kontrol Edin

PowerShell açın ve şu komutu çalıştırın:

```powershell
cd "D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi"

# Gerekli dosyalar
Get-ChildItem -Name docker-compose.minimal.yml
Get-ChildItem -Name superset_config.py
Get-ChildItem -Name .env
Get-ChildItem -Name ofelia.ini
Get-ChildItem -Name kur.bat

# Gerekli klasörler
Get-ChildItem -Directory -Name dbt_project
Get-ChildItem -Directory -Name dbt_profiles
```

**Beklenen Çıktı**: Tüm dosyalar listelenmeli

---

### Adım 2: Test Kurulum (Gerçek müşteri oluşturmadan)

```cmd
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi

REM Test için klasör oluştur
mkdir TEST_FIRMA_DENEME

REM Manuel kopyalama testi
copy docker-compose.minimal.yml TEST_FIRMA_DENEME\docker-compose.yml
copy superset_config.py TEST_FIRMA_DENEME\
copy .env TEST_FIRMA_DENEME\
copy ofelia.ini TEST_FIRMA_DENEME\

xcopy /E /I /Y dbt_project TEST_FIRMA_DENEME\dbt_project
xcopy /E /I /Y dbt_profiles TEST_FIRMA_DENEME\dbt_profiles

REM Kontrol
dir TEST_FIRMA_DENEME
```

**Beklenen Sonuç**: Tüm dosyalar kopyalanmalı

---

### Adım 3: SECRET_KEY Üretme Testi

```powershell
# PowerShell'de çalıştırın
[System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

**Beklenen Çıktı**: Base64 string (örn: `a7F3kL9mP2wR...`)

---

### Adım 4: kur.bat'ı Gerçek Test

```cmd
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi

kur.bat TEST_FIRMA
```

**Adımlar**:
1. Script çalışmaya başlar
2. Dosyalar kopyalanır
3. Notepad açılır (.env düzenlemek için)
4. `.env` içinde sadece `MUSTERI_ADI=TEST_FIRMA` değiştiğini kontrol edin
5. Kaydet ve kapat
6. "E" yazıp Enter basın

**Beklenen Sonuç**:
- `TEST_FIRMA/` klasörü oluşur
- Docker servisler başlar
- 2 dakika sonra http://localhost:8088 açılır

---

## 🐛 OLASI HATALAR VE ÇÖZÜMLER

### Hata 1: "docker-compose.minimal.yml bulunamadı"

**Sebep**: Yanlış klasörde çalıştırıyorsunuz

**Çözüm**:
```cmd
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi
dir docker-compose.minimal.yml
```

---

### Hata 2: "PowerShell execution policy" hatası

**Sebep**: PowerShell scriptleri engellenmiş

**Çözüm**: kur.bat zaten `-ExecutionPolicy Bypass` kullanıyor, sorun olmamalı. Olursa:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

### Hata 3: "xcopy geçersiz parametre"

**Sebep**: Kaynak klasör yok

**Çözüm**:
```cmd
# dbt klasörlerini kontrol edin
dir dbt_project /AD
dir dbt_profiles /AD
```

Yoksa manuel oluşturun:
```cmd
mkdir dbt_project\models
mkdir dbt_profiles
```

---

### Hata 4: "Docker baslatilirken hata olustu"

**Sebep**: Docker çalışmıyor veya `docker-compose.yml` hatalı

**Çözüm**:
```cmd
# Docker kontrol
docker --version
docker ps

# docker-compose kontrol
cd TEST_FIRMA
docker-compose config
```

---

## ✅ BAŞARILI KURULUM KONTROLÜ

Kurulum başarılıysa şunlar olmalı:

### 1. Klasör Yapısı:
```
TEST_FIRMA/
├── docker-compose.yml          ✓
├── superset_config.py          ✓
├── .env                        ✓
├── ofelia.ini                  ✓
├── dbt_project/                ✓
│   ├── dbt_project.yml
│   ├── models/
│   └── scripts/
├── dbt_profiles/               ✓
│   └── profiles.yml
├── logs/                       ✓
└── data/                       ✓ (Docker otomatik oluşturur)
```

### 2. Docker Servisler:
```cmd
cd TEST_FIRMA
docker-compose ps
```

**Beklenen Çıktı**:
```
NAME                      STATUS
TEST_FIRMA_clickhouse     Up
TEST_FIRMA_postgres       Up
TEST_FIRMA_redis          Up
TEST_FIRMA_dbt            Up
TEST_FIRMA_scheduler      Up
TEST_FIRMA_superset       Up
```

### 3. Superset Erişim:
- URL: http://localhost:8088
- Kullanıcı: `admin`
- Şifre: `admin123`

---

## 🚀 HIZLI FİKS SCRIPT'İ

Eğer kur.bat çalışmıyorsa, bu minimal scripti kullanın:

**kur_basit.bat**:
```batch
@echo off
SET MUSTERI=%1

IF "%MUSTERI%"=="" (
    echo Kullanim: kur_basit.bat MUSTERI_ADI
    exit /b 1
)

echo Klasor olusturuluyor: %MUSTERI%
mkdir %MUSTERI%

echo Dosyalar kopyalaniyor...
copy docker-compose.minimal.yml %MUSTERI%\docker-compose.yml
copy superset_config.py %MUSTERI%\
copy .env %MUSTERI%\
copy ofelia.ini %MUSTERI%\

xcopy /E /I /Y dbt_project %MUSTERI%\dbt_project
xcopy /E /I /Y dbt_profiles %MUSTERI%\dbt_profiles

mkdir %MUSTERI%\logs

cd %MUSTERI%

echo.
echo .env dosyasini aciyorum...
notepad .env

echo.
echo Docker baslatiliyor...
docker-compose up -d

echo.
echo Kurulum tamam! http://localhost:8088
cd ..
```

Kullanım:
```cmd
kur_basit.bat TEST_FIRMA
```

---

## 📞 DESTEK

Hala sorun yaşıyorsanız:

1. **Logları gönderin**:
   ```cmd
   kur.bat TEST_FIRMA > kurulum_log.txt 2>&1
   ```

2. **Dosya listesini gönderin**:
   ```cmd
   dir /s /b > dosya_listesi.txt
   ```

3. **Docker durumunu gönderin**:
   ```cmd
   docker ps -a > docker_durum.txt
   ```

---

**Güncellenme**: 2026-01-18
**Versiyon**: 3.0 (Ofelia + dbt dahil)
