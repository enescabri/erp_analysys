# 📋 YENİ MÜŞTERİ KURULUM REHBERİ (ADIM ADIM)

**Son Güncelleme**: 2026-01-18 16:15
**Versiyon**: 3.2 (Ofelia + dbt + Şema Parametreleri)

---

## 🎯 HIZLI BAŞLANGIÇ TABLOSU

| # | ADIM | SÜRE | ZORUNLU | DOSYA |
|---|------|------|---------|-------|
| 1 | Kurulum Scriptini Çalıştır | 1 dk | ✅ | `kur.bat` |
| 2 | .env → ERP Bağlantısı | 3 dk | ✅ | `.env` satır 13-19 |
| 3 | .env → Şema Parametreleri | 2 dk | ✅ | `.env` satır 29-40 |
| 4 | .env → SQL Dosyası Seç | 1 dk | ✅ | `.env` satır 27 |
| 5 | SQL Sorgusunu Kontrol Et | 5 dk | ⚠️ | `queries/*.sql` |
| 6 | Docker Başlat | 2 dk | ✅ | Script otomatik |
| 7 | İlk Veri Yükleme (Test) | 3 dk | ✅ | Manuel komut |
| 8 | dbt Çalıştır | 2 dk | ✅ | Manuel komut |
| 9 | Superset Bağlantısı | 2 dk | ✅ | Web arayüzü |
| 10 | İlk Dashboard | 5 dk | ✅ | Web arayüzü |
| 11 | Ofelia Kontrol | 1 dk | ⚠️ | `docker logs` |

**TOPLAM**: ~27 dakika (ilk kurulum), ~15 dakika (deneyimli kullanıcı)

---

## 📝 DETAYLI ADIMLAR

### ✅ ADIM 1: KURULUM SCRİPTİNİ ÇALIŞTIR

#### Ne Yapıyor?
- Yeni müşteri klasörü oluşturur
- Tüm dosyaları kopyalar (docker-compose, .env, dbt, queries)
- Rastgele SECRET_KEY üretir
- .env dosyasını açar

#### Komutlar:
```cmd
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi
kur.bat ABC_MUSTERI
```

#### Alternatif (Basit):
```cmd
kur_basit.bat ABC_MUSTERI
```

#### Beklenen Çıktı:
```
================================================================
YENİ MUSTERİ KURULUMU: ABC_MUSTERI
================================================================

[1/7] Klasor olusturuluyor...
[2/7] Dosyalar kopyalaniyor...
[3/7] dbt klasorleri kopyalaniyor...
[4/7] Yapilandirma dosyasi hazirlaniyor...
[5/7] Guvenlik anahtari olusturuluyor...
```

#### Sorun Çözüm:
| Hata | Çözüm |
|------|-------|
| "docker-compose.minimal.yml bulunamadı" | Ana klasörde olduğunuzdan emin olun |
| PowerShell hatası | `Set-ExecutionPolicy RemoteSigned` çalıştırın |

---

### ✅ ADIM 2: .ENV → ERP BAĞLANTISI

#### Notepad Otomatik Açılacak
Script `.env` dosyasını otomatik açar. Şu satırları doldurun:

#### Doldurulacak Alanlar:

```ini
# === ERP VERİTABANI BAĞLANTISI ===
ERP_DB_TYPE=mssql                    # ← mssql, postgresql, oracle
ERP_DB_HOST=192.168.1.50             # ← Müşteriden alın
ERP_DB_PORT=1433                     # ← Varsayılan bırakılabilir
ERP_DB_NAME=WORKCUBE_ABC             # ← Veritabanı adı
ERP_DB_USER=raporlama                # ← Salt-okunur kullanıcı
ERP_DB_PASSWORD=abc123               # ← Şifre
```

#### Nereden Öğrenirsiniz?

