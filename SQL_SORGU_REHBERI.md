# 📊 SQL SORGU YAPLANDIRMASI REHBERİ

## 🎯 SORUNUZA CEVAP: "Neyi Nasıl Çekecek?"

### Cevap: `.env` dosyasında `SQL_QUERY_FILE` ile belirlenir!

---

## 🔧 NASIL ÇALIŞIR?

### 1️⃣ Her Müşteri İçin SQL Dosyası Oluşturun

```
dbt_project/scripts/queries/
├── workcube_satislar.sql    ← Workcube müşteriler için
├── odoo_satislar.sql         ← Odoo müşteriler için
├── logo_satislar.sql         ← LOGO müşteriler için
└── custom_satislar.sql       ← Özel durumlar için
```

### 2️⃣ .env Dosyasında Hangi SQL'i Kullanacağını Belirleyin

```ini
# .env dosyasında
SQL_QUERY_FILE=workcube_satislar.sql
```

### 3️⃣ Ofelia Her Gece Bu SQL'i Çalıştırır

```ini
# ofelia.ini
[job-exec "erp_veri_cek"]
schedule = 0 2 * * *
command = python /usr/app/scripts/erp_to_clickhouse_v2.py
```

Python scripti:
1. `.env`'den `SQL_QUERY_FILE` okur
2. `queries/workcube_satislar.sql` dosyasını açar
3. O SQL'i ERP'de çalıştırır
4. Sonucu ClickHouse'a yazar

---

## 📝 YENİ MÜŞTERİ EKLEME (Adım Adım)

### Senaryo: ABC Turizm (Workcube ERP)

#### Adım 1: Kurulum

```cmd
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi
kur.bat ABC_Turizm
```

#### Adım 2: .env Dosyasını Düzenle

```ini
MUSTERI_ADI=ABC_Turizm

# ERP bağlantısı
ERP_DB_TYPE=mssql
ERP_DB_HOST=192.168.1.50
ERP_DB_NAME=WORKCUBE_ABC
ERP_DB_USER=raporlama
ERP_DB_PASSWORD=abc123

# ÖNEMLI: Hangi SQL kullanılacak?
SQL_QUERY_FILE=workcube_satislar.sql
```

#### Adım 3: SQL Dosyasını Kontrol Et

`ABC_Turizm/dbt_project/scripts/queries/workcube_satislar.sql` dosyasını açın.

Tablo isimlerini kontrol edin:
```sql
FROM SALESINVOICELINES  -- ← ABC Turizm'de bu tablo var mı?
```

Yoksa düzeltin:
```sql
FROM WRK_SALESINVOICES  -- ← Doğru tablo adı
```

#### Adım 4: Manuel Test

```cmd
cd ABC_Turizm

# İlk veri çekmeyi test et
docker exec ABC_Turizm_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py
```

**Beklenen çıktı**:
```
[2026-01-18 16:00:00] 📦 ERP → ClickHouse Veri Aktarımı BAŞLADI
[2026-01-18 16:00:00] 📄 Kullanılan SQL: workcube_satislar.sql
[2026-01-18 16:00:01] 🔌 ERP'ye bağlanılıyor: 192.168.1.50:1433/WORKCUBE_ABC
[2026-01-18 16:00:02] 📊 Sorgu çalıştırılıyor...
[2026-01-18 16:00:05] ✅ 1,234 satır çekildi
[2026-01-18 16:00:06] 🔌 ClickHouse'a bağlanılıyor...
[2026-01-18 16:00:07] ✅ Yükleme tamamlandı! Toplam kayıt: 1,234
```

#### Adım 5: Otomatik Çalışmayı Doğrula

Ofelia her gece saat 02:00'de otomatik çalıştıracak. Logları görmek için:

```cmd
docker logs ABC_Turizm_scheduler -f
```

---

## 📂 SQL DOSYASI ŞABLONLARhI

### Workcube İçin (workcube_satislar.sql)

```sql
SELECT
    CAST(SALESID AS VARCHAR(50)) as satir_id,
    CAST(INVOICEID AS VARCHAR(50)) as fatura_id,
    CAST(INVOICEDATE AS DATE) as fatura_tarihi,
    CAST(ITEMCODE AS VARCHAR(100)) as urun_kodu,
    CAST(ITEMNAME AS VARCHAR(500)) as urun_adi,
    CAST(QUANTITY AS FLOAT) as miktar,
    CAST(UNITPRICE AS FLOAT) as birim_fiyat,
    CAST(TOTALAMOUNT AS FLOAT) as toplam_tutar,
    CAST(TAXAMOUNT AS FLOAT) as kdv_tutari,
    CAST(CUSTOMERCODE AS VARCHAR(100)) as musteri_kodu,
    CAST(CUSTOMERNAME AS VARCHAR(500)) as musteri_adi,
    CAST(WAREHOUSECODE AS VARCHAR(50)) as depo_kodu
FROM SALESINVOICELINES
WHERE INVOICEDATE >= DATEADD(day, -7, GETDATE())
ORDER BY INVOICEDATE DESC
```

### Odoo İçin (odoo_satislar.sql)

