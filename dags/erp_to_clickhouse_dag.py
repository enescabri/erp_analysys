"""
ERP'den ClickHouse'a Veri Taşıma DAG (Şablon)
==============================================
Bu dosyayı her müşteri için kopyalayıp düzenleyin.
Görev: Her gün saat 02:00'de ERP'den satış verilerini çekip ClickHouse'a yükle.
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import os
import pandas as pd
import clickhouse_connect

# === YAPILANDIRMA (Ortam değişkenlerinden gelir) ===
ERP_CONFIG = {
    'type': os.getenv('ERP_DB_TYPE', 'mssql'),
    'host': os.getenv('ERP_DB_HOST', 'localhost'),
    'port': os.getenv('ERP_DB_PORT', '1433'),
    'database': os.getenv('ERP_DB_NAME', 'LOGO'),
    'user': os.getenv('ERP_DB_USER', 'sa'),
    'password': os.getenv('ERP_DB_PASSWORD', 'password')
}

CLICKHOUSE_CONFIG = {
    'host': 'clickhouse',
    'port': 8123,
    'database': 'erp_analytics'
}

# === FONKSİYONLAR ===

def extract_from_erp():
    """ERP'den veri çeker"""
    print(f"🔄 ERP'ye bağlanılıyor: {ERP_CONFIG['host']}")

    # Bağlantı string'i oluştur (SQL Server örneği)
    if ERP_CONFIG['type'] == 'mssql':
        import pymssql
        conn = pymssql.connect(
            server=ERP_CONFIG['host'],
            port=ERP_CONFIG['port'],
            user=ERP_CONFIG['user'],
            password=ERP_CONFIG['password'],
            database=ERP_CONFIG['database']
        )

        # Örnek sorgu: Son 7 günün satışları
        query = """
        SELECT
            TARIH as tarih,
            STOK_KODU as urun_kodu,
            STOK_ADI as urun_adi,
            MIKTAR as miktar,
            TUTAR as tutar,
            MUSTERI_KODU as musteri_kodu
        FROM SATIS_HAREKETLERI
        WHERE TARIH >= DATEADD(day, -7, GETDATE())
        """

        df = pd.read_sql(query, conn)
        conn.close()

        print(f"✓ {len(df)} satır veri çekildi")
        return df

    else:
        raise ValueError(f"Desteklenmeyen veritabanı: {ERP_CONFIG['type']}")


def load_to_clickhouse(**context):
    """ClickHouse'a veri yükler"""
    df = context['task_instance'].xcom_pull(task_ids='extract_erp')

    if df is None or len(df) == 0:
        print("⚠ Yüklenecek veri yok")
        return

    print(f"🔄 ClickHouse'a bağlanılıyor...")
    client = clickhouse_connect.get_client(
        host=CLICKHOUSE_CONFIG['host'],
        port=CLICKHOUSE_CONFIG['port']
    )

    # Veritabanı ve tablo oluştur (yoksa)
    client.command(f"CREATE DATABASE IF NOT EXISTS {CLICKHOUSE_CONFIG['database']}")

    client.command(f"""
        CREATE TABLE IF NOT EXISTS {CLICKHOUSE_CONFIG['database']}.satislar (
            tarih Date,
            urun_kodu String,
            urun_adi String,
            miktar Float64,
            tutar Float64,
            musteri_kodu String
        ) ENGINE = MergeTree()
        ORDER BY (tarih, urun_kodu)
    """)

    # Veriyi yükle
    client.insert_df(
        f"{CLICKHOUSE_CONFIG['database']}.satislar",
        df
    )

    print(f"✓ {len(df)} satır ClickHouse'a yüklendi")


# === DAG TANIMI ===

default_args = {
    'owner': 'erp_analiz',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'erp_to_clickhouse',
    default_args=default_args,
    description='ERP verilerini ClickHouse\'a taşır',
    schedule_interval='0 2 * * *',  # Her gün saat 02:00
    catchup=False,
    tags=['erp', 'etl']
)

# Görevler
task_extract = PythonOperator(
    task_id='extract_erp',
    python_callable=extract_from_erp,
    dag=dag
)

task_load = PythonOperator(
    task_id='load_clickhouse',
    python_callable=load_to_clickhouse,
    dag=dag
)

# Görev sırası
task_extract >> task_load
