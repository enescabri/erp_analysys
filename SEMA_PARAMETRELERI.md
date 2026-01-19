# 🗂️ ŞEMA PARAMETRELERİ KULLANIM REHBERİ

## 🎯 SORUN: Her Müşteride Farklı Şema İsimleri

Workcube ERP'de her müşteride:
- Ana şema: `workcube_prod`, `wc_main`, `erp_data` vs.
- Periyot şeması: `workcube_prod_2026_1`, `wc_2025_2` vs.
- Şirket şeması: `workcube_prod_1`, `wc_company_5` vs.
- Ürün şeması: `workcube_prod_product`, `wc_products` vs.

**Her müşteri için SQL'i yeniden yazmak zor!**

---

## ✅ ÇÖZÜM: Parametreli SQL Şablonları

### 1️⃣ .env Dosyasında Parametreleri Tanımlayın

```ini
# === WORKCUBE ŞEMA PARAMETRELERİ ===
WC_BASE_SCHEMA=workcube_prod        # Ana şema adı
WC_PERIOD_YEAR=2026                 # Periyot yılı
WC_COMPANY_ID=1                     # Şirket ID
WC_PRODUCT_SCHEMA=workcube_prod_product  # Ürün şeması
```

### 2️⃣ SQL Dosyasında Değişkenleri Kullanın

```sql
-- workcube_satislar.sql

SELECT
    s.SALESID,
    p.ITEMNAME,
    c.CUSTOMERNAME

FROM {{dsn2}}.dbo.SALESINVOICELINES s
LEFT JOIN {{dsn_product}}.dbo.PRODUCTS p ON s.ITEMCODE = p.ITEMCODE
LEFT JOIN {{dsn3}}.dbo.CUSTOMERS c ON s.CUSTOMERCODE = c.CUSTOMERCODE

WHERE s.INVOICEDATE >= DATEADD(day, -7, GETDATE())
```

### 3️⃣ Python Scripti Otomatik Değiştir

```python
# Script çalıştığında:
{{dsn}}         → workcube_prod
{{dsn2}}        → workcube_prod_2026_1
{{dsn3}}        → workcube_prod_1
{{dsn_product}} → workcube_prod_product
```

---

## 📊 KULLANILABILEN DEĞİŞKENLER

| Değişken | Formül | Örnek Değer |
|----------|--------|-------------|
| `{{dsn}}` | `WC_BASE_SCHEMA` | `workcube_prod` |
| `{{dsn2}}` | `WC_BASE_SCHEMA_WC_PERIOD_YEAR_WC_COMPANY_ID` | `workcube_prod_2026_1` |
| `{{dsn3}}` | `WC_BASE_SCHEMA_WC_COMPANY_ID` | `workcube_prod_1` |
| `{{dsn_product}}` | `WC_PRODUCT_SCHEMA` | `workcube_prod_product` |

---

## 🎯 GERÇEK ÖRNEKLER

### Örnek 1: ABC Turizm

**.env**:
```ini
WC_BASE_SCHEMA=workcube_prod
WC_PERIOD_YEAR=2026
WC_COMPANY_ID=1
WC_PRODUCT_SCHEMA=workcube_prod_product
```

**SQL**:
```sql
FROM {{dsn2}}.dbo.SALESINVOICELINES
```

**Çalışma zamanında**:
```sql
FROM workcube_prod_2026_1.dbo.SALESINVOICELINES
```

---

### Örnek 2: XYZ Tekstil (Farklı Yapı)

**.env**:
```ini
WC_BASE_SCHEMA=wc_main
WC_PERIOD_YEAR=2025
WC_COMPANY_ID=5
WC_PRODUCT_SCHEMA=wc_products
```

**SQL** (aynı):
```sql
FROM {{dsn2}}.dbo.SALESINVOICELINES
LEFT JOIN {{dsn_product}}.dbo.PRODUCTS p
```

**Çalışma zamanında**:
```sql
FROM wc_main_2025_5.dbo.SALESINVOICELINES
LEFT JOIN wc_products.dbo.PRODUCTS p
```

---

### Örnek 3: DEF Holding (Çoklu Şirket)

**.env - Şirket 1**:
```ini
WC_BASE_SCHEMA=erp_def
WC_PERIOD_YEAR=2026
WC_COMPANY_ID=1
WC_PRODUCT_SCHEMA=erp_def_products
```

**.env - Şirket 2** (başka klasör):
```ini
WC_BASE_SCHEMA=erp_def
WC_PERIOD_YEAR=2026
WC_COMPANY_ID=2  # ← Sadece bu değişti!
WC_PRODUCT_SCHEMA=erp_def_products
```