| Parametre | Kaynak |
|-----------|--------|
| `ERP_DB_TYPE` | ERP tipi: Workcube/Odoo (PostgreSQL), LOGO (MSSQL) |
| `ERP_DB_HOST` | Müşteri IT departmanından |
| `ERP_DB_PORT` | Varsayılan: 1433 (MSSQL), 5432 (PostgreSQL), 1521 (Oracle) |
| `ERP_DB_NAME` | Müşteri IT'den veya ERP ekranından |
| `ERP_DB_USER` | Müşteri IT'den (salt-okunur yeterli!) |
| `ERP_DB_PASSWORD` | Müşteri IT'den |

#### Test (ERP bağlantısı doğru mu?):
```cmd
# MSSQL için
sqlcmd -S 192.168.1.50 -U raporlama -P abc123 -d WORKCUBE_ABC -Q "SELECT 1"

# PostgreSQL için
psql -h 192.168.1.50 -U raporlama -d odoo_abc -c "SELECT 1"
```

---

### ✅ ADIM 3: .ENV → ŞEMA PARAMETRELERİ

#### Sadece Workcube İçin Gerekli
Odoo/LOGO kullanıyorsanız bu adımı atlayın.

#### Şema İsimlerini Öğrenme:
ERP veritabanında şu sorguyu çalıştırın:

```sql
SELECT name FROM sys.schemas
WHERE name LIKE '%workcube%' OR name LIKE '%wc%'
ORDER BY name
```

#### Örnek Çıktı:
```
workcube_prod
workcube_prod_2026_1
workcube_prod_1
workcube_prod_product
```

#### .env'de Doldurun:

```ini
# === WORKCUBE ŞEMA PARAMETRELERİ ===
WC_BASE_SCHEMA=workcube_prod        # ← Ana şema adı
WC_PERIOD_YEAR=2026                 # ← Aktif dönem yılı
WC_COMPANY_ID=1                     # ← Şirket numarası
WC_PRODUCT_SCHEMA=workcube_prod_product  # ← Ürün şeması
```

#### Şema Desen Tablosu:

| Parametre | Kullanıldığı Yer | Oluşan Değer |
|-----------|------------------|--------------|
| `WC_BASE_SCHEMA` | `{{dsn}}` | `workcube_prod` |
| `WC_BASE_SCHEMA` + `WC_PERIOD_YEAR` + `WC_COMPANY_ID` | `{{dsn2}}` | `workcube_prod_2026_1` |
| `WC_BASE_SCHEMA` + `WC_COMPANY_ID` | `{{dsn3}}` | `workcube_prod_1` |
| `WC_PRODUCT_SCHEMA` | `{{dsn_product}}` | `workcube_prod_product` |

---

### ✅ ADIM 4: .ENV → SQL DOSYASI SEÇ

#### Hangi SQL Dosyası?

```ini
SQL_QUERY_FILE=workcube_satislar.sql  # ← Değiştirin
```

#### Seçenekler:

| ERP Tipi | SQL Dosyası | Açıklama |
|----------|-------------|----------|
| Workcube | `workcube_satislar.sql` | Standart Workcube satış verileri |
| Odoo | `odoo_satislar.sql` | Odoo sale_order tabloları |
| LOGO | `logo_satislar.sql` | LOGO LG_* tabloları (kendiniz oluşturmalısınız) |
| Özel | `custom_satislar.sql` | Hiçbiri uymazsa özel SQL |

#### .env'de Kaydedin ve Kapatın

Script devam edecek.

---

### ⚠️ ADIM 5: SQL SORGUSUNU KONTROL ET/DÜZENLE

#### Ne Zaman Gerekli?
- ✅ Tablo isimleri farklıysa
- ✅ Kolon isimleri farklıysa
- ✅ Farklı veri çekmek istiyorsanız (30 gün yerine 7 gün)

#### Dosyayı Açın:

```cmd
cd ABC_MUSTERI
notepad dbt_project\scripts\queries\workcube_satislar.sql
```

#### Kontrol Edilecekler:

