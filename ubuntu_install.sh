#!/bin/bash
# ================================================================
# ERP ANALİZ PAKETİ - UBUNTU SERVER KURULUMU
# ================================================================
# Bu script Ubuntu Server'a ERP Analiz Paketi'ni kurar
# Kullanım:
#   chmod +x ubuntu_install.sh
#   ./ubuntu_install.sh MUSTERI_ADI
# ================================================================

set -e  # Hata durumunda dur

# Renkli çıktı
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log fonksiyonu
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[HATA]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[UYARI]${NC} $1"
}

# Banner
echo ""
echo "================================================================"
echo "   ERP ANALİZ PAKETİ - UBUNTU SERVER KURULUMU"
echo "================================================================"
echo ""

# Müşteri adı kontrolü
MUSTERI_ADI=$1
if [ -z "$MUSTERI_ADI" ]; then
    error "Kullanım: ./ubuntu_install.sh MUSTERI_ADI"
fi

log "Müşteri: $MUSTERI_ADI"

# Root kontrolü
if [ "$EUID" -eq 0 ]; then
    warning "Bu script'i root olarak çalıştırmayın!"
    warning "Sudo gerektiğinde otomatik soracak."
fi

# ================================================================
# 1. SİSTEM GÜNCELLEMESİ
# ================================================================
log "Sistem güncelleniyor..."
sudo apt update
sudo apt upgrade -y

# ================================================================
# 2. GEREKLI PAKETLER
# ================================================================
log "Gerekli paketler kuruluyor..."
sudo apt install -y \
    curl \
    wget \
    git \
    htop \
    nano \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release

# ================================================================
# 3. DOCKER KURULUMU
# ================================================================
if command -v docker &> /dev/null; then
    log "Docker zaten kurulu: $(docker --version)"
else
    log "Docker kuruluyor..."

    # Docker resmi kurulum scripti
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh

    # Kullanıcıyı docker grubuna ekle
    sudo usermod -aG docker $USER

    log "Docker kuruldu: $(docker --version)"
fi

# ================================================================
# 4. DOCKER COMPOSE KURULUMU
# ================================================================
if command -v docker compose &> /dev/null; then
    log "Docker Compose zaten kurulu"
else
    log "Docker Compose plugin kuruluyor..."
    sudo apt install -y docker-compose-plugin
fi

# ================================================================
# 5. DOCKER SERVİSİNİ BAŞLAT
# ================================================================
log "Docker servisi başlatılıyor..."
sudo systemctl enable docker
sudo systemctl start docker

# Docker grubunu aktif et (logout/login gerektirmeden)
# Not: Script içinde çalışmaz ama sonraki komutlar için hazırlanır
log "Docker grubu aktif ediliyor..."
# newgrp komutu interaktif olduğu için script içinde çalışmaz
# Kullanıcı script bittikten sonra logout/login yapmalı veya:
# newgrp docker

# ================================================================
# 6. GÜVENLİK AYARLARI
# ================================================================
log "Güvenlik ayarları yapılıyor..."

# Firewall (UFW) kur
if ! command -v ufw &> /dev/null; then
    sudo apt install -y ufw
fi

# Firewall kuralları (interaktif onay sormasın diye -y kullan)
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp          # SSH
sudo ufw allow 8088/tcp        # Superset
# ClickHouse'u internete AÇMAYIN! (127.0.0.1:8123 olmalı)

log "Firewall kuralları ayarlandı"

# ================================================================
# 7. PERFORMANS OPTİMİZASYONU
# ================================================================
log "Sistem optimizasyonu yapılıyor..."

# ClickHouse için kernel parametreleri
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF

# ERP Analiz Paketi - ClickHouse Optimizasyonu
vm.swappiness = 10
vm.overcommit_memory = 1
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
EOF

sudo sysctl -p > /dev/null

# ================================================================
# 8. ÇALIŞMA DİZİNİ OLUŞTUR
# ================================================================
log "Çalışma dizini oluşturuluyor..."

WORK_DIR="$HOME/erp-analiz"
MUSTERI_DIR="$WORK_DIR/$MUSTERI_ADI"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# ================================================================
# 9. GIT REPO'SUNU KLONLA
# ================================================================
log "GitHub reposu klonlanıyor..."

if [ -d "erp_analiz_paketi" ]; then
    warning "Repo zaten mevcut, güncelleniyor..."
    cd erp_analiz_paketi
    git pull
    cd ..
else
    # Repo URL'sini kendi GitHub repo'nuzla değiştirin
    git clone https://github.com/KULLANICI_ADI/erp_analiz_paketi.git
fi

# ================================================================
# 10. MÜŞTERİ KURULUMU
# ================================================================
log "Müşteri kurulumu başlatılıyor: $MUSTERI_ADI"

cd erp_analiz_paketi

# Kurulum klasörü oluştur
mkdir -p "$MUSTERI_DIR"

# Dosyaları kopyala
cp docker-compose.minimal.yml "$MUSTERI_DIR/docker-compose.yml"
cp superset_config.py "$MUSTERI_DIR/"
cp .env "$MUSTERI_DIR/"
cp ofelia.ini "$MUSTERI_DIR/"

