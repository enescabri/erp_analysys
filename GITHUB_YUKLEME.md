# 📦 GITHUB'A YÜKLEME REHBERİ

**ERP Analiz Paketi'ni GitHub'a yükleyip Ubuntu Server'dan çekin**

---

## 🎯 AMAÇ

1. Projeyi GitHub'a public/private repo olarak yükle
2. Ubuntu Server'dan `git clone` ile çek
3. Güncellemeleri `git pull` ile al

---

## 📋 ADIM 1: GITHUB REPO OLUŞTUR

### GitHub.com'da:

1. https://github.com → Sign in
2. Sağ üst **+** → **New repository**
3. Repository name: `erp_analiz_paketi`
4. Description: `ERP Analiz Paketi - ClickHouse + dbt + Superset`
5. **Public** veya **Private** seç
6. ❌ **Initialize this repository with a README** işaretleme (zaten var)
7. **Create repository**

**Repo URL'niz**:
```
https://github.com/KULLANICI_ADI/erp_analiz_paketi.git
```

---

## 📋 ADIM 2: LOKAL REPO'YU HAZIRLA

### Windows'ta (Projenin olduğu yerde):

```bash
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi

# Git init (eğer yoksa)
git init

# .gitignore kontrol (zaten var)
cat .gitignore

# Tüm dosyaları ekle
git add .

# İlk commit
git commit -m "Initial commit - ERP Analiz Paketi v3.2"

# Uzak repo ekle (KULLANICI_ADI'nı değiştir!)
git remote add origin https://github.com/KULLANICI_ADI/erp_analiz_paketi.git

# Ana branch'i main yap (eğer master ise)
git branch -M main

# GitHub'a pushla
git push -u origin main
```

**İlk push'ta kullanıcı adı/şifre sorar:**
- **Username**: GitHub kullanıcı adınız
- **Password**: Personal Access Token (PAT) kullanın
  - GitHub → Settings → Developer settings → Personal access tokens → Generate new token (classic)
  - Seçenekler: repo (tüm kutuları işaretle)
  - Token'ı kopyala ve sakla!

---

## 📋 ADIM 3: UBUNTU SERVER'A KLONLA

### SSH ile Ubuntu'ya bağlan:

```bash
ssh kullanici@sunucu-ip
```

### Repo'yu klonla:

```bash
# Çalışma dizini oluştur
mkdir -p ~/erp-analiz
cd ~/erp-analiz

# GitHub'dan klonla (KULLANICI_ADI'nı değiştir!)
git clone https://github.com/KULLANICI_ADI/erp_analiz_paketi.git

cd erp_analiz_paketi
```

**Private repo ise:**
- Kullanıcı adı/token sorar
- Personal Access Token kullan

**Alternatif (SSH key ile - önerilir):**

```bash
# Ubuntu'da SSH key oluştur
ssh-keygen -t ed25519 -C "sunucu@erp-analiz"

# Public key'i kopyala
cat ~/.ssh/id_ed25519.pub
```

GitHub'da:
1. Settings → SSH and GPG keys → New SSH key
2. Key'i yapıştır → Add SSH key

Sonra HTTPS yerine SSH URL kullan:
```bash
git clone git@github.com:KULLANICI_ADI/erp_analiz_paketi.git
```

---

## 📋 ADIM 4: KURULUMA DEVAM

### Otomatik kurulum script'i:

```bash
cd ~/erp-analiz/erp_analiz_paketi

chmod +x ubuntu_install.sh
./ubuntu_install.sh ABC_MUSTERI
```

**VEYA**

### Manuel kurulum:

```bash
# Müşteri klasörü oluştur
MUSTERI="ABC_MUSTERI"
mkdir -p ~/erp-analiz/$MUSTERI

# Dosyaları kopyala
cp docker-compose.minimal.yml ~/erp-analiz/$MUSTERI/docker-compose.yml
cp superset_config.py ~/erp-analiz/$MUSTERI/
cp .env ~/erp-analiz/$MUSTERI/
cp ofelia.ini ~/erp-analiz/$MUSTERI/
cp -r dbt_project ~/erp-analiz/$MUSTERI/
cp -r dbt_profiles ~/erp-analiz/$MUSTERI/
mkdir -p ~/erp-analiz/$MUSTERI/logs

cd ~/erp-analiz/$MUSTERI

# .env düzenle
nano .env

# Docker başlat
docker compose up -d
```

---

## 🔄 GÜNCELLEME İŞLEMİ

### Windows'ta (Geliştirme):

```bash
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi

# Değişiklikleri ekle
git add .

# Commit
git commit -m "Yeni özellik: LOGO ERP desteği eklendi"

# GitHub'a pushla
git push
```

### Ubuntu'da (Sunucu):

```bash
cd ~/erp-analiz/erp_analiz_paketi

# Son versiyonu çek
git pull

# Müşteri kurulumunu güncelle (gerekirse)
cd ~/erp-analiz/ABC_MUSTERI
docker compose down
docker compose pull
docker compose up -d
```

