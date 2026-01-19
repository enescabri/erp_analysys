-- ================================================================
-- ERP Analiz Paketi - İlk Kurulum SQL
-- ================================================================
-- Bu script sadece ilk çalıştırmada otomatik çalışır.
-- Superset ve Airflow'un ihtiyaç duyduğu database'leri hazırlar.
-- ================================================================

-- Superset için şema (Postgres'te zaten default olarak 'public' var)
CREATE SCHEMA IF NOT EXISTS superset;

-- Airflow için şema
CREATE SCHEMA IF NOT EXISTS airflow;

-- ClickHouse entegrasyonu için örnek tablo görünümü
-- (Gerçek tablolar Airflow DAG'larıyla oluşturulacak)

-- Kurulum başarılı mesajı
DO $$
BEGIN
    RAISE NOTICE '✓ ERP Analiz Paketi veritabanı hazır!';
END $$;
