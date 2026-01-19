{{
    config(
        materialized='table',
        tags=['mart', 'sales']
    )
}}

/*
TÜM SATIŞLAR - BİRLEŞTİRİLMİŞ (Fact Table)
===========================================
Workcube, Odoo ve diğer tüm ERP'lerden gelen satışları
tek bir tabloda birleştirir. Superset buraya bağlanır.

KULLANIM:
- Dashboard'larda doğrudan kullanılır
- Filtreleme: kaynak_sistem = 'workcube' veya 'odoo'
- Performans: ClickHouse'da tablo olarak saklanır (hızlı!)
*/

WITH tum_satislar AS (
    -- Workcube satışları
    SELECT * FROM {{ ref('stg_workcube_satislar') }}

    UNION ALL

    -- Odoo satışları
    SELECT * FROM {{ ref('stg_odoo_satislar') }}

    -- Yeni ERP eklediğinizde buraya eklersiniz:
    -- UNION ALL
    -- SELECT * FROM {{ ref('stg_sap_satislar') }}
)

SELECT
    satir_id,
    fatura_id,
    fatura_tarihi,
    toYear(fatura_tarihi) as yil,
    toMonth(fatura_tarihi) as ay,
    toQuarter(fatura_tarihi) as ceyrek,

    urun_kodu,
    urun_adi,

    miktar,
    birim_fiyat,
    toplam_tutar,
    kdv_tutari,
    (toplam_tutar + kdv_tutari) as kdv_dahil_tutar,

    musteri_kodu,
    musteri_adi,

    depo_kodu,
    satis_temsilcisi_kodu,

    kaynak_sistem,
    kayit_tarihi,

    -- Hesaplanmış alanlar (KPI'lar için)
    CASE
        WHEN toplam_tutar > 10000 THEN 'Yüksek'
        WHEN toplam_tutar > 1000 THEN 'Orta'
        ELSE 'Düşük'
    END as fatura_buyuklugu

FROM tum_satislar
