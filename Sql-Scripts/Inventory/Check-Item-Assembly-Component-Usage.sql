/* ============================================================================
   Why does an item raise the "used as a component of an existing assembly"
   message?  Shows every assembly the item is a COMPONENT of, with the UOM and
   quantity P21 stored, plus the parent assembly's OE-explosion settings.

   Run in: P21Dev (or the env under test).  READ-ONLY.

   Schema notes (P21Dev, confirmed 2026-09-10):
     assembly_line.inv_mast_uid            = the assembly PARENT item
     assembly_line.component_inv_mast_uid  = the COMPONENT item   <-- filter on this
     assembly_hdr  is keyed by inv_mast_uid (the parent); no surrogate key.
   ============================================================================ */
USE P21Dev;
GO

DECLARE @item_id varchar(40) = 'CBVVCG10AS';

/* 1. every assembly this item is a component of --------------------------- */
SELECT  parent.item_id            AS assembly_parent,
        parent.item_desc          AS assembly_desc,
        al.unit_of_measure        AS component_uom_in_bom,
        al.quantity,
        al.qty_needed,
        al.sub_assembly,
        al.delete_flag            AS line_delete_flag,
        ah.assembly_for_stock,
        ah.auto_expand_flag,
        ah.production_order_processing,
        ah.bypass_oe_prod_order_processing,
        ah.allow_oe_add_components
FROM        dbo.assembly_line al
JOIN        dbo.inv_mast comp    ON comp.inv_mast_uid   = al.component_inv_mast_uid
JOIN        dbo.inv_mast parent  ON parent.inv_mast_uid = al.inv_mast_uid
LEFT JOIN   dbo.assembly_hdr ah  ON ah.inv_mast_uid     = al.inv_mast_uid
WHERE       comp.item_id = @item_id
ORDER BY    assembly_parent;
GO

/* 2. side-by-side with the other test items: is-a-component is the only diff */
SELECT  im.item_id,
        im.item_desc,
        (SELECT COUNT(*) FROM dbo.assembly_line al
          WHERE al.component_inv_mast_uid = im.inv_mast_uid AND al.delete_flag = 'N')
            AS times_used_as_component,
        (SELECT COUNT(*) FROM dbo.assembly_line al
          WHERE al.inv_mast_uid = im.inv_mast_uid AND al.delete_flag = 'N')
            AS is_an_assembly_parent_lines
FROM    dbo.inv_mast im
WHERE   im.item_id IN ('CBVVCG10AS'
                      /* ,'REPLACE_ME_02', ... the other 9 test item_ids */ )
ORDER BY times_used_as_component DESC, im.item_id;
GO
