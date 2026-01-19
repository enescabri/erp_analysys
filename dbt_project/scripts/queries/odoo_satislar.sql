-- ================================================================
-- ODOO SATIŞ VERİSİ ÇEKME SORGUSU
-- ================================================================

SELECT
    CAST(sol.id AS VARCHAR(50)) as satir_id,
    CAST(so.name AS VARCHAR(50)) as fatura_id,
    CAST(so.date_order AS DATE) as fatura_tarihi,

    CAST(pt.default_code AS VARCHAR(100)) as urun_kodu,
    CAST(pt.name AS VARCHAR(500)) as urun_adi,

    CAST(sol.product_uom_qty AS FLOAT) as miktar,
    CAST(sol.price_unit AS FLOAT) as birim_fiyat,
    CAST(sol.price_subtotal AS FLOAT) as toplam_tutar,
    CAST(sol.price_tax AS FLOAT) as kdv_tutari,

    CAST(rp.ref AS VARCHAR(100)) as musteri_kodu,
    CAST(rp.name AS VARCHAR(500)) as musteri_adi,

    CAST(sw.code AS VARCHAR(50)) as depo_kodu

FROM sale_order_line sol
LEFT JOIN sale_order so ON sol.order_id = so.id
LEFT JOIN product_product pp ON sol.product_id = pp.id
LEFT JOIN product_template pt ON pp.product_tmpl_id = pt.id
LEFT JOIN res_partner rp ON so.partner_id = rp.id
LEFT JOIN stock_warehouse sw ON so.warehouse_id = sw.id

WHERE so.state IN ('sale', 'done')
  AND so.date_order >= CURRENT_DATE - INTERVAL '7 days'

ORDER BY so.date_order DESC