**SQL** (ikiside aynı):
```sql
FROM {{dsn2}}.dbo.SALESINVOICELINES
```

**Şirket 1**:
```sql
FROM erp_def_2026_1.dbo.SALESINVOICELINES
```

**Şirket 2**:
```sql
FROM erp_def_2026_2.dbo.SALESINVOICELINES
```

---

## 🔧 TABLO İSİMLERİ FARKLI İSE

### Senaryo: Müşteride tablo ismi `SALES` değil `INVOICES`

**.env'de yeni parametre ekleyin**:
```ini
WC_SALES_TABLE=INVOICES  # Varsayılan: SALESINVOICELINES
```

**SQL'de kullanın**:
```sql
FROM {{dsn2}}.dbo.{{sales_table}}
```

**Python'da ekleyin** (`replace_schema_params` fonksiyonuna):
```python
replacements = {
    '{{dsn}}': dsn,
    '{{dsn2}}': dsn2,
    '{{dsn3}}': dsn3,
    '{{dsn_product}}': dsn_product,
    '{{sales_table}}': os.getenv('WC_SALES_TABLE', 'SALESINVOICELINES'),  # YENİ
}
```

---

## 📝 YENİ MÜŞTERİ EKLEME (Şema Parametreleriyle)

### Adım 1: ERP'deki Şema İsimlerini Öğrenin

```sql
-- ERP veritabanında çalıştırın
SELECT name FROM sys.schemas
```

**Çıktı**:
```
workcube_prod
workcube_prod_2026_1
workcube_prod_1
workcube_prod_product
```

### Adım 2: .env Dosyasını Doldurun

```ini
WC_BASE_SCHEMA=workcube_prod
WC_PERIOD_YEAR=2026
WC_COMPANY_ID=1
WC_PRODUCT_SCHEMA=workcube_prod_product
```

### Adım 3: SQL Şablonunu Kullanın

`workcube_satislar.sql` şablonunu olduğu gibi kullanın! Değişiklik gerekmez.

### Adım 4: Test Edin

```cmd
docker exec MUSTERI_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py
```

**Beklenen log**:
```
[2026-01-18 16:00:00] 📝 Şema parametreleri:
   {{dsn}} → workcube_prod
   {{dsn2}} → workcube_prod_2026_1
   {{dsn3}} → workcube_prod_1
   {{dsn_product}} → workcube_prod_product
```

---

## 🎨 LOGO VE DİĞER ERP'LER İÇİN

### LOGO ERP Parametreleri

**.env**:
```ini
# LOGO Şema Parametreleri
LOGO_FIRM_NO=001
LOGO_PERIOD_NO=01
```

**SQL**:
```sql
FROM LG_{{logo_firm}}_{{logo_period}}_STLINE
```

**Python** (`replace_schema_params` fonksiyonuna ekle):
```python
# LOGO parametreleri
logo_firm = os.getenv('LOGO_FIRM_NO', '001')
logo_period = os.getenv('LOGO_PERIOD_NO', '01')

replacements.update({
    '{{logo_firm}}': logo_firm,
    '{{logo_period}}': logo_period,
})
```

**Sonuç**:
```sql
FROM LG_001_01_STLINE
```

---

## 🔄 PERIYOT DEĞİŞTİĞİNDE

### Yıl Sonu (2026 → 2027)

**.env'de sadece yılı değiştirin**:
```ini
WC_PERIOD_YEAR=2027  # ← Sadece bu değişti
```

**SQL** (hiç dokunmayın):
```sql
FROM {{dsn2}}.dbo.SALESINVOICELINES
```

**Çalışma zamanında**:
```sql
FROM workcube_prod_2027_1.dbo.SALESINVOICELINES
```

---

## 🎯 ÖZET

| Ne Yapıyorsunuz? | Nerede Tanımlıyorsunuz? |
|------------------|-------------------------|
| **Şema isimleri** | `.env` dosyasında parametreler |
| **SQL sorgusu** | `queries/*.sql` dosyasında {{değişken}} |
| **Değişken değiştirme** | Python scripti otomatik yapar |

### Avantajlar:

✅ **Tek .env değişikliği** → Tüm SQL'ler güncellenir
✅ **SQL şablonları standart** → Her müşteri aynı SQL'i kullanır
✅ **Yeni müşteri eklemek kolay** → Sadece .env'i doldur
✅ **Periyot değişimi kolay** → Sadece yıl parametresini değiştir

---

**Güncellenme**: 2026-01-18
**Versiyon**: 3.2 (Şema Parametreleri)
