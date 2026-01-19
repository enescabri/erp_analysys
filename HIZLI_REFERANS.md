# ⚡ HIZLI REFERANS KARTI

Müşteri kurulumlarında hızlıca bakabileceğiniz komutlar.

---

## 🚀 YENİ MÜŞTERİ KURULUMU

```bash
# 1. Tek komutla kurulum
kur.bat ABC_Firma

# 2. .env düzenle (Script açacak)
# ERP_DB_HOST, ERP_DB_NAME, ERP_DB_USER, ERP_DB_PASSWORD

# 3. Başlat (Script otomatik yapacak)
# Yoksa: cd ABC_Firma && docker-compose up -d
```

**Erişim**: http://localhost:8088 (admin / admin123)

---

## 📊 VERİ YÜKLEME

### Hızlı Test (Python Script)
```bash
python scripts/erp_to_clickhouse.py
```

### Manuel (SQL Lab)
```sql
CREATE TABLE erp_analytics.satislar (...) ENGINE = MergeTree() ORDER BY fatura_tarihi;
```

---

## 🔧 SIK KULLANILAN KOMUTLAR

```bash
# Servisleri başlat
docker-compose up -d

# Durumunu kontrol et
docker-compose ps

# Logları göster
docker-compose logs -f superset

# Yeniden başlat
docker-compose restart superset

# Durdur
docker-compose down

# Temiz kurulum (veriler korunur)
docker-compose down && docker-compose up -d
```

---

## 🏃 PERFORMANS İPUÇLARI

### Cache Ayarı (Dashboard'da)
- **Settings → Advanced → Cache Timeout**: `86400` (24 saat)
- **Refresh Interval**: `300` (5 dakika)

### ClickHouse Optimizasyonu
```sql
ALTER TABLE satislar ORDER BY (fatura_tarihi, urun_kodu);
```

---

## 🖥 ANDON EKRANI

### URL
```
http://IP:8088/superset/dashboard/1/?standalone=true
```

### Chrome Kiosk
```bash
chrome --kiosk --app="http://IP:8088/superset/dashboard/1/?standalone=true"
```

### Otomatik Yenileme
Dashboard → Settings → **Auto Refresh: 10 seconds**

---

## 🐛 SORUN GİDERME

| Sorun | Çözüm |
|-------|-------|
| Bağlantı hatası | `docker-compose logs clickhouse` |
| Yavaşlık | Redis cache kontrol et |
| Dashboard açılmıyor | `docker-compose restart superset` |
| Veri gelmiyor | `.env` dosyasını kontrol et |

---

## 📁 DOSYA YAPISI

```
ABC_Firma/
├── .env                    ← Müşteri bilgileri
├── docker-compose.yml      ← Sistem mimarisi
├── superset_config.py      ← Ayarlar
└── data/                   ← Veriler (yedekle!)
    ├── clickhouse/
    ├── postgres/
    └── superset_home/
```

---

## 🔐 GÜVENLİK

### Şifre Değiştir
`.env` → `SUPERSET_ADMIN_PASS=yeni_sifre`
```bash
docker-compose restart superset
```

### Satır Bazlı Güvenlik (RLS)
Settings → Row Level Security → Filter: `musteri_kodu = '{{ current_username() }}'`

---

## ⏱ KURULUM SÜRELERİ

- **İlk kurulum**: 30 dakika
- **İkinci kurulum**: 10 dakika
- **Veri yükleme**: 2-5 dakika
- **Dashboard oluşturma**: 5 dakika

**Toplam**: ~50 dakika → Sonraki müşteriler: ~20 dakika

---

## 📞 ACIL DURUM

```bash
# Tümünü durdur
docker-compose down

# Cache temizle
docker-compose exec redis redis-cli FLUSHALL

# Yeniden başlat
docker-compose up -d
```

---

**Bu kartı yazdırın ve masanızda tutun!** 📌
