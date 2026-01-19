#!/bin/bash
# Yeni Müşteri Kurulum Scripti
# Kullanım: ./yeni_musteri.sh ABC_Firma

MUSTERI_ADI=$1

if [ -z "$MUSTERI_ADI" ]; then
    echo "❌ Kullanım: ./yeni_musteri.sh MUSTERI_ADI"
    exit 1
fi

echo "📦 Yeni müşteri klasörü oluşturuluyor: $MUSTERI_ADI"

# Paketi kopyala
cp -r erp_analiz_paketi $MUSTERI_ADI
cd $MUSTERI_ADI

# .env dosyasını düzenle
sed -i "s/MUSTERI_ADI=Ornek_Firma/MUSTERI_ADI=$MUSTERI_ADI/g" .env

echo "✅ Kurulum tamamlandı!"
echo ""
echo "📝 Şimdi yapmanız gerekenler:"
echo "1. cd $MUSTERI_ADI"
echo "2. nano .env  (ERP bağlantı bilgilerini girin)"
echo "3. docker-compose up -d"
echo ""
echo "🌐 Adresler:"
echo "   Superset: http://localhost:8088"
echo "   Airflow:  http://localhost:8080"
