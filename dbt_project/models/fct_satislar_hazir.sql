{{
    config(
        materialized='table',
        tags=['production', 'daily']
    )
}}

/*
TÜM SATIŞLAR - HAZIR RAPOR TABLOSU
===================================
raw_erp.satislar → mart.fct_satislar_hazir

Bu tablo doğrudan Superset'te kullanılır.
Her gece Ofelia tarafından otomatik güncellenir.

KULLANIM:
- Superset Dataset: mart.fct_satislar_hazir
- Filtreler: yil, ay, musteri_adi, urun_adi
- Metrikler: toplam_satis, ortalama_fiyat, toplam_adet
*/

WITH kaynak AS (
    SELECT
        fatura_id,
        fatura_tarihi,
        urun_kodu,
        urun_adi,
        miktar,
        birim_fiyat,
        toplam_tutar,
        kdv_tutari,
        musteri_kodu,
        musteri_adi,
        depo_kodu,
        yukleme_zamani
    FROM raw_erp.satislar
    WHERE fatura_tarihi >= today() - INTERVAL 2 YEAR  -- Son 2 yıl
)

SELECT
    -- Temel kolonlar
    fatura_id,
    fatura_tarihi,

    -- Zaman boyutları (Filtreleme için)
    toYear(fatura_tarihi) as yil,
    toMonth(fatura_tarihi) as ay,
    toQuarter(fatura_tarihi) as ceyrek,
    toDayOfWeek(fatura_tarihi) as haftanin_gunu,
    formatDateTime(fatura_tarihi, '%Y-%m') as ay_yil,

    -- Ürün bilgileri
    urun_kodu,
    urun_adi,

    -- Miktar ve tutarlar
    miktar,
    birim_fiyat,
    toplam_tutar,
    kdv_tutari,
    (toplam_tutar + kdv_tutari) as kdv_dahil_tutar,

    -- Hesaplanan metrikler
    CASE
        WHEN miktar > 0 THEN toplam_tutar / miktar
        ELSE birim_fiyat
    END as ortalama_birim_fiyat,

    -- Müşteri bilgileri
    musteri_kodu,
    musteri_adi,

    -- Depo/Şube
    depo_kodu,

    -- Kategoriler (Analiz için)
    CASE
        WHEN toplam_tutar >= 10000 THEN 'Büyük Satış'
        WHEN toplam_tutar >= 1000 THEN 'Orta Satış'
        ELSE 'Küçük Satış'
    END as satis_kategorisi,

    CASE
        WHEN miktar >= 100 THEN 'Toptan'
        WHEN miktar >= 10 THEN 'Perakende'
        ELSE 'Bireysel'
    END as miktar_kategorisi,

    -- Metadata
    yukleme_zamani,
    now() as model_calisma_zamani

FROM kaynak

-- Kalite kontrolü (Veri temizleme)
WHERE toplam_tutar > 0
  AND miktar > 0
  AND fatura_id IS NOT NULL
