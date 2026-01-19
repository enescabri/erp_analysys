#!/usr/bin/env python3
"""
ERP → ClickHouse Otomatik Veri Yükleme
======================================
Ofelia tarafından her gece otomatik çalıştırılır.
.env dosyasından bağlantı bilgilerini alır.
"""

import os
import sys
import pandas as pd
import clickhouse_connect
from datetime import datetime, timedelta

# === LOG FONKSİYONU ===
def log(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")
    sys.stdout.flush()

# === YAPILANDIRMA ===
ERP_TYPE = os.getenv('ERP_DB_TYPE', 'mssql')
ERP_HOST = os.getenv('ERP_DB_HOST', 'localhost')
ERP_PORT = int(os.getenv('ERP_DB_PORT', 1433))
ERP_DB = os.getenv('ERP_DB_NAME', 'ERP')
ERP_USER = os.getenv('ERP_DB_USER', 'sa')
ERP_PASS = os.getenv('ERP_DB_PASSWORD', '')

CLICKHOUSE_HOST = os.getenv('CLICKHOUSE_HOST', 'clickhouse')
CLICKHOUSE_PORT = int(os.getenv('CLICKHOUSE_PORT', 8123))

# === 1. ERP'DEN VERİ ÇEK ===
def extract_from_erp():
    """ERP'den son 7 günün verilerini çeker"""
    log(f"🔌 ERP'ye bağlanılıyor: {ERP_HOST}:{ERP_PORT}/{ERP_DB}")

    if ERP_TYPE == 'mssql':
        import pymssql
        conn = pymssql.connect(
            server=ERP_HOST,
            port=ERP_PORT,
            user=ERP_USER,
            password=ERP_PASS,
            database=ERP_DB
        )
    elif ERP_TYPE == 'postgresql':
        import psycopg2
        conn = psycopg2.connect(
            host=ERP_HOST,
            port=ERP_PORT,
            dbname=ERP_DB,
            user=ERP_USER,
            password=ERP_PASS
        )
    elif ERP_TYPE == 'oracle':
        import cx_Oracle
        dsn = cx_Oracle.makedsn(ERP_HOST, ERP_PORT, service_name=ERP_DB)
        conn = cx_Oracle.connect(user=ERP_USER, password=ERP_PASS, dsn=dsn)
    else:
        raise ValueError(f"Desteklenmeyen ERP tipi: {ERP_TYPE}")

    # WORKCUBE SORGUSU (Müşteriye göre özelleştirin!)
    query = """
    SELECT
        CAST(SALESID AS VARCHAR(50)) as satir_id,
        CAST(INVOICEID AS VARCHAR(50)) as fatura_id,
        CAST(INVOICEDATE AS DATE) as fatura_tarihi,
        CAST(ITEMCODE AS VARCHAR(100)) as urun_kodu,
        CAST(ITEMNAME AS VARCHAR(500)) as urun_adi,
        CAST(QUANTITY AS FLOAT) as miktar,
        CAST(UNITPRICE AS FLOAT) as birim_fiyat,
        CAST(TOTALAMOUNT AS FLOAT) as toplam_tutar,
        CAST(TAXAMOUNT AS FLOAT) as kdv_tutari,
        CAST(CUSTOMERCODE AS VARCHAR(100)) as musteri_kodu,
        CAST(CUSTOMERNAME AS VARCHAR(500)) as musteri_adi,
        CAST(WAREHOUSECODE AS VARCHAR(50)) as depo_kodu
    FROM SALESINVOICELINES
    WHERE INVOICEDATE >= DATEADD(day, -7, GETDATE())
    ORDER BY INVOICEDATE DESC
    """

    log(f"📊 Sorgu çalıştırılıyor (Son 7 gün)...")
    df = pd.read_sql(query, conn)
    conn.close()

    log(f"✅ {len(df):,} satır çekildi")
    return df

# === 2. CLICKHOUSE'A YÜKLE ===
def load_to_clickhouse(df):
    """ClickHouse'a incremental (artımlı) yükleme yapar"""
    if df.empty:
        log("⚠️ Yüklenecek veri yok!")
        return

    log(f"🔌 ClickHouse'a bağlanılıyor: {CLICKHOUSE_HOST}:{CLICKHOUSE_PORT}")

    client = clickhouse_connect.get_client(
        host=CLICKHOUSE_HOST,
        port=CLICKHOUSE_PORT
    )

    # Database ve tablo oluştur (yoksa)
    client.command("CREATE DATABASE IF NOT EXISTS raw_erp")

    create_table_sql = """
    CREATE TABLE IF NOT EXISTS raw_erp.satislar (
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
        depo_kodu String,
        yukleme_zamani DateTime DEFAULT now()
    ) ENGINE = ReplacingMergeTree(yukleme_zamani)
    ORDER BY (fatura_tarihi, satir_id)
    """
    client.command(create_table_sql)

    # Eski kayıtları sil (aynı tarih aralığı)
    min_date = df['fatura_tarihi'].min()
    max_date = df['fatura_tarihi'].max()

    delete_sql = f"""
    ALTER TABLE raw_erp.satislar
    DELETE WHERE fatura_tarihi >= '{min_date}' AND fatura_tarihi <= '{max_date}'
    """
    client.command(delete_sql)
    log(f"🗑️ {min_date} - {max_date} arası eski kayıtlar silindi")

    # Yeni veriyi yükle
    client.insert_df('raw_erp.satislar', df)

    # Toplam kayıt sayısı
    result = client.query("SELECT count() FROM raw_erp.satislar")
    total = result.result_rows[0][0]

    log(f"✅ Yükleme tamamlandı! Toplam kayıt: {total:,}")

# === 3. ANA FONKSİYON ===
def main():
    log("="*60)
    log("📦 ERP → ClickHouse Veri Aktarımı BAŞLADI")
    log("="*60)

    try:
        # Veriyi çek
        df = extract_from_erp()

        # ClickHouse'a yükle
        load_to_clickhouse(df)

        log("="*60)
        log("✅ İŞLEM BAŞARIYLA TAMAMLANDI!")
        log("="*60)

    except Exception as e:
        log(f"❌ HATA: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
