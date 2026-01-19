# 🚀 YENİ MÜŞTERİ KURULUM REHBERİ

**Tahmini Süre**: 30 dakika
**Zorluk**: Kolay

---

## 📋 KURULUMDAN ÖNCE HAZIRLIK

### Müşteriden İstenmesi Gerekenler:

- [ ] **ERP Veritabanı Bilgileri**
  - IP adresi/hostname
  - Port numarası
  - Veritabanı adı
  - Kullanıcı adı ve şifre (salt-okunur yeterli)

- [ ] **ERP Tipi** (Workcube, Odoo, SAP, LOGO, Mikro, vs.)

- [ ] **Rapor İhtiyaçları**
  - Satış raporları mı?
  - Üretim takibi mi?
  - Andon ekranı gerekiyor mu?

- [ ] **Sunucu/Bilgisayar Erişimi**
  - Docker kurulabilecek bir Windows/Linux makine
  - Minimum 8GB RAM
  - 20GB boş disk alanı

---

## ⚡ HIZLI KURULUM (Önerilen)

### Adım 1: Kurulum Scriptini Çalıştırın (5 dakika)

```bash
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi

# Tek komutla kurulum
kur.bat ABC_Firma
```

**Script şunları yapar:**
1. Yeni klasör oluşturur: `ABC_Firma/`
2. Gerekli dosyaları kopyalar
3. Rastgele güvenlik anahtarı üretir
4. .env dosyasını açar (siz düzenlersiniz)
5. Docker'ı başlatır

### Adım 2: .env Dosyasını Düzenleyin (5 dakika)

Script otomatik olarak `notepad .env` açacak. Şu satırları doldurun:

```ini
# === MÜŞTERİ BİLGİLERİ ===
MUSTERI_ADI=ABC_Firma                   # ← Script zaten yazmış olacak
DOMAIN=analiz.abcfirma.com              # ← Opsiyonel (subdomain varsa)

# === ERP VERİTABANI BAĞLANTISI ===
ERP_DB_TYPE=mssql                       # mssql, postgresql, oracle
ERP_DB_HOST=192.168.1.50                # ← DEĞİŞTİRİN
ERP_DB_PORT=1433
ERP_DB_NAME=LOGO_ABC                    # ← DEĞİŞTİRİN
ERP_DB_USER=raporlama                   # ← DEĞİŞTİRİN
ERP_DB_PASSWORD=gizli_sifre             # ← DEĞİŞTİRİN

# === SMTP (Opsiyonel - Zamanlanmış raporlar için) ===
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=

# === GÜVENLİK (Script otomatik oluşturdu) ===
SECRET_KEY=...                          # ← Otomatik oluşturuldu, DOKUNMAYIN
SUPERSET_ADMIN_PASS=admin123            # ← İsterseniz değiştirin
```

Kaydet ve kapat.

### Adım 3: Docker'ı Başlatın (2 dakika)

Script otomatik olarak soracak: **".env dosyasını düzenlediniz mi? (E/H)"**

`E` deyin. Docker otomatik başlayacak.

```bash
# Manuel başlatmak isterseniz:
cd ABC_Firma
docker-compose up -d
```

### Adım 4: Superset'in Hazır Olmasını Bekleyin (1-2 dakika)

```bash
docker-compose logs -f superset
```

**"Superset is ready"** görünce `CTRL+C` yapın.

### Adım 5: İlk Giriş (1 dakika)

Tarayıcıdan: **http://localhost:8088** (veya sunucu IP'si)

- **Kullanıcı**: `admin`
- **Şifre**: `.env` dosyasındaki `SUPERSET_ADMIN_PASS` (varsayılan: `admin123`)

---

## 📊 İLK DASHBOARD OLUŞTURMA (15 dakika)

### 1. ERP Verisini ClickHouse'a Yükleyin

İki seçenek var:

#### **Seçenek A: Python Script ile (Hızlı Test)**

```bash
cd ABC_Firma

# Script'i çalıştırın
python scripts/erp_to_clickhouse.py
```

Bu script:
- ERP'den son 90 günün satışlarını çeker
- ClickHouse'a `erp_analytics.satislar` tablosuna yazar
- 30 saniyede biter

#### **Seçenek B: Superset SQL Lab'dan Manuel**

1. Superset → **SQL Lab** → **SQL Editor**
2. Önce veritabanı bağlantısı ekleyin:
   - Settings → Database Connections → **+Database**
   - **SUPPORTED DATABASES** → ClickHouse
   - **SQLALCHEMY URI**: `clickhouse://localhost:8123/erp_analytics`
   - **Test Connection** → **Connect**

3. SQL Lab'da sorgu yazın:

```sql
-- ClickHouse'da tablo oluştur
CREATE TABLE IF NOT EXISTS erp_analytics.satislar (
    fatura_id String,
    fatura_tarihi Date,
    urun_kodu String,
    urun_adi String,
    miktar Float64,
    tutar Float64,
    musteri_adi String
) ENGINE = MergeTree()
ORDER BY fatura_tarihi;

-- ERP'den veri çekmek için Superset'in "Database" özelliğini kullanın
-- (Bu adımda dbt kullanmıyorsanız, Python scripti önerilir)
```

### 2. Dataset Oluşturun

