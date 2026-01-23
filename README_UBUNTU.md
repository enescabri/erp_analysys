# 🐧 UBUNTU SERVER KURULUM REHBERİ

**ERP Analiz Paketi - Ubuntu Server Hızlı Kurulum**

---

## 🚀 HIZLI KURULUM (Tek Komut)

### Adım 1: Ubuntu Server'a SSH ile Bağlan

```bash
ssh kullanici@sunucu-ip
```

### Adım 2: Kurulum Script'ini İndir ve Çalıştır

```bash
# GitHub'dan script'i indir
wget https://raw.githubusercontent.com/KULLANICI_ADI/erp_analiz_paketi/main/ubuntu_install.sh

# Çalıştırma izni ver
chmod +x ubuntu_install.sh

# Kurulumu başlat
./ubuntu_install.sh ABC_MUSTERI
```

**Script ne yapar?**
1. Sistemi günceller
2. Docker ve Docker Compose kurar
3. Güvenlik ayarlarını yapar (Firewall)
4. Sistem optimizasyonu (ClickHouse için)
5. GitHub'dan paketi klonlar
6. Müşteri kurulum klasörünü oluşturur
7. .env dosyasını düzenlemeniz için açar
8. Docker servislerini başlatır
9. Superset admin kullanıcısı oluşturur

**Süre**: ~10 dakika

---

## 📋 ADIM ADIM MANUEL KURULUM

### 1️⃣ Sistemi Güncelle

```bash
sudo apt update && sudo apt upgrade -y
```

### 2️⃣ Gerekli Paketleri Kur

```bash
sudo apt install -y curl wget git htop nano net-tools
```

### 3️⃣ Docker Kur

```bash
# Docker resmi kurulum scripti
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Kullanıcıyı docker grubuna ekle
sudo usermod -aG docker $USER

# Oturumu yenile
newgrp docker

# Test
docker --version
```

### 4️⃣ Docker Compose Kur

```bash
sudo apt install -y docker-compose-plugin

# Test
docker compose version
```

### 5️⃣ Docker Servisini Başlat

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

### 6️⃣ GitHub Repo'sunu Klonla

```bash
# Çalışma dizini oluştur
mkdir -p ~/erp-analiz
cd ~/erp-analiz

# Repo'yu klonla
git clone https://github.com/KULLANICI_ADI/erp_analiz_paketi.git
cd erp_analiz_paketi
```

### 7️⃣ Müşteri Kurulumu Oluştur

```bash
# Müşteri klasörü
MUSTERI="ABC_MUSTERI"
mkdir -p ~/erp-analiz/$MUSTERI

# Dosyaları kopyala
cp docker-compose.minimal.yml ~/erp-analiz/$MUSTERI/docker-compose.yml
cp superset_config.py ~/erp-analiz/$MUSTERI/
cp .env.example ~/erp-analiz/$MUSTERI/.env
cp ofelia.ini ~/erp-analiz/$MUSTERI/
cp -r dbt_project ~/erp-analiz/$MUSTERI/
cp -r dbt_profiles ~/erp-analiz/$MUSTERI/
mkdir -p ~/erp-analiz/$MUSTERI/logs

cd ~/erp-analiz/$MUSTERI
```

### 8️⃣ .env Dosyasını Düzenle

```bash
nano .env
```

Düzenle:
```ini
MUSTERI_ADI=ABC_MUSTERI
ERP_DB_HOST=192.168.1.100
ERP_DB_NAME=WORKCUBE_ABC
ERP_DB_USER=raporlama
ERP_DB_PASSWORD=sifre123
SQL_QUERY_FILE=workcube_satislar.sql
WC_BASE_SCHEMA=workcube_prod
WC_PERIOD_YEAR=2026
WC_COMPANY_ID=1
SECRET_KEY=DEGISTIR_bu_anahtari_256bit
```

Kaydet: `Ctrl+X`, `Y`, `Enter`

### 9️⃣ Docker Servislerini Başlat

```bash
docker compose up -d
```

### 🔟 Servislerin Hazır Olmasını Bekle

```bash
# Durumu kontrol et
docker compose ps

# Logları izle
docker compose logs -f
```

Tüm servisler "healthy" olmalı (~2 dakika)

### 1️⃣1️⃣ Superset Admin Oluştur

```bash
docker exec -it ABC_MUSTERI_superset superset fab create-admin \
  --username admin \
  --firstname Admin \
  --lastname User \
  --email admin@test.com \
  --password admin123

docker exec -it ABC_MUSTERI_superset superset db upgrade
docker exec -it ABC_MUSTERI_superset superset init
```

### 1️⃣2️⃣ Test Et

```bash
# ClickHouse test
docker exec ABC_MUSTERI_clickhouse clickhouse-client -q "SELECT 1"

# Veri çekme test
docker exec ABC_MUSTERI_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py
```

---

## 🌐 ERİŞİM

### Superset Dashboard

```
http://SUNUCU-IP:8088
Kullanıcı: admin
Şifre: admin123
```

