# 🔄 VERİ AKIŞI - GÖRSEL ÖZET

## 📊 SORUNUZA CEVAP

**"ERP veritabanından veriyi nasıl yükleyecek? Hangi veriyi alacak? Ofelia ile cron oluşturuyoruz ama neyi nasıl çekecek ayarlanıyor mu?"**

✅ **CEVAP**: `.env` dosyasında `SQL_QUERY_FILE` parametresi ile ayarlanıyor!

---

## 🎯 VERİ ÇEKME SÜRECİ (5 ADIM)

```
┌─────────────────────────────────────────────────────┐
│ 1. .ENV DOSYASI (Yapılandırma)                      │
│ ─────────────────────────────────────────────────── │
│ SQL_QUERY_FILE=workcube_satislar.sql                │
│ ERP_DB_HOST=192.168.1.50                            │
│ ERP_DB_NAME=WORKCUBE_ABC                            │
│ ERP_DB_USER=raporlama                               │
│ ERP_DB_PASSWORD=abc123                              │
└──────────────┬──────────────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────────────┐
│ 2. OFELİA (Zamanlayıcı)                             │
│ ─────────────────────────────────────────────────── │
│ Her gece saat 02:00                                 │
│ Çalıştır: python erp_to_clickhouse_v2.py            │
└──────────────┬──────────────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────────────┐
│ 3. PYTHON SCRİPTİ                                   │
│ ─────────────────────────────────────────────────── │
│ .env'den SQL_QUERY_FILE oku                         │
│ → workcube_satislar.sql dosyasını aç               │
│ → SQL sorgusunu ERP'de çalıştır                     │
└──────────────┬──────────────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────────────┐
│ 4. SQL DOSYASI (queries/workcube_satislar.sql)     │
│ ─────────────────────────────────────────────────── │
│ SELECT                                              │
│   SALESID, INVOICEID, INVOICEDATE,                  │
│   ITEMCODE, QUANTITY, TOTALAMOUNT                   │
│ FROM SALESINVOICELINES                              │
│ WHERE INVOICEDATE >= DATEADD(day, -7, GETDATE())   │
└──────────────┬──────────────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────────────┐
│ 5. CLICKHOUSE                                       │
│ ─────────────────────────────────────────────────── │
│ raw_erp.satislar tablosuna veri yazılır             │
│ → dbt bu veriyi işleyip mart.fct_satislar_hazir'a  │
│ → Superset buradan dashboard oluşturur             │
└─────────────────────────────────────────────────────┘
```

---

## 🔧 MÜŞTER İYE GÖRE ÖZELLEŞTİRME

### Senaryo 1: ABC Turizm (Workcube)

```ini
# ABC_Turizm/.env
SQL_QUERY_FILE=workcube_satislar.sql
ERP_DB_NAME=WORKCUBE_ABC
```

**Çekilecek veri**: Son 7 günün satış faturaları

### Senaryo 2: XYZ Tekstil (Odoo)

```ini
# XYZ_Tekstil/.env
SQL_QUERY_FILE=odoo_satislar.sql
ERP_DB_NAME=odoo_xyz
```

**Çekilecek veri**: Odoo'daki onaylı satış siparişleri

### Senaryo 3: DEF Gıda (LOGO)

```ini
# DEF_Gida/.env
SQL_QUERY_FILE=logo_satislar.sql
ERP_DB_NAME=LOGO_DEF
```

**SQL dosyasını siz oluşturursunuz**:
```sql
-- logo_satislar.sql
SELECT
    LOGICALREF as satir_id,
    FICHENO as fatura_id,
    DATE_ as fatura_tarihi,
    STOCKREF as urun_kodu,
    -- LOGO'ya özel alanlar...
FROM LG_001_01_STLINE
WHERE DATE_ >= DATEADD(day, -7, GETDATE())
```

---

## 📁 KLASÖR YAPISI (Her Müşteri İçin)

```
ABC_Turizm/
├── .env                                 ← SQL_QUERY_FILE=workcube_satislar.sql
├── dbt_project/
│   └── scripts/
│       ├── erp_to_clickhouse_v2.py      ← Bu scripti çalıştırır Ofelia
│       └── queries/
│           ├── workcube_satislar.sql    ← Bu SQL'i çalıştırır script
│           ├── odoo_satislar.sql        ← Başka müşteri için
│           └── custom.sql               ← Özel durumlar için
└── ofelia.ini                           ← Her gece 02:00'de tetikler
```

---

## ⚙️ NASIL ÖZELLEŞTİRİRSİNİZ?

### 1. Farklı Tablo İsimleri

**Workcube**: `SALESINVOICELINES`
**Odoo**: `sale_order_line`
**LOGO**: `LG_001_01_STLINE`

→ Her müşteri için **ayrı SQL dosyası** oluşturun.

### 2. Farklı Tarih Aralığı

**7 gün yerine 30 gün**:
```sql
WHERE INVOICEDATE >= DATEADD(day, -30, GETDATE())
```

**Belirli bir tarihten itibaren**:
```sql
WHERE INVOICEDATE >= '2024-01-01'
```

### 3. Farklı Filtreler

**Sadece belirli şube**:
```sql
WHERE WAREHOUSECODE = 'IST001'
  AND INVOICEDATE >= DATEADD(day, -7, GETDATE())
```

**Sadece onaylı faturalar**:
```sql
WHERE STATUS = 'APPROVED'
  AND INVOICEDATE >= DATEADD(day, -7, GETDATE())
```

---

## 🚀 YENİ MÜŞTERİ EKLEDİĞİNİZDE YAPMANIZ GEREKENLER

### Adım 1: ERP'deki Tablo İsimlerini Öğrenin

```sql
-- ERP veritabanında çalıştırın
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%SAT%' OR TABLE_NAME LIKE '%SALES%'
```

### Adım 2: SQL Dosyası Oluşturun

`queries/musteri_adi.sql` dosyasını şablondan kopyalayıp düzenleyin.

### Adım 3: .env'de Belirtin

```ini
SQL_QUERY_FILE=musteri_adi.sql
```

### Adım 4: Test Edin

```cmd
docker exec MUSTERI_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py
```

### Adım 5: Otomatik Çalışsın

Ofelia her gece otomatik çalıştıracak. Loglar:
```cmd
docker logs MUSTERI_scheduler -f
```

---

## 🎯 ÖZET

| Soru | Cevap |
|------|-------|
| **Hangi veriyi çekecek?** | `queries/` klasöründeki SQL dosyası belirler |
| **Nasıl belirleriz?** | `.env` dosyasında `SQL_QUERY_FILE` parametresi |
| **Ne zaman çalışacak?** | `ofelia.ini`'de `schedule = 0 2 * * *` (her gece 02:00) |
| **Otomatik mi?** | Evet! Ofelia her gece otomatik çalıştırır |
| **Farklı müşterilerde?** | Her müşteri için farklı SQL dosyası |

---

**Artık her müşteri için sadece SQL dosyası oluşturmanız yeterli!** 🎉

**Güncellenme**: 2026-01-18
**Versiyon**: 3.1