```sql
SELECT
    CAST(sol.id AS VARCHAR(50)) as satir_id,
    CAST(so.name AS VARCHAR(50)) as fatura_id,
    CAST(so.date_order AS DATE) as fatura_tarihi,
    CAST(pt.default_code AS VARCHAR(100)) as urun_kodu,
    CAST(pt.name AS VARCHAR(500)) as urun_adi,
    CAST(sol.product_uom_qty AS FLOAT) as miktar,
    CAST(sol.price_unit AS FLOAT) as birim_fiyat,
    CAST(sol.price_subtotal AS FLOAT) as toplam_tutar,
    CAST(sol.price_tax AS FLOAT) as kdv_tutari,
    CAST(rp.ref AS VARCHAR(100)) as musteri_kodu,
    CAST(rp.name AS VARCHAR(500)) as musteri_adi,
    CAST(sw.code AS VARCHAR(50)) as depo_kodu
FROM sale_order_line sol
LEFT JOIN sale_order so ON sol.order_id = so.id
LEFT JOIN product_product pp ON sol.product_id = pp.id
LEFT JOIN product_template pt ON pp.product_tmpl_id = pt.id
LEFT JOIN res_partner rp ON so.partner_id = rp.id
LEFT JOIN stock_warehouse sw ON so.warehouse_id = sw.id
WHERE so.state IN ('sale', 'done')
  AND so.date_order >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY so.date_order DESC
```

---

## 🔄 FARKLI VERİLER ÇEKMEK

### Sadece Satış Değil, Stok da İstiyorsanız

#### Adım 1: Yeni SQL Oluştur

`workcube_stok.sql`:
```sql
SELECT
    CAST(ITEMCODE AS VARCHAR(100)) as urun_kodu,
    CAST(ITEMNAME AS VARCHAR(500)) as urun_adi,
    CAST(ONHAND AS FLOAT) as eldeki_miktar,
    CAST(WAREHOUSECODE AS VARCHAR(50)) as depo_kodu,
    CAST(LASTUPDATED AS DATE) as guncelleme_tarihi
FROM STOCKLEVELS
WHERE WAREHOUSECODE IS NOT NULL
```

#### Adım 2: Ofelia'ya Ekle

`ofelia.ini`:
```ini
# Stok verisi çek (Her gün 04:00)
[job-exec "stok_veri_cek"]
schedule = 0 4 * * *
container = ${MUSTERI_ADI}_dbt
command = python /usr/app/scripts/erp_to_clickhouse_stok.py
no-overlap = true
```

#### Adım 3: Python Script Kopyala

```cmd
cd ABC_Turizm/dbt_project/scripts
copy erp_to_clickhouse_v2.py erp_to_clickhouse_stok.py
```

`erp_to_clickhouse_stok.py` içinde:
```python
SQL_QUERY_FILE = os.getenv('SQL_QUERY_FILE_STOK', 'workcube_stok.sql')
```

---

## ⚙️ AYARLANAB İLİR PARAMETRELER

### .env Dosyasında

```ini
# Kaç günlük veri çekilsin? (Varsayılan: 7)
DAYS_TO_FETCH=30

# Toplu mu çekilsin, incremental mı?
LOAD_MODE=incremental  # veya "full"

# Hangi tarihten itibaren?
START_DATE=2024-01-01
```

### SQL Dosyasında Kullanmak

```sql
-- Dinamik tarih filtresi
WHERE INVOICEDATE >= DATEADD(day, -{{DAYS_TO_FETCH}}, GETDATE())
```

Python scriptinde:
```python
days = int(os.getenv('DAYS_TO_FETCH', 7))
query = query.replace('{{DAYS_TO_FETCH}}', str(days))
```

---

## 🐛 SORUN GİDERME

### "SQL dosyası bulunamadı"

**Hata**:
```
❌ HATA: /usr/app/scripts/queries/workcube_satislar.sql bulunamadı!
```

**Çözüm**:
```cmd
cd ABC_Turizm/dbt_project/scripts/queries
dir  # Dosya var mı kontrol et

# Yoksa oluştur
copy ..\..\..\..\dbt_project\scripts\queries\workcube_satislar.sql .
```

### "Tablo bulunamadı"

**Hata**:
```
Invalid object name 'SALESINVOICELINES'
```

**Çözüm**: SQL dosyasındaki tablo adını ERP'nizde kontrol edin.

```cmd
# ERP'ye bağlan ve tablo isimlerini listele
docker exec ABC_Turizm_dbt python -c "
import pymssql
conn = pymssql.connect(server='192.168.1.50', user='raporlama', password='abc123', database='WORKCUBE_ABC')
cursor = conn.cursor()
cursor.execute(\"SELECT name FROM sys.tables WHERE name LIKE '%SALES%'\")
for row in cursor:
    print(row[0])
"
```

---

## ✅ ÖZET: VERİ ÇEKİMİ NASIL AYARLANIYOR?

1. **SQL dosyası oluştur**: `queries/musteri_adi.sql`
2. **.env'de belirt**: `SQL_QUERY_FILE=musteri_adi.sql`
3. **Manuel test et**: `docker exec ... python erp_to_clickhouse_v2.py`
4. **Ofelia otomatik çalıştırır**: Her gece 02:00

**İşte bu kadar!** Her müşteri için sadece SQL dosyası değiştirmeniz yeterli.

---

**Güncellenme**: 2026-01-18
**Versiyon**: 3.1 (Yapılandırılabilir SQL)