1. **Datasets** → **+Dataset**
2. **Database**: `ClickHouse`
3. **Schema**: `erp_analytics`
4. **Table**: `satislar`
5. **Create Dataset and Create Chart**

### 3. İlk Grafiği Yapın

1. **Visualization Type**: `Time-series Line Chart`
2. **Time Column**: `fatura_tarihi`
3. **Metrics**: `SUM(tutar)`
4. **Group By**: `musteri_adi` (opsiyonel)
5. **Update Chart** → **Save**

### 4. Dashboard Oluşturun

1. **Dashboards** → **+Dashboard**
2. **Title**: `ABC Firma - Satış Raporu`
3. Grafiğinizi sürükleyip bırakın
4. **Save**

---

## 🎯 PERFORMANS OPTİMİZASYONU (Opsiyonel ama Önerilen)

### Redis Cache'i Aktifleştirin

**Dashboard → Settings → Advanced**
- **CACHE TIMEOUT**: `86400` (24 saat)
- **REFRESH INTERVAL**: `300` (5 dakika)

Bu ayarlar sayesinde dashboard **saniyeler içinde** açılır!

### ClickHouse İndeksleme

```sql
-- Sık sorgulanan kolonlara göre sıralama
ALTER TABLE erp_analytics.satislar
ORDER BY (fatura_tarihi, urun_kodu, musteri_adi);
```

---

## 🖥 ANDON EKRANI KURULUMU (Fabrika Ekranları)

### 1. Dashboard'u Tam Ekran Moduna Alın

Dashboard URL'sinin sonuna `?standalone=true` ekleyin:

```
http://192.168.1.100:8088/superset/dashboard/1/?standalone=true
```

### 2. Otomatik Yenileme Ayarlayın

**Dashboard → Settings**
- **AUTO REFRESH**: `10 seconds`

### 3. Chrome Kiosk Modunda Açın (Fabrika TV'si için)

```bash
# Windows
"C:\Program Files\Google\Chrome\Application\chrome.exe" --kiosk --disable-gpu --app="http://192.168.1.100:8088/superset/dashboard/1/?standalone=true"

# Linux
chromium-browser --kiosk --app="http://192.168.1.100:8088/superset/dashboard/1/?standalone=true"
```

---

## 🔐 GÜVENLİK AYARLARI (Üretim Ortamı İçin)

### 1. Şifreleri Değiştirin

```bash
# .env dosyasında
SUPERSET_ADMIN_PASS=cok_guclu_bir_sifre_123!
```

Sonra Superset'i yeniden başlatın:
```bash
docker-compose restart superset
```

### 2. Satır Bazlı Güvenlik (RLS)

Örnek: Her şube müdürü sadece kendi şubesini görsün.

1. **Settings → Row Level Security → +**
2. **Table**: `satislar`
3. **Filter**: `musteri_kodu = '{{ current_username() }}'`
4. **Roles**: Şube müdürü rolü
5. **Save**

---

## 🐛 SORUN GİDERME

### ❌ "Database connection failed"

**Sebep**: ClickHouse henüz hazır değil.

**Çözüm**:
```bash
docker-compose logs clickhouse
# "Ready for connections" mesajını bekleyin
```

### ❌ "Superset yavaş"

**Sebep**: Redis cache kapalı.

**Çözüm**: `superset_config.py` içinde cache ayarlarını kontrol edin.

### ❌ "ERP'den veri gelmiyor"

**Sebep**: Firewall veya kullanıcı izni.

**Çözüm**:
```bash
# ERP veritabanına erişimi test edin
telnet 192.168.1.50 1433
```

---

## ✅ KURULUM TAMAMLANDI CHECKLİSTİ

- [ ] Docker servisleri çalışıyor (`docker-compose ps` ile kontrol)
- [ ] Superset'e giriş yapabiliyorum (http://localhost:8088)
- [ ] ClickHouse'a veri yükledim (`erp_analytics.satislar` tablosu var)
- [ ] İlk dataset'i oluşturdum
- [ ] İlk dashboard'u yaptım
- [ ] Cache ayarlarını yaptım (hız için)
- [ ] Müşteriye demo gösterdim ✅

---

## 📞 DESTEK

**Sorunlarla karşılaşırsanız:**

1. **Logları kontrol edin**:
   ```bash
   docker-compose logs --tail=50 superset
   docker-compose logs --tail=50 clickhouse
   ```

2. **Docker'ı yeniden başlatın**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

3. **Verileri koruyarak temiz kurulum**:
   ```bash
   docker-compose down
   docker-compose up -d --force-recreate
   ```

---

## 🚀 GELİŞMİŞ ÖZELLİKLER (Sonradan Eklenebilir)

### Airflow Eklemek (Otomatik Veri Güncellemesi)

```bash
# docker-compose.advanced.yml dosyasını kullan
docker-compose -f docker-compose.yml -f docker-compose.advanced.yml up -d
```

### dbt Eklemek (Karmaşık Veri Dönüşümleri)

```bash
# dbt konteynerini başlat
docker-compose exec dbt bash

# Modelleri çalıştır
dbt run
```

---

**Kurulum süresi**: ~30 dakika
**Tekrar kurulum süresi**: ~10 dakika (artık alışkınsınız!)

İyi çalışmalar! 🎉
