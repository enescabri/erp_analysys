# 🔧 DBT CONTAINER RESTART SORUNU - ÇÖZÜM

**Tarih**: 2026-01-24 23:30
**Sorun**: dbt container'ı sürekli "Restarting" durumunda

---

## ❌ SORUN

```bash
docker compose ps
```

Çıktı:
```
NAME                     STATUS
CabriBT_dbt              Restarting (2) Less than a second ago
```

---

## ✅ ÇÖZÜM

### Seçenek 1: GitHub'dan Son Versiyonu Çek (Önerilen)

```bash
cd ~/erp-analiz/erp_analiz_paketi

# Son versiyonu çek
git pull

# Güncellenen dosyayı müşteri klasörüne kopyala
cp docker-compose.minimal.yml ~/erp-analiz/ABC_MUSTERI/docker-compose.yml

# dbt container'ını yeniden oluştur
cd ~/erp-analiz/ABC_MUSTERI
docker compose stop dbt
docker compose rm -f dbt
docker compose up -d dbt

# Kontrol et
docker compose ps dbt
```

**Beklenen çıktı**: `Up` (artık "Restarting" olmamalı)

---

### Seçenek 2: Manuel Düzeltme

```bash
cd ~/erp-analiz/ABC_MUSTERI

# docker-compose.yml dosyasını düzenle
nano docker-compose.yml
```

**Bulunacak satırlar** (dbt servisi içinde):
```yaml
  dbt:
    ...
    command: tail -f /dev/null
```

**Değiştirilecek**:
```yaml
  dbt:
    ...
    command: ["tail", "-f", "/dev/null"]
```

**Not**: Komut array (dizi) formatında olmalı: `["tail", "-f", "/dev/null"]`

Kaydet: `Ctrl+X`, `Y`, `Enter`

**Container'ı yeniden oluştur**:
```bash
docker compose stop dbt
docker compose rm -f dbt
docker compose up -d dbt

# Kontrol et
docker compose ps dbt
```

---

## 🧪 TEST

```bash
# dbt container'ı çalışıyor mu?
docker compose ps dbt

# Beklenen: Up

# dbt içine girebiliyor muyuz?
docker exec -it ABC_MUSTERI_dbt bash

# İçindeyken:
dbt --version
exit
```

---

## 📋 SORUN NEDENİ

Eski syntax:
```yaml
command: tail -f /dev/null
```

Docker bu komutu shell olmadan çalıştırmaya çalışıyor ve `tail -f /dev/null` komutunu tek bir executable olarak arıyor (bulamıyor).

Doğru syntax:
```yaml
command: ["tail", "-f", "/dev/null"]
```

Bu, Docker'a komutu executable ve argümanlar olarak ayırmasını söyler:
- Executable: `tail`
- Arg 1: `-f`
- Arg 2: `/dev/null`

---

## 🎯 SONRAKI ADIMLAR

dbt container'ı düzeldikten sonra veri akışını kurabilirsiniz:

```bash
# 1. .env dosyasını düzenle (ERP bağlantısı)
cd ~/erp-analiz/ABC_MUSTERI
nano .env

# 2. Manuel veri çekme testi
docker exec ABC_MUSTERI_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py

# 3. dbt transformasyonları çalıştır
docker exec ABC_MUSTERI_dbt dbt run

# 4. ClickHouse'da veriyi kontrol et
docker exec -it ABC_MUSTERI_clickhouse clickhouse-client -q "SHOW TABLES"
```

---

**Oluşturulma**: 2026-01-24 23:30
**Commit**: 4f22235
