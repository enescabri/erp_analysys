# 📊 ERP Analiz Paketi v3.2 (ClickHouse + dbt)

**Multi-ERP destekli, fabrika Andon ekranları hazır, açık kaynak veri analizi platformu.**

Workcube, Odoo, SAP ve diğer tüm ERP'lerden veriyi **standart bir şemada** birleştirip saniyeler içinde raporlar.

---

## 📚 DOKÜMANTASYON

### 💻 Platform Seçimi

**Windows kurulum** → **[KURULUM_ADIM_ADIM.md](KURULUM_ADIM_ADIM.md)** (11 adımlık detaylı rehber)

**Ubuntu Server kurulum** → **[README_UBUNTU.md](README_UBUNTU.md)** (Linux server kurulumu) 🐧

**GitHub'a yükleme** → **[GITHUB_YUKLEME.md](GITHUB_YUKLEME.md)** (Repo oluştur ve paylaş)

**Tüm dokümantasyon** → **[DOKUMANTASYON_INDEX.md](DOKUMANTASYON_INDEX.md)** (İçindekiler ve navigasyon)

---

## 🎯 Neden Bu Paket?

### Sorununuz:
- Her müşteride farklı ERP (Workcube, Odoo, LOGO...)
- Tablolar, kolon isimleri, JOIN mantıkları hep farklı
- Aynı raporları her müşteri için tekrar tekrar yazmak zorunda kalıyorsunuz

### Çözümümüz:
✅ **dbt ile standart şema**: Workcube'daki `SALESINVOICELINES` ile Odoo'daki `sale_order_line` → aynı `fct_satislar` tablosuna dönüşür
✅ **ClickHouse ile hız**: Milyonlarca satır JOIN → 0.2 saniye
✅ **Superset ile profesyonellik**: Andon ekranları, otomatik raporlar, satır bazlı güvenlik

---

## 🛠 Paket İçeriği

| Bileşen | Rol | Port | Neden Var? |
|---------|-----|------|-----------|
| **ClickHouse** | Analitik Depo | 8123 | ERP'yi yormadan, hızlı sorgu için veri burada |
| **dbt** | Veri Dönüşüm | - | SQL ile "Ham ERP → Standart Şema" |
| **Ofelia** | Zamanlayıcı | - | Her gece otomatik veri çekme (cron) |
| **Apache Superset** | Dashboard | 8088 | Raporlar, Andon ekranları |
| **PostgreSQL** | Metadata | 5432 | Superset metadata ayarları |
| **Redis** | Cache | 6379 | Dashboard'ları hızlandırır (0.2 sn) |

---

## 🚀 Hızlı Kurulum (10 Dakika)

### Gereksinimler
- Docker & Docker Compose
- En az 8GB RAM (16GB önerilir)

### Kurulum

```bash
# 1. Paketi klonlayın
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi

# 2. .env dosyasını düzenleyin
notepad .env
# → MÜŞTERİ BİLGİLERİNİ DOLDURUN (ERP bağlantısı, SMTP vs.)

# 3. Sistemi başlatın
docker-compose up -d

# 4. İlk kurulumu bekleyin (2-3 dakika)
docker-compose logs -f superset
```

### İlk Giriş

- **Superset**: http://localhost:8088 (admin / .env'deki şifre)
- **Airflow**: http://localhost:8080 (admin / .env'deki şifre)

---

## 📐 Veri Mimarisi

```
┌──────────────────────────────────────────────────┐
│ KATMAN 1: HAM VERİ (Raw Layer)                   │
│ ┌──────────────┐  ┌──────────────┐              │
│ │  Workcube    │  │    Odoo      │              │
│ │ (SQL Server) │  │ (PostgreSQL) │              │
│ └──────┬───────┘  └──────┬───────┘              │
│        │                  │                       │
│        └────── Airflow ───┘                       │
│                  ↓                                │
│        ClickHouse (raw_workcube, raw_odoo)       │
└──────────────────────────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│ KATMAN 2: DÖNÜŞÜM (dbt ile SQL)                  │
│                                                   │
│ stg_workcube_satislar.sql                        │
│ stg_odoo_satislar.sql                            │
│        ↓                                          │
│ fct_satislar (BİRLEŞİK TABLO)                    │
│ → Standart kolonlar: fatura_tarihi, urun_kodu... │
└──────────────────────────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│ KATMAN 3: GÖRSEL (Superset Dashboard)            │
│ • Satış Raporu Dashboard                         │
│ • Üretim Takip Dashboard                         │
│ • Andon Ekranları (Otomatik yenileme)            │
└──────────────────────────────────────────────────┘
```