| Ne | Nasıl Kontrol Edilir | Örnek Değişiklik |
|----|---------------------|------------------|
| **Tablo adları** | `FROM {{dsn2}}.dbo.SALESINVOICELINES` | `WRK_INVOICES` olabilir |
| **Kolon adları** | `ITEMCODE`, `QUANTITY` | `PRODUCT_CODE`, `QTY` olabilir |
| **Tarih süresi** | `DATEADD(day, -7, GETDATE())` | `-30` yapabilirsiniz |
| **JOIN'ler** | `LEFT JOIN ... PRODUCTS` | Tablo yoksa çıkartın |

#### Örnek Değişiklik (Tablo Adı):

**Eski**:
```sql
FROM {{dsn2}}.dbo.SALESINVOICELINES s
```

**Yeni** (müşteride tablo adı farklıysa):
```sql
FROM {{dsn2}}.dbo.WRK_SALES_INVOICES s
```

#### Şema Değişkenleri:

| Değişken | Örnek Değer (Çalışma zamanında) |
|----------|----------------------------------|
| `{{dsn}}` | `workcube_prod` |
| `{{dsn2}}` | `workcube_prod_2026_1` |
| `{{dsn3}}` | `workcube_prod_1` |
| `{{dsn_product}}` | `workcube_prod_product` |

---

### ✅ ADIM 6: DOCKER SERVİSLERİNİ BAŞLAT

#### Script Soracak:
```
.env dosyasini duzenlediniz mi? (E/H):
```

**E** yazın ve Enter'a basın.

#### Ne Olur?
6 Docker servisi başlar:

| Servis | Port | Rol |
|--------|------|-----|
| ClickHouse | 8123 | Analitik veritabanı |
| PostgreSQL | 5432 | Superset metadata |
| Redis | 6379 | Cache |
| dbt | - | Veri dönüşüm |
| Ofelia | - | Zamanlayıcı |
| Superset | 8088 | Dashboard |

#### Kontrol:
```cmd
cd ABC_MUSTERI
docker-compose ps
```

**Beklenen Çıktı** (hepsi "Up" olmalı):
```
NAME                      STATUS
ABC_MUSTERI_clickhouse    Up
ABC_MUSTERI_postgres      Up
ABC_MUSTERI_redis         Up
ABC_MUSTERI_dbt           Up
ABC_MUSTERI_scheduler     Up
ABC_MUSTERI_superset      Up
```

#### Sorun Çözüm:

| Sorun | Çözüm |
|-------|-------|
| "Docker daemon çalışmıyor" | Docker Desktop'ı başlatın |
| Bir servis "Exited" | `docker-compose logs [servis_adi]` |
| Port 8088 kullanımda | `netstat -ano \| findstr :8088` → İşlemi kapatın |

---

### ✅ ADIM 7: İLK VERİ YÜKLEME (MANUEL TEST)

#### Komut:

```cmd
cd ABC_MUSTERI
docker exec ABC_MUSTERI_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py
```

#### Beklenen Çıktı:

```
[2026-01-18 16:00:00] 📦 ERP → ClickHouse Veri Aktarımı BAŞLADI
[2026-01-18 16:00:00] 📄 Kullanılan SQL: workcube_satislar.sql
[2026-01-18 16:00:00] 📝 Şema parametreleri:
   {{dsn}} → workcube_prod
   {{dsn2}} → workcube_prod_2026_1
   {{dsn3}} → workcube_prod_1
   {{dsn_product}} → workcube_prod_product
[2026-01-18 16:00:01] 🔌 ERP'ye bağlanılıyor: 192.168.1.50:1433/WORKCUBE_ABC
[2026-01-18 16:00:02] 📊 Sorgu çalıştırılıyor...
[2026-01-18 16:00:05] ✅ 1,234 satır çekildi
[2026-01-18 16:00:06] 🔌 ClickHouse'a bağlanılıyor...
[2026-01-18 16:00:07] ✅ Yükleme tamamlandı! Toplam kayıt: 1,234
```

#### Veriyi Kontrol:

```cmd
docker exec ABC_MUSTERI_clickhouse clickhouse-client --query "SELECT count() FROM raw_erp.satislar"
```