# dbt klasörlerini kopyala
cp -r dbt_project "$MUSTERI_DIR/"
cp -r dbt_profiles "$MUSTERI_DIR/"

# Logs klasörü
mkdir -p "$MUSTERI_DIR/logs"

log "Dosyalar kopyalandı: $MUSTERI_DIR"

# ================================================================
# 11. .ENV DOSYASINI DÜZENLE
# ================================================================
cd "$MUSTERI_DIR"

log "Şimdi .env dosyasını düzenlemeniz gerekiyor..."
log ""
echo "================================================================"
echo "  ÖNEMLI: .env dosyasını düzenleyin!"
echo "================================================================"
echo ""
echo "Aşağıdaki bilgileri doldurun:"
echo ""
echo "  1. MUSTERI_ADI=$MUSTERI_ADI"
echo "  2. ERP_DB_HOST=192.168.x.x"
echo "  3. ERP_DB_NAME=veritabani_adi"
echo "  4. ERP_DB_USER=kullanici"
echo "  5. ERP_DB_PASSWORD=sifre"
echo "  6. SQL_QUERY_FILE=workcube_satislar.sql (veya odoo, logo)"
echo "  7. WC_BASE_SCHEMA, WC_PERIOD_YEAR, WC_COMPANY_ID (Workcube ise)"
echo "  8. SECRET_KEY=rastgele_256bit_anahtar"
echo ""
echo "Düzenlemek için:"
echo "  nano .env"
echo ""
echo "Kaydet ve çık: Ctrl+X, Y, Enter"
echo ""
read -p "Enter'a basarak .env düzenlemesine geç..." dummy

nano .env

# ================================================================
# 12. DOCKER IMAGE'LERİNİ İNDİR (opsiyonel ama önerilir)
# ================================================================
log "Docker image'leri indiriliyor (bu biraz zaman alabilir)..."

docker pull clickhouse/clickhouse-server:23.8-alpine &
docker pull postgres:15-alpine &
docker pull redis:7-alpine &
docker pull ghcr.io/dbt-labs/dbt-clickhouse:1.7.0 &
docker pull mcuadros/ofelia:latest &
docker pull apache/superset:3.1.0 &

# Tüm pull işlemlerinin bitmesini bekle
wait

log "Tüm image'ler indirildi"

# ================================================================
# 13. SERVİSLERİ BAŞLAT
# ================================================================
log "Docker servisleri başlatılıyor..."

docker compose up -d

log "Servisler başlatıldı. Hazır olmaları bekleniyor (~2 dakika)..."
sleep 30

# ================================================================
# 14. SERVİS DURUMUNU KONTROL ET
# ================================================================
log "Servis durumu kontrol ediliyor..."

docker compose ps

# ================================================================
# 15. SUPERSET ADMIN OLUŞTUR
# ================================================================
log "Superset admin kullanıcısı oluşturuluyor..."

# Superset'in tamamen başlamasını bekle
sleep 30

docker exec -it ${MUSTERI_ADI}_superset superset fab create-admin \
    --username admin \
    --firstname Admin \
    --lastname User \
    --email admin@${MUSTERI_ADI}.com \
    --password admin123 || warning "Admin kullanıcısı zaten mevcut olabilir"

docker exec -it ${MUSTERI_ADI}_superset superset db upgrade
docker exec -it ${MUSTERI_ADI}_superset superset init

# ================================================================
# 16. TEST
# ================================================================
log "Sistem testi yapılıyor..."

# ClickHouse test
log "ClickHouse test..."
docker exec ${MUSTERI_ADI}_clickhouse clickhouse-client -q "SELECT 1" || error "ClickHouse bağlantı hatası!"

log "✅ ClickHouse çalışıyor"

# ================================================================
# KURULUM TAMAMLANDI!
# ================================================================
echo ""
echo "================================================================"
echo "   ✅ KURULUM TAMAMLANDI!"
echo "================================================================"
echo ""
echo "📊 Superset Dashboard:"
echo "   URL: http://$(hostname -I | awk '{print $1}'):8088"
echo "   Kullanıcı: admin"
echo "   Şifre: admin123"
echo ""
echo "📁 Kurulum klasörü:"
echo "   $MUSTERI_DIR"
echo ""
echo "🐳 Docker komutları:"
echo "   cd $MUSTERI_DIR"
echo "   docker compose ps              # Durum"
echo "   docker compose logs -f         # Loglar"
echo "   docker compose restart         # Yeniden başlat"
echo "   docker compose down            # Durdur"
echo "   docker compose up -d           # Başlat"
echo ""
echo "📝 Veri çekme testi:"
echo "   docker exec ${MUSTERI_ADI}_dbt python /usr/app/scripts/erp_to_clickhouse_v2.py"
echo ""
echo "⏰ Ofelia (zamanlayıcı) logları:"
echo "   docker logs ${MUSTERI_ADI}_scheduler -f"
echo ""
echo "🔄 ÖNEMLİ: Docker grubunun aktif olması için:"
echo "   Oturumu kapatıp açın VEYA şu komutu çalıştırın:"
echo "   newgrp docker"
echo ""
echo "================================================================"
echo ""

# Kurulum log dosyası
log "Kurulum tamamlandı: $(date)" | tee -a "$MUSTERI_DIR/kurulum.log"