---

## 🔧 dbt ile Çalışma (Önemli!)

### dbt Nedir?
Veriyi **SQL ile** dönüştürür. Python yazmaya gerek yok.

### İlk Modelleri Çalıştırma

```bash
# dbt konteynerine girin
docker-compose exec dbt bash

# Modelleri çalıştırın (Workcube + Odoo → fct_satislar)
dbt run

# Test edin
dbt test

# Dokümantasyon oluşturun
dbt docs generate
dbt docs serve --port 8081
```

### Yeni ERP Eklemek (Örn: SAP)

1. `models/staging/stg_sap_satislar.sql` oluşturun:
```sql
SELECT
    VBELN as fatura_id,
    ERDAT as fatura_tarihi,
    MATNR as urun_kodu,
    MENGE as miktar,
    NETWR as toplam_tutar,
    -- ...
    'sap' as kaynak_sistem
FROM {{ source('raw_sap', 'VBRK') }}
```

2. `models/mart/fct_satislar.sql` içine ekleyin:
```sql
UNION ALL
SELECT * FROM {{ ref('stg_sap_satislar') }}
```

3. Çalıştırın:
```bash
dbt run --models fct_satislar
```

**İşte bu kadar!** Superset otomatik olarak yeni veriyi görür.

---

## 🖥 Andon Ekranları (Fabrika)

### Superset'te Andon Dashboard Oluşturma

1. **Dataset**: `fct_satislar` veya üretim verinizi seçin
2. **Grafik Oluştur**: Big Number, Table, Time Series
3. **Dashboard → Settings**:
   - **Auto Refresh**: 10 saniye
   - **Full Screen Mode**: Aktif
4. **URL'yi kopyalayın**:
   ```
   http://192.168.1.100:8088/superset/dashboard/5/?standalone=true
   ```
5. **Fabrika TV'sine Chrome Kiosk modunda açın**:
   ```bash
   chrome --kiosk --app="http://192.168.1.100:8088/superset/dashboard/5/?standalone=true"
   ```

### Andon için Özel Ayarlar

`superset_config.py` içinde:
```python
SUPERSET_DASHBOARD_PERIODICAL_REFRESH_LIMIT = 5  # Min 5 saniye
```

---

## 🔐 Satır Bazlı Güvenlik (RLS)

**Senaryo**: Her şube müdürü sadece kendi şubesinin verisini görmeli.

### Adımlar:

1. **SQL Lab'da Row Level Security tanımlayın**:
   ```sql
   -- Şube Müdürü için filtre
   depo_kodu = '{{ current_username() }}'
   ```

2. **Settings → Row Level Security → +**
   - **Table**: `fct_satislar`
   - **Clause**: `depo_kodu = 'ISTANBUL'`
   - **Roles**: `Sube_Muduru`

3. **Kullanıcıyı role atayın**:
   - User → Edit → Roles → `Sube_Muduru`

Artık o kullanıcı sadece İstanbul şubesinin verisini görür!

---

## 📂 Klasör Yapısı

```
erp_analiz_paketi/
├── .env                        # ← TEK AYAR NOKTASI
├── docker-compose.yml          # Sistem mimarisi
├── superset_config.py          # Superset özelleştirme
│
├── dbt_project/                # dbt SQL modelleri
│   ├── dbt_project.yml
│   └── models/
│       ├── staging/            # Ham veri → Temiz veri
│       │   ├── stg_workcube_satislar.sql
│       │   └── stg_odoo_satislar.sql
│       └── mart/               # Birleşik tablolar (Rapor için)
│           └── fct_satislar.sql
│
├── dags/                       # Airflow veri çekme görevleri
│   └── erp_to_clickhouse_dag.py
│
└── data/                       # Veriler (Docker Volume)
    ├── clickhouse/
    ├── postgres/
    └── superset_home/
```

