#!/usr/bin/env python3
"""
ERP'den ClickHouse'a Veri Yükleme (Basit Versiyon)
===================================================
dbt kullanmadan, doğrudan ERP'den veri çeker ve ClickHouse'a yazar.
İlk kurulumda hızlıca test için kullanılır.

Kullanım:
    python erp_to_clickhouse.py
"""

import os
import pandas as pd
import pymssql  # SQL Server için (pip install pymssql)
import clickhouse_connect  # pip install clickhouse-connect
from datetime import datetime, timedelta

# === YAPILANDIRMA (.env'den otomatik gelir) ===
ERP_CONFIG = {
    'server': os.getenv('ERP_DB_HOST', 'localhost'),
    'port': int(os.getenv('ERP_DB_PORT', 1433)),
    'database': os.getenv('ERP_DB_NAME', 'ERP_DB'),
    'user': os.getenv('ERP_DB_USER', 'sa'),
    'password': os.getenv('ERP_DB_PASSWORD', 'password')
}

CLICKHOUSE_CONFIG = {
    'host': 'localhost',
    'port': 8123
}

# === 1. ERP'DEN VERİ ÇEK ===
def extract_from_erp(days_back=30):
    """ERP'den son N günün satışlarını çeker"""
    print(f"🔄 ERP'ye bağlanılıyor: {ERP_CONFIG['server']}")

    conn = pymssql.connect(
        server=ERP_CONFIG['server'],
        port=ERP_CONFIG['port'],
        user=ERP_CONFIG['user'],
        password=ERP_CONFIG['password'],
        database=ERP_CONFIG['database']
    )

    # Son 30 günün satışları (Workcube örneği)
    # Bu SQL'i müşterinizin ERP'sine göre değiştirin!
    query = f"""
    SELECT
        SALESID as satir_id,
        INVOICEID as fatura_id,
        INVOICEDATE as fatura_tarihi,
        ITEMCODE as urun_kodu,
        ITEMNAME as urun_adi,
        QUANTITY as miktar,
        UNITPRICE as birim_fiyat,
        TOTALAMOUNT as toplam_tutar,
        TAXAMOUNT as kdv_tutari,
        CUSTOMERCODE as musteri_kodu,
        CUSTOMERNAME as musteri_adi
    FROM SALESINVOICELINES
    WHERE INVOICEDATE >= DATEADD(day, -{days_back}, GETDATE())
    ORDER BY INVOICEDATE DESC
    """

    print(f"📊 Sorgu çalıştırılıyor (Son {days_back} gün)...")
    df = pd.read_sql(query, conn)
    conn.close()

    print(f"✅ {len(df):,} satır veri çekildi")
    return df

# === 2. CLICKHOUSE'A YÜKLE ===
def load_to_clickhouse(df, table_name='satislar'):
    """DataFrame'i ClickHouse'a yükler"""
    print(f"🔄 ClickHouse'a bağlanılıyor...")

    client = clickhouse_connect.get_client(
        host=CLICKHOUSE_CONFIG['host'],
        port=CLICKHOUSE_CONFIG['port']
    )

    # Veritabanı oluştur
    client.command("CREATE DATABASE IF NOT EXISTS erp_analytics")

    # Tablo oluştur (ilk çalıştırmada)
    client.command(f"""
        CREATE TABLE IF NOT EXISTS erp_analytics.{table_name} (
            satir_id String,
            fatura_id String,
            fatura_tarihi Date,
            urun_kodu String,
            urun_adi String,
            miktar Float64,
            birim_fiyat Float64,
            toplam_tutar Float64,
            kdv_tutari Float64,
            musteri_kodu String,
            musteri_adi String,
            yukleme_zamani DateTime DEFAULT now()
        ) ENGINE = MergeTree()
        ORDER BY (fatura_tarihi, urun_kodu)
    """)

    # Veriyi yükle
    print(f"⬆ ClickHouse'a yükleniyor...")
    client.insert_df(f"erp_analytics.{table_name}", df)

    # Toplam satır sayısını kontrol et
    result = client.query(f"SELECT count() FROM erp_analytics.{table_name}")
    total_rows = result.result_rows[0][0]

    print(f"✅ Yükleme tamamlandı! Toplam satır: {total_rows:,}")

# === 3. ANA FONKSİYON ===
def main():
    print("\n" + "="*60)
    print("📦 ERP → ClickHouse Veri Aktarımı")
    print("="*60 + "\n")

    try:
        # Veriyi çek
        df = extract_from_erp(days_back=90)  # Son 90 gün

        if df.empty:
            print("⚠ Veri bulunamadı!")
            return

        # ClickHouse'a yükle
        load_to_clickhouse(df)

        print("\n" + "="*60)
        print("✅ İŞLEM TAMAMLANDI!")
        print("="*60)
        print("\n📊 Sonraki Adımlar:")
        print("1. Superset'e gidin: http://localhost:8088")
        print("2. Database bağlantısı ekleyin: clickhouse://localhost:8123/erp_analytics")
        print("3. 'satislar' tablosunu dataset olarak ekleyin")
        print("4. Dashboard oluşturun!")
        print("\n")

    except Exception as e:
        print(f"\n❌ HATA: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