**Beklenen**: `1234` (veya veri sayınız)

#### Hata Çözümleri:

| Hata | Sebep | Çözüm |
|------|-------|-------|
| "Invalid object name 'SALESINVOICELINES'" | Tablo adı yanlış | SQL dosyasını düzenleyin (Adım 5) |
| "Login failed for user" | Kullanıcı adı/şifre yanlış | .env'i kontrol edin |
| "Cannot connect to server" | ERP sunucusu ulaşılamıyor | Firewall/VPN kontrol edin |
| "Invalid schema 'workcube_prod_2026_1'" | Şema yok | .env'deki parametreleri kontrol edin |

---

### ✅ ADIM 8: DBT MODELLERİNİ ÇALIŞTIR

#### Komut:

```cmd
docker exec ABC_MUSTERI_dbt dbt run
```

#### Ne Yapar?
`raw_erp.satislar` → `mart.fct_satislar_hazir` dönüşümü yapar.

#### Beklenen Çıktı:

```
Running with dbt=1.7.0
Found 1 model, 0 tests, 0 snapshots, 0 analyses

Concurrency: 2 threads

Completed successfully

Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

#### Sonucu Kontrol:

```cmd
docker exec ABC_MUSTERI_clickhouse clickhouse-client --query "SELECT count() FROM mart.fct_satislar_hazir"
```

---

### ✅ ADIM 9: SUPERSET → CLICKHOUSE BAĞLANTISI

#### Tarayıcıda:
```
http://localhost:8088
```

#### Giriş:
- **Kullanıcı**: `admin`
- **Şifre**: `admin123` (veya .env'deki değer)

#### Adımlar:

| # | İşlem | Detay |
|---|-------|-------|
| 1 | **Settings** → **Database Connections** | Sol menüden |
| 2 | **+Database** butonu | Sağ üstte |
| 3 | **SUPPORTED DATABASES** → **ClickHouse** | Listeden seçin |
| 4 | **SQLALCHEMY URI** | `clickhouse://clickhouse:8123/mart` |
| 5 | **Test Connection** | Yeşil ✓ görmeli |
| 6 | **Connect** | Bağlantıyı kaydet |

#### Kontrol:
Settings → Database Connections → "ClickHouse" görünmeli

---

### ✅ ADIM 10: İLK DASHBOARD OLUŞTUR

#### 10.1: Dataset Ekle

| # | İşlem | Değer |
|---|-------|-------|
| 1 | **Datasets** → **+Dataset** | |
| 2 | **Database** | ClickHouse |
| 3 | **Schema** | mart |
| 4 | **Table** | fct_satislar_hazir |
| 5 | **Create Dataset and Create Chart** | |

#### 10.2: Grafik Oluştur

| Alan | Değer |
|------|-------|
| **Visualization Type** | Time-series Line Chart |
| **Time Column** | fatura_tarihi |
| **Metrics** | SUM(toplam_tutar) |
| **Group By** | (boş veya musteri_adi) |

**Update Chart** → **Save** → **"Satış Grafiği"**

#### 10.3: Dashboard Ekle

1. **Dashboards** → **+Dashboard**
2. **Title**: `ABC MUSTERI - Satış Raporu`
3. Grafiği sürükleyip bırakın
4. **Save**

#### 10.4: Cache Ayarı (Hız İçin!)

Dashboard → **Settings** → **Advanced**
- **Cache Timeout**: `86400` (24 saat)
- **Refresh Interval**: `300` (5 dakika)

**Save**

Artık dashboard **0.2 saniyede** açılacak! 🚀

---

### ⚠️ ADIM 11: OFELİA KONTROL (OTOMASYON)

#### Ofelia Çalışıyor mu?

```cmd
docker ps | findstr scheduler
```

**Beklenen**: `ABC_MUSTERI_scheduler   Up`

#### Logları Görüntüle:

```cmd
docker logs ABC_MUSTERI_scheduler -f
```

**Beklenen Çıktı**:
```
Ofelia daemon started
```

#### Zamanlanmış Görevler:

| Görev | Zamanlama | Ne Yapar |
|-------|-----------|----------|
| `erp_veri_cek` | Her gece 02:00 | ERP'den veri çeker |
| `dbt_calistir` | Her gece 03:00 | dbt modellerini çalıştırır |
| `cache_temizle` | Her Pazar 04:00 | Redis cache temizler |

#### Manuel Tetikleme (Test için):

```cmd
# ERP'den veri çek (Adım 7'nin aynısı)
docker exec ABC_MUSTERI_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py

# dbt çalıştır (Adım 8'in aynısı)
docker exec ABC_MUSTERI_dbt dbt run
```

---

## ✅ KURULUM TAMAMLANDI!

### Kontrol Listesi:

| ☑ | İşlem | Doğrulama |
|---|-------|-----------|
| ☐ | Klasör oluştu | `ABC_MUSTERI/` klasörü var |
| ☐ | .env dolduruldu | ERP + Şema + SQL parametreleri |
| ☐ | Docker çalışıyor | 6/6 servis "Up" |
| ☐ | Veri yüklendi | `raw_erp.satislar` tablosu var |
| ☐ | dbt çalıştı | `mart.fct_satislar_hazir` tablosu var |
| ☐ | Superset açıldı | http://localhost:8088 |
| ☐ | ClickHouse bağlandı | Settings → Database Connections |
| ☐ | Dataset oluştu | `mart.fct_satislar_hazir` |
| ☐ | Dashboard var | En az 1 grafik |
| ☐ | Cache ayarlandı | Dashboard hızlı açılıyor |
| ☐ | Ofelia aktif | Scheduler çalışıyor |

---

## 🚨 SIK KARŞILAŞILAN HATALAR

| Hata | Dosya/Yer | Çözüm |
|------|-----------|-------|
| "docker-compose.yml bulunamadı" | Terminal | `cd ABC_MUSTERI` |
| "ERP'ye bağlanılamadı" | `.env` satır 15 | Host/Port/User/Pass kontrol |
| "Tablo bulunamadı" | `queries/*.sql` | Tablo adlarını kontrol |
| "Şema bulunamadı" | `.env` satır 31-34 | Şema parametrelerini kontrol |
| "Superset açılmıyor" | Docker | 2-3 dk bekleyin, `docker logs` |
| "dbt çalışmıyor" | dbt_project | `docker exec ... dbt debug` |
| "Dataset boş" | Adım 7 | Veri çekildi mi kontrol edin |
| "Dashboard yavaş" | Superset | Cache ayarını yapın (Adım 10.4) |

---

## 📞 YARDIM KAYNAKLARI

| Konu | Dosya |
|------|-------|
| SQL şema parametreleri | `SEMA_PARAMETRELERI.md` |
| SQL sorgu yapılandırma | `SQL_SORGU_REHBERI.md` |
| Veri akışı | `VERİ_AKISI_OZET.md` |
| Hızlı komutlar | `HIZLI_REFERANS.md` |
| Kurulum testi | `KURULUM_TEST.md` |

---

## 📌 SONRAKİ ADIMLAR (Kurulum Sonrası)

1. **Müşteriye Demo Yapın**
   - Dashboard'u gösterin
   - Filtreleme özelliklerini gösterin
   - Andon modunu gösterin (standalone URL)

2. **Yedek Alın**
   ```cmd
   # data/ klasörünü yedekleyin
   xcopy /E /I ABC_MUSTERI\data ABC_MUSTERI_YEDEK_20260118
   ```

3. **Dokümantasyon**
   - Müşteriye özel SQL sorgularını kaydedin
   - Dashboard'ların ekran görüntüsünü alın

4. **Eğitim**
   - Müşteriye Superset kullanımını gösterin
   - Basit filtre eklemeyi öğretin

---

**Bu dosyayı yazdırıp mabanıza asın!** 📌

**Güncelleme Geçmişi**:
- 2026-01-18 16:15: İlk versiyon (Ofelia + dbt + Şema parametreleri)