---

## 🧪 Test Senaryosu

### 1. Workcube'dan Veri Çekme

`dags/workcube_to_clickhouse.py` içinde:
```python
# ERP'den SQL Server ile veri çek
SELECT * FROM SALESINVOICELINES WHERE INVOICEDATE >= '2024-01-01'
# → ClickHouse'a raw_workcube.SALESINVOICELINES tablosuna yükle
```

### 2. dbt ile Dönüştürme

```bash
docker-compose exec dbt dbt run --models stg_workcube_satislar
# → ClickHouse'da 'staging.stg_workcube_satislar' view'ı oluşur

docker-compose exec dbt dbt run --models fct_satislar
# → ClickHouse'da 'mart.fct_satislar' tablosu oluşur
```

### 3. Superset'te Görselleştirme

- **Dataset**: `mart.fct_satislar`
- **Grafik**: Time Series Bar Chart
  - X-Axis: `fatura_tarihi`
  - Metric: `SUM(toplam_tutar)`
  - Group By: `kaynak_sistem`

**Sonuç**: Workcube ve Odoo satışlarını yan yana görebilirsiniz!

---

## 🐛 Sorun Giderme

### dbt modelleri çalışmıyor

```bash
# Bağlantıyı test edin
docker-compose exec dbt dbt debug

# Hata: "Relation does not exist"
# → Airflow'dan veri çekilmiş mi kontrol edin
docker-compose exec clickhouse clickhouse-client --query "SHOW TABLES FROM raw_workcube"
```

### Superset yavaş

```bash
# Redis cache'i kontrol edin
docker-compose exec redis redis-cli KEYS "superset*"

# Cache'i temizleyin
docker-compose exec redis redis-cli FLUSHALL
```

### Andon ekranı donuyor

- **Chrome GPU Hatası**: Chrome'u `--disable-gpu` ile başlatın
- **Ağ Yavaşlığı**: Dashboard'daki grafik sayısını azaltın (Max 6 grafik önerilir)

---

## 📊 Performans İpuçları

### ClickHouse Optimizasyonu

```sql
-- İndeks ekleyin (ORDER BY zaten indeks oluşturur)
CREATE TABLE mart.fct_satislar (
    ...
) ENGINE = MergeTree()
ORDER BY (fatura_tarihi, urun_kodu)  -- Bu sütunlar hızlı sıralanır
```

### dbt Incremental Models

Eğer veri çok büyükse, sadece yeni satırları işleyin:

```sql
{{
    config(
        materialized='incremental',
        unique_key='satir_id'
    )
}}

SELECT * FROM {{ source('raw_workcube', 'SALESINVOICELINES') }}
{% if is_incremental() %}
    WHERE MODIFIEDDATE > (SELECT MAX(guncelleme_tarihi) FROM {{ this }})
{% endif %}
```

---

## 🚀 Yeni Müşteri Kurulum Checklist

- [ ] Paketi kopyala: `cp -r erp_analiz_paketi ABC_Firma/`
- [ ] `.env` dosyasını düzenle (ERP bağlantı bilgileri)
- [ ] `docker-compose up -d`
- [ ] Airflow'da DAG'ı aktifleştir
- [ ] dbt modellerini çalıştır: `dbt run`
- [ ] Superset'te ClickHouse bağlantısı ekle
- [ ] İlk dashboard'u oluştur
- [ ] Müşteriye demo yap!

**Süre**: 30 dakika (Artık günlerce uğraşmak yok!)

---

## 📞 Destek

**Dokümantasyon**: [dbt Docs](https://docs.getdbt.com)
**ClickHouse**: [ClickHouse.com](https://clickhouse.com/docs)
**Superset**: [Superset.apache.org](https://superset.apache.org)

---

## 📜 Lisans

MIT License - Ticari kullanıma açıktır.

**Yapımcı**: ERP Analiz Paketi v2.0 (2024)
