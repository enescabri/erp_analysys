-- ================================================================
-- WORKCUBE SATIŞ VERİSİ ÇEKME SORGUSU (Parametreli)
-- ================================================================
-- Şema parametreleri .env dosyasından gelir:
--   {{dsn}}  → WC_BASE_SCHEMA
--   {{dsn2}} → WC_BASE_SCHEMA_WC_PERIOD_YEAR_WC_COMPANY_ID
--   {{dsn3}} → WC_BASE_SCHEMA_WC_COMPANY_ID
--   {{dsn_product}} → WC_PRODUCT_SCHEMA
-- ================================================================

SELECT
    CAST(s.SALESID AS VARCHAR(50)) as satir_id,
    CAST(s.INVOICEID AS VARCHAR(50)) as fatura_id,
    CAST(s.INVOICEDATE AS DATE) as fatura_tarihi,

    CAST(s.ITEMCODE AS VARCHAR(100)) as urun_kodu,
    CAST(p.ITEMNAME AS VARCHAR(500)) as urun_adi,

    CAST(s.QUANTITY AS FLOAT) as miktar,
    CAST(s.UNITPRICE AS FLOAT) as birim_fiyat,
    CAST(s.TOTALAMOUNT AS FLOAT) as toplam_tutar,
    CAST(s.TAXAMOUNT AS FLOAT) as kdv_tutari,

    CAST(s.CUSTOMERCODE AS VARCHAR(100)) as musteri_kodu,
    CAST(c.CUSTOMERNAME AS VARCHAR(500)) as musteri_adi,

    CAST(s.WAREHOUSECODE AS VARCHAR(50)) as depo_kodu

FROM {{dsn2}}.dbo.SALESINVOICELINES s
LEFT JOIN {{dsn_product}}.dbo.PRODUCTS p ON s.ITEMCODE = p.ITEMCODE
LEFT JOIN {{dsn3}}.dbo.CUSTOMERS c ON s.CUSTOMERCODE = c.CUSTOMERCODE

WHERE s.INVOICEDATE >= DATEADD(day, -7, GETDATE())

ORDER BY s.INVOICEDATE DESC