---

## 🔐 GÜVENLİK ÖNERİLERİ

### 1. .env Dosyası Koruması

**.gitignore zaten içeriyor:**
```gitignore
*_MUSTERI/.env
*_Firma/.env
TEST_*/.env
```

**Ama yine de kontrol edin:**
```bash
# Windows'ta
git status

# .env görünüyorsa:
git rm --cached .env
git commit -m "Remove .env from tracking"
```

### 2. Private Repo Kullan

- **Üretim kurulumları için Private repo şart!**
- Müşteri bilgileri hassas olabilir

### 3. GitHub Actions ile Otomasyonf (İleri Seviye)

`.github/workflows/deploy.yml`:
```yaml
name: Deploy to Ubuntu Server

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd ~/erp-analiz/erp_analiz_paketi
            git pull
            docker compose restart
```

---

## 📊 DOSYA YAPISI (GitHub'da)

```
erp_analiz_paketi/
├── README.md                      ← Ana açıklama
├── README_UBUNTU.md               ← Ubuntu kurulum
├── GITHUB_YUKLEME.md              ← Bu dosya
├── KURULUM_ADIM_ADIM.md           ← Windows kurulum
├── DOKUMANTASYON_INDEX.md         ← Tüm dokümantasyon
├── docker-compose.minimal.yml     ← 6 servis
├── .env                           ← Şablon (örnek değerlerle)
├── superset_config.py
├── ofelia.ini
├── ubuntu_install.sh              ← Otomatik kurulum scripti
├── kur.bat                        ← Windows kurulum scripti
├── .gitignore                     ← Güvenlik
├── dbt_project/
│   ├── dbt_project.yml
│   ├── models/
│   └── scripts/
│       ├── erp_to_clickhouse_v2.py
│       └── queries/
│           ├── workcube_satislar.sql
│           └── odoo_satislar.sql
├── dbt_profiles/
│   └── profiles.yml
└── (TEST_KURULUM_2/ ignore edilir)
```

---

## 🎯 HIZLI KOMUT ÖZETİ

### İlk Yükleme (Windows):

```bash
cd D:\PROJECTS\DATA_ANALYSIS_AND_BI_TOOL\erp_analiz_paketi
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/KULLANICI_ADI/erp_analiz_paketi.git
git branch -M main
git push -u origin main
```

### Ubuntu'dan Çekme:

```bash
# Tek komut kurulum
wget https://raw.githubusercontent.com/KULLANICI_ADI/erp_analiz_paketi/main/ubuntu_install.sh
chmod +x ubuntu_install.sh
./ubuntu_install.sh ABC_MUSTERI
```

**VEYA**

```bash
cd ~/erp-analiz
git clone https://github.com/KULLANICI_ADI/erp_analiz_paketi.git
cd erp_analiz_paketi
# Manuel kuruluma devam...
```

### Güncelleme (Her İki Taraf):

```bash
# Windows'ta
git add .
git commit -m "Güncelleme"
git push

# Ubuntu'da
git pull
```

---

## ✅ KONTROL LİSTESİ

Windows'ta (GitHub'a yüklemeden önce):
- [ ] .gitignore güncel
- [ ] Test klasörleri ignore ediliyor (*_MUSTERI/, TEST_*)
- [ ] .env şablon değerlerle (gerçek şifre yok!)
- [ ] README.md güncel
- [ ] ubuntu_install.sh çalıştırma izni var (`chmod +x`)

GitHub'da:
- [ ] Repo oluşturuldu (public/private)
- [ ] İlk push başarılı
- [ ] Dosyalar görünüyor
- [ ] .env hassas bilgi içermiyor

Ubuntu'da:
- [ ] git clone başarılı
- [ ] ubuntu_install.sh çalışıyor
- [ ] Docker servisleri ayakta
- [ ] Superset erişilebilir

---

## 🆘 SORUN GİDERME

### "Permission denied (publickey)"

```bash
# SSH key oluştur
ssh-keygen -t ed25519

# GitHub'a ekle
cat ~/.ssh/id_ed25519.pub
# GitHub → Settings → SSH keys → Add
```

### "Authentication failed"

- Personal Access Token kullan (şifre değil!)
- GitHub → Settings → Developer settings → Personal access tokens

### ".env dosyası GitHub'da görünüyor"

```bash
# Hemen kaldır!
git rm --cached .env
git commit -m "Remove .env"
git push

# Şifreleri değiştir!
```

### "fatal: not a git repository"

```bash
# git init unutulmuş
git init
git add .
git commit -m "Initial commit"
```

---

**Hazırladık! GitHub'a yükleyip Ubuntu'dan çekmeye hazırsınız.** 🚀

Sonraki adım: `README_UBUNTU.md` dosyasındaki komutlarla Ubuntu Server'a kurulum.

---

**Oluşturulma**: 2026-01-18
**Versiyon**: 1.0
