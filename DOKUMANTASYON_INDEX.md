# 📚 ERP ANALİZ PAKETİ - DOKÜMANTASYON İNDEKS

**Versiyon**: 3.2
**Son Güncelleme**: 2026-01-18
**Durum**: ✅ Üretim Hazır

---

## 🚀 HIZLI BAŞLANGIÇ

### Yeni Müşteri Kurulumu İçin:
1. **[KURULUM_ADIM_ADIM.md](KURULUM_ADIM_ADIM.md)** ← **BURADAN BAŞLAYIN**
   - 11 adımlık detaylı kurulum rehberi
   - Her adımda komutlar, süreler, beklenen çıktılar
   - Hata çözümleri ve kontrol listeleri

### Sistem Hakkında Genel Bilgi İçin:
2. **[README.md](README.md)**
   - Sistem mimarisi ve bileşenler
   - Teknoloji stack'i açıklaması
   - Genel özellikler ve yetenekler

---

## 📖 DETAYLI REHBERLER

### 🔧 Kurulum ve Yapılandırma

| Dosya | İçerik | Ne Zaman Kullanılır |
|-------|--------|---------------------|
| **[KURULUM_ADIM_ADIM.md](KURULUM_ADIM_ADIM.md)** | Adım adım kurulum (11 aşama) | Her yeni müşteri kurulumunda |
| **[KURULUM_ADIMLARI.md](KURULUM_ADIMLARI.md)** | Alternatif kurulum rehberi | Referans olarak |
| **[HIZLI_REFERANS.md](HIZLI_REFERANS.md)** | Hızlı komut ve ayar referansı | Günlük kullanımda |

### 📊 SQL ve Veri Çekme

| Dosya | İçerik | Ne Zaman Kullanılır |
|-------|--------|---------------------|
| **[SQL_SORGU_REHBERI.md](SQL_SORGU_REHBERI.md)** | SQL şablon oluşturma rehberi | Yeni ERP tipi eklerken |
| **[SEMA_PARAMETRELERI.md](SEMA_PARAMETRELERI.md)** | Şema parametre sistemi ({{dsn}}, {{dsn2}}) | Workcube kurulumlarında |
| **[VERİ_AKISI_OZET.md](VERİ_AKISI_OZET.md)** | Veri akış görsel özeti | Sistemi anlamak için |

### 🧪 Test ve Doğrulama

| Dosya | İçerik | Ne Zaman Kullanılır |
|-------|--------|---------------------|
| **[KURULUM_TEST.md](KURULUM_TEST.md)** | Test senaryoları ve komutları | Kurulum sonrası doğrulama |
| **[TEST_FIRMA/TEST_RAPORU.md](TEST_FIRMA/TEST_RAPORU.md)** | kur.bat test raporu | Script güncellemelerinde |

---

## 🎯 KULLANIM SENARYOLARI

### Senaryo 1: Yeni Workcube Müşterisi Ekleme

```
1. KURULUM_ADIM_ADIM.md → Adım 1-4 (Kurulum + .env düzenleme)
2. SEMA_PARAMETRELERI.md → Şema parametrelerini öğren
3. .env dosyasında:
   - WC_BASE_SCHEMA
   - WC_PERIOD_YEAR
   - WC_COMPANY_ID
   ayarla
4. KURULUM_ADIM_ADIM.md → Adım 5-11 (Devam et)
```

### Senaryo 2: Yeni ERP Tipi Ekleme (Odoo, LOGO, vs.)

```
1. SQL_SORGU_REHBERI.md → SQL şablonu nasıl oluşturulur öğren
2. VERİ_AKISI_OZET.md → Veri akışını anla
3. queries/ klasöründe yeni_erp_satislar.sql oluştur
4. .env'de SQL_QUERY_FILE=yeni_erp_satislar.sql ayarla
5. KURULUM_TEST.md → Test komutlarıyla doğrula
```

### Senaryo 3: Sorun Giderme

