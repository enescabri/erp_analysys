{{
    config(
        materialized='view',
        tags=['staging', 'odoo']
    )
}}

/*
Odoo Satış Siparişleri → Standart Şema
===============================================
Odoo'daki sale.order ve sale.order.line tablolarını birleştirip
Workcube ile aynı standart çıktıyı üretir.
*/

WITH siparis_satirlari AS (
    SELECT
        sol.id as satir_id,
        so.name as fatura_id,
        so.date_order::Date as fatura_tarihi,

        -- Ürün bilgileri (product.product ve product.template join)
        pt.default_code as urun_kodu,
        pt.name as urun_adi,

        -- Miktar ve tutar
        sol.product_uom_qty as miktar,
        sol.price_unit as birim_fiyat,
        sol.price_subtotal as toplam_tutar,
        sol.price_tax as kdv_tutari,

        -- Müşteri bilgileri (res.partner join)
        rp.ref as musteri_kodu,
        rp.name as musteri_adi,

        -- Diğer
        sw.code as depo_kodu,
        su.login as satis_temsilcisi_kodu,

        -- Metadata
        so.create_date as kayit_tarihi,
        so.write_date as guncelleme_tarihi

    FROM {{ source('raw_odoo', 'sale_order_line') }} sol
    LEFT JOIN {{ source('raw_odoo', 'sale_order') }} so ON sol.order_id = so.id
    LEFT JOIN {{ source('raw_odoo', 'product_product') }} pp ON sol.product_id = pp.id
    LEFT JOIN {{ source('raw_odoo', 'product_template') }} pt ON pp.product_tmpl_id = pt.id
    LEFT JOIN {{ source('raw_odoo', 'res_partner') }} rp ON so.partner_id = rp.id
    LEFT JOIN {{ source('raw_odoo', 'stock_warehouse') }} sw ON so.warehouse_id = sw.id
    LEFT JOIN {{ source('raw_odoo', 'res_users') }} su ON so.user_id = su.id

    WHERE so.state IN ('sale', 'done')  -- Sadece onaylanmış siparişler
      AND so.date_order >= '{{ var("start_date") }}'
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
    'odoo' as kaynak_sistem
FROM siparis_satirlari
