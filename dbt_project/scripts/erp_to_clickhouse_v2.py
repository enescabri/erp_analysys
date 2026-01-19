#!/usr/bin/env python3
"""
ERP → ClickHouse Otomatik Veri Yükleme (Yapılandırılabilir SQL)
================================================================
.env dosyasından SQL_QUERY_FILE ile hangi sorgunun kullanılacağını belirler.

Kullanım:
    .env dosyasına ekleyin:
    SQL_QUERY_FILE=workcube_satislar.sql

    veya

    SQL_QUERY_FILE=odoo_satislar.sql
"""

import os
import sys
import pandas as pd
import clickhouse_connect
from datetime import datetime
from pathlib import Path

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

# SQL dosyası (müşteriye özel)
SQL_QUERY_FILE = os.getenv('SQL_QUERY_FILE', 'workcube_satislar.sql')

CLICKHOUSE_HOST = os.getenv('CLICKHOUSE_HOST', 'clickhouse')
CLICKHOUSE_PORT = int(os.getenv('CLICKHOUSE_PORT', 8123))

# === 1. SQL SORGUSUNU OKU VE PARAMETRELERİ DEĞIŞTIR ===
def load_query():
    """SQL dosyasını queries/ klasöründen okur ve parametreleri değiştirir"""
    script_dir = Path(__file__).parent
    query_file = script_dir / 'queries' / SQL_QUERY_FILE

    if not query_file.exists():
        log(f"❌ HATA: {query_file} bulunamadı!")
        log(f"📁 Mevcut klasör: {script_dir / 'queries'}")
        log(f"📄 Aranılan dosya: {SQL_QUERY_FILE}")
        sys.exit(1)

    log(f"📄 SQL dosyası okunuyor: {SQL_QUERY_FILE}")
    with open(query_file, 'r', encoding='utf-8') as f:
        query = f.read()

    # Workcube şema parametrelerini değiştir
    query = replace_schema_params(query)

    return query


def replace_schema_params(query):
    """SQL içindeki {{dsn}}, {{dsn2}} gibi parametreleri .env'den değiştirir"""

    # Workcube parametreleri
    wc_base = os.getenv('WC_BASE_SCHEMA', 'workcube_prod')
    wc_year = os.getenv('WC_PERIOD_YEAR', '2026')
    wc_company = os.getenv('WC_COMPANY_ID', '1')
    wc_product = os.getenv('WC_PRODUCT_SCHEMA', 'workcube_prod_product')

    # Şema isimlerini oluştur
    dsn = wc_base
    dsn2 = f"{wc_base}_{wc_year}_{wc_company}"
    dsn3 = f"{wc_base}_{wc_company}"
    dsn_product = wc_product

    # SQL'deki değişkenleri değiştir
    replacements = {
        '{{dsn}}': dsn,
        '{{dsn2}}': dsn2,
        '{{dsn3}}': dsn3,
        '{{dsn_product}}': dsn_product,
    }

    log(f"📝 Şema parametreleri:")
    for key, value in replacements.items():
        log(f"   {key} → {value}")
        query = query.replace(key, value)

    return query

# === 2. ERP'DEN VERİ ÇEK ===
def extract_from_erp():
    """ERP'den SQL dosyasındaki sorguyu çalıştırır"""
    log(f"🔌 ERP'ye bağlanılıyor: {ERP_HOST}:{ERP_PORT}/{ERP_DB}")

    # SQL sorgusunu yükle
    query = load_query()

    # ERP tipine göre bağlantı
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

    log(f"📊 Sorgu çalıştırılıyor...")
    df = pd.read_sql(query, conn)
    conn.close()

    log(f"✅ {len(df):,} satır çekildi")
    return df

# === 3. CLICKHOUSE'A YÜKLE ===
def load_to_clickhouse(df):
    """ClickHouse'a incremental yükleme yapar"""
    if df.empty:
        log("⚠️ Yüklenecek veri yok!")
        return

    log(f"🔌 ClickHouse'a bağlanılıyor: {CLICKHOUSE_HOST}:{CLICKHOUSE_PORT}")

    client = clickhouse_connect.get_client(
        host=CLICKHOUSE_HOST,
        port=CLICKHOUSE_PORT
    )

    # Database ve tablo oluştur
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

# === 4. ANA FONKSİYON ===
def main():
    log("="*60)
    log("📦 ERP → ClickHouse Veri Aktarımı BAŞLADI")
    log(f"📄 Kullanılan SQL: {SQL_QUERY_FILE}")
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