### Server IP'sini Öğren

```bash
hostname -I
# veya
ip addr show
```

---

## 🔒 GÜVENLİK AYARLARI

### Firewall (UFW) Kur

```bash
sudo apt install -y ufw

# Kurallar
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp          # SSH
sudo ufw allow 8088/tcp        # Superset

# Aktif et
sudo ufw enable

# Durumu kontrol
sudo ufw status
```

### ClickHouse'u İnternete Açma!

docker-compose.yml'de:
```yaml
ports:
  - "127.0.0.1:8123:8123"  # Sadece localhost
```

### SSH Güvenliği

```bash
# SSH yapılandırması
sudo nano /etc/ssh/sshd_config
```

Değiştir:
```
PermitRootLogin no
PasswordAuthentication no  # Key-based login için
```

Yeniden başlat:
```bash
sudo systemctl restart sshd
```

---

## 📊 SİSTEM İZLEME

### Docker Durumu

```bash
# Çalışan container'lar
docker ps

# Kaynak kullanımı
docker stats

# Servis durumu
docker compose ps

# Loglar
docker compose logs -f
docker compose logs clickhouse
docker compose logs superset
```

### Sistem Kaynakları

```bash
# CPU/RAM
htop

# Disk kullanımı
df -h

# Docker disk kullanımı
docker system df
```

---

## 🛠 YARINLI KOMUTLAR

### Docker Compose Komutları

```bash
cd ~/erp-analiz/ABC_MUSTERI

# Durumu göster
docker compose ps

# Logları izle
docker compose logs -f --tail=50

# Servisi yeniden başlat
docker compose restart superset

# Tümünü yeniden başlat
docker compose restart

# Durdur
docker compose down

# Başlat
docker compose up -d

# Güncelleme sonrası yeniden başlat
docker compose down
docker compose pull
docker compose up -d
```

### Veri Çekme

```bash
# Manuel veri çekme
docker exec ABC_MUSTERI_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py

# Ofelia logları (zamanlayıcı)
docker logs ABC_MUSTERI_scheduler -f

# dbt çalıştır
docker exec ABC_MUSTERI_dbt dbt run
```

### Yedekleme

```bash
# ClickHouse verilerini yedekle
sudo tar -czf backup-$(date +%Y%m%d).tar.gz ~/erp-analiz/ABC_MUSTERI/data/

# Superset metadata yedekle
docker exec ABC_MUSTERI_postgres pg_dump -U superset superset_metadata > backup_superset.sql
```

---

## 🆘 SORUN GİDERME

### Docker Daemon Çalışmıyor

```bash
sudo systemctl status docker
sudo systemctl start docker
```

### Port Zaten Kullanılıyor

```bash
# Port'u kullanan process'i bul
sudo netstat -tulpn | grep 8088

# Process'i durdur
sudo kill -9 PID
```

### Container Restart Oluyor

```bash
# Logları kontrol et
docker logs ABC_MUSTERI_superset

# Health check
docker inspect ABC_MUSTERI_clickhouse | grep -A 10 Health
```

### Disk Dolu

```bash
# Docker temizliği
docker system prune -a

# Kullanılmayan volume'leri sil
docker volume prune
```

---

## 🔄 GÜNCELLEME

### Paket Güncellemesi

```bash
cd ~/erp-analiz/erp_analiz_paketi

# Son versiyonu çek
git pull

# Müşteri kurulumunu güncelle
cd ~/erp-analiz/ABC_MUSTERI
docker compose down
docker compose pull
docker compose up -d
```

---

## 📞 DESTEK

### Loglar

```bash
# Tüm servisler
docker compose logs

# Son 100 satır
docker compose logs --tail=100

# Canlı takip
docker compose logs -f

# Belirli servis
docker compose logs superset -f
```

### Sistem Bilgisi

```bash
# Docker version
docker version
docker compose version

# Sistem bilgisi
uname -a
lsb_release -a
free -h
df -h
```

---

## 🎯 BAŞARI KRİTERLERİ

✅ docker compose ps → Tüm servisler "Up" ve "(healthy)"
✅ http://SUNUCU-IP:8088 → Superset açılıyor
✅ docker exec ABC_MUSTERI_clickhouse clickhouse-client -q "SELECT 1" → Sonuç: 1
✅ docker logs ABC_MUSTERI_scheduler → Ofelia çalışıyor

---

## 📚 EK KAYNAKLAR

- [KURULUM_ADIM_ADIM.md](KURULUM_ADIM_ADIM.md) - Detaylı Windows kurulum
- [DOKUMANTASYON_INDEX.md](DOKUMANTASYON_INDEX.md) - Tüm dokümantasyon
- [SEMA_PARAMETRELERI.md](SEMA_PARAMETRELERI.md) - Workcube şema parametreleri
- [VERİ_AKISI_OZET.md](VERİ_AKISI_OZET.md) - Veri akış şeması

---

**Oluşturulma**: 2026-01-18
**Platform**: Ubuntu Server 22.04 LTS
**Versiyon**: 3.2