```
1. KURULUM_ADIM_ADIM.md → Adım 11'deki sorun giderme tablosu
2. HIZLI_REFERANS.md → İlgili bölüm (Docker/Superset/ClickHouse)
3. Docker logları kontrol:
   docker logs MUSTERI_dbt
   docker logs MUSTERI_scheduler
```

### Senaryo 4: Sistem Mimarisini Anlama

```
1. README.md → Genel mimari
2. VERİ_AKISI_OZET.md → Veri akış görsel şeması
3. SEMA_PARAMETRELERI.md → Parametre sistemi
```

---

## 📁 DOSYA YAPISI VE İLİŞKİLER

```
erp_analiz_paketi/
│
├── 🚀 BAŞLANGIÇ NOKTALARİ
│   ├── KURULUM_ADIM_ADIM.md        ← Yeni kurulum için BURADAN
│   └── README.md                    ← Sistem hakkında bilgi için BURADAN
│
├── 🔧 KURULUM DOSYALARI
│   ├── kur.bat                      → Otomatik kurulum scripti
│   ├── docker-compose.minimal.yml   → 6 servis tanımı
│   ├── .env                         → TÜM yapılandırma BURADA
│   ├── ofelia.ini                   → Zamanlama (cron)
│   └── superset_config.py           → Superset ayarları
│
├── 📊 VERİ ÇEKME
│   ├── dbt_project/
│   │   └── scripts/
│   │       ├── erp_to_clickhouse_v2.py  → Ana veri çekme scripti
│   │       └── queries/
│   │           ├── workcube_satislar.sql  → Workcube şablonu
│   │           └── odoo_satislar.sql      → Odoo şablonu
│   │
│   └── dbt_project/models/
│       └── fct_satislar_hazir.sql   → dbt transformasyon modeli
│
└── 📚 DOKÜMANTASYON
    ├── DOKUMANTASYON_INDEX.md       ← BU DOSYA (navigasyon)
    ├── KURULUM_ADIM_ADIM.md         → Detaylı kurulum
    ├── SEMA_PARAMETRELERI.md        → {{dsn}} parametre sistemi
    ├── VERİ_AKISI_OZET.md           → Veri akış görsel şeması
    ├── SQL_SORGU_REHBERI.md         → SQL şablon oluşturma
    ├── HIZLI_REFERANS.md            → Komut referansı
    ├── KURULUM_ADIMLARI.md          → Alternatif rehber
    └── KURULUM_TEST.md              → Test senaryoları
```

---

## 🔄 GÜNCELLEME PROTOKOLÜ

Bu sistem "yaşayan dokümantasyon" prensibiyle tasarlandı. Sistem değiştiğinde dokümantasyon da güncellenir.

### Güncelleme Gerektiren Durumlar:

1. **Yeni Servis Eklendi** → docker-compose.minimal.yml değişti
   - Güncelle: KURULUM_ADIM_ADIM.md (Adım 4)
   - Güncelle: README.md (Mimari bölümü)

2. **.env'ye Yeni Parametre Eklendi**
   - Güncelle: KURULUM_ADIM_ADIM.md (Adım 2 - .env tablosu)
   - Güncelle: İlgili özel rehber (SEMA_PARAMETRELERI.md, SQL_SORGU_REHBERI.md)

3. **Yeni SQL Şablonu Eklendi**
   - Güncelle: SQL_SORGU_REHBERI.md (Örnekler bölümü)
   - Güncelle: VERİ_AKISI_OZET.md (Müşteri örnekleri)

4. **kur.bat Değişti**
   - Test et: TEST_FIRMA/ klasöründe
   - Güncelle: TEST_FIRMA/TEST_RAPORU.md
   - Güncelle: KURULUM_ADIM_ADIM.md (Adım 1)

### Versiyon Numaraları:

- **3.0**: İlk stabil versiyon (Ofelia entegrasyonu)
- **3.1**: SQL şablon sistemi eklendi
- **3.2**: Şema parametre sistemi ({{dsn}}, {{dsn2}}) eklendi
- **3.3**: (Gelecek) - İlave özellikler

Her .md dosyasının sonunda versiyon ve tarih bilgisi var:
```markdown
**Güncellenme**: 2026-01-18
**Versiyon**: 3.2
```

---

## 💡 İPUÇLARI

### Yeni Kullanıcılar İçin:
1. Önce **KURULUM_ADIM_ADIM.md** dosyasını baştan sona okuyun
2. Bir test kurulumu yapın (TEST_FIRMA gibi)
3. Gerçek müşteriye geçmeden önce test edin

### Deneyimli Kullanıcılar İçin:
1. **HIZLI_REFERANS.md** günlük kullanım için yeterli
2. Sorun olursa KURULUM_ADIM_ADIM.md → Adım 11 (Sorun Giderme)

### Özel Durumlar İçin:
- Workcube farklı şema yapısı → **SEMA_PARAMETRELERI.md**
- Yeni ERP tipi → **SQL_SORGU_REHBERI.md**
- Veri akışını anlama → **VERİ_AKISI_OZET.md**

---

## 📞 DESTEK VE SORUN GİDERME

### Log Dosyaları:

```bash
# Tüm servisler
docker-compose logs

# Veri çekme
docker logs MUSTERI_dbt -f

# Zamanlama
docker logs MUSTERI_scheduler -f

# Superset
docker logs MUSTERI_superset -f

# ClickHouse
docker logs MUSTERI_clickhouse -f
```

### Yaygın Sorunlar:

| Sorun | Bakılacak Doküman |
|-------|-------------------|
| Kurulum başarısız | KURULUM_ADIM_ADIM.md → Adım 11 |
| SQL şablonu çalışmıyor | SQL_SORGU_REHBERI.md → Hata Ayıklama |
| Şema isimleri yanlış | SEMA_PARAMETRELERI.md → Örnekler |
| Veri gelmiyor | VERİ_AKISI_OZET.md → 5 Adım |
| Dashboard yavaş | README.md → Redis Cache bölümü |

---

## ✅ BAŞARI KRİTERLERİ

Kurulum başarılı sayılır:

- [ ] `docker-compose ps` → Tüm 6 servis "healthy"
- [ ] `docker exec MUSTERI_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py` → Veri çekildi
- [ ] `docker exec MUSTERI_dbt dbt run` → Transformasyon başarılı
- [ ] Superset → ClickHouse bağlantısı test OK
- [ ] İlk dashboard oluşturuldu ve 1 saniyeden hızlı açıldı
- [ ] Ofelia log'unda cron job çalışıyor görünüyor

Detaylı checklist: **KURULUM_ADIM_ADIM.md → Adım 9**

---

## 🎓 ÖĞRENİM YOLU

Sistemi öğrenmek için önerilen sıra:

### Gün 1: Temel Kurulum
1. README.md (mimari anlayın - 15 dk)
2. KURULUM_ADIM_ADIM.md (test kurulum yapın - 30 dk)
3. HIZLI_REFERANS.md (komutları ezberleyin - 10 dk)

### Gün 2: Veri Akışı
1. VERİ_AKISI_OZET.md (veri akışını anlayın - 20 dk)
2. SQL_SORGU_REHBERI.md (SQL şablon oluşturun - 30 dk)
3. İlk gerçek müşteri kurulumu (60 dk)

### Gün 3: İleri Seviye
1. SEMA_PARAMETRELERI.md (Workcube parametreleri - 20 dk)
2. KURULUM_TEST.md (test senaryoları - 30 dk)
3. İkinci müşteri kurulumu (artık 15 dk!) 🎉

---

**Oluşturulma**: 2026-01-18
**Versiyon**: 1.0
**Amaç**: Tüm dokümantasyonu tek noktadan yönetmek ve kolay navigasyon sağlamak
