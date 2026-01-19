{{
    config(
        materialized='view',
        tags=['staging', 'workcube']
    )
}}

/*
Workcube Satış Hareketleri → Standart Şema
===============================================
Workcube'daki satış tablolarını standart bir formata dönüştürür.
Her ERP'nin farklı tablo isimleri olsa da, çıktı hep aynı kolonlardan oluşur.
*/

WITH kaynak AS (
    SELECT
        -- Temel alanlar
        SALESID as satir_id,
        INVOICEID as fatura_id,
        INVOICEDATE as fatura_tarihi,

        -- Ürün bilgileri
        ITEMCODE as urun_kodu,
        ITEMNAME as urun_adi,

        -- Miktar ve tutar
        QUANTITY as miktar,
        UNITPRICE as birim_fiyat,
        TOTALAMOUNT as toplam_tutar,
        TAXAMOUNT as kdv_tutari,

        -- Müşteri bilgileri
        CUSTOMERCODE as musteri_kodu,
        CUSTOMERNAME as musteri_adi,

        -- Diğer
        WAREHOUSECODE as depo_kodu,
        SALESPERSONCODE as satis_temsilcisi_kodu,

        -- Metadata
        CREATEDDATE as kayit_tarihi,
        MODIFIEDDATE as guncelleme_tarihi

    FROM {{ source('raw_workcube', 'SALESINVOICELINES') }}
    WHERE INVOICEDATE >= '{{ var("start_date") }}'
)

SELECT
    satir_id,
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
    satis_temsilcisi_kodu,
    kayit_tarihi,
    'workcube' as kaynak_sistem
FROM kaynak
