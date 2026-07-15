/* ============================================================================
   Discontinued items (class_id4 = 'DISCONT') with total on-hand quantity
   ----------------------------------------------------------------------------
   Built for Efrain, 2026-07-15.
   Lists every DISCONT-lifecycle item with its division, manufacturer,
   product line, base unit, and the SUM of qty_on_hand across all locations.

   Notes:
   - qty_on_hand is a LEFT JOIN to a grouped derived table on item_id so the
     per-item total is computed once (not per output row) and items with no
     inv_loc row still appear (ISNULL -> 0).
   - The C2 (product line) join predicate was corrected from C1.class_type
     to C2.class_type; the original had a copy-paste alias bug.
   - No kb_/js_ objects referenced — all standard p21_view_* views.
   ============================================================================ */

select p21_view_inv_mast.item_id,
       p21_view_inv_mast.extended_desc,
       inv_mast_ud.division,
       class_id1 as 'Manufacturer_id',
       c1.class_description as 'manufacturer_description',
       class_id2 as 'product_line_id',
       c2.class_description as 'product_line_description',
       c4.class_description as 'product_lifecycle',
       p21_view_inv_mast.base_unit,
       isnull(loc.qty_on_hand, 0) as qty_on_hand
from p21_view_inv_mast
left join p21_view_class as C1
       on C1.class_id = p21_view_inv_mast.class_id1
      and C1.class_number = 1
      and C1.class_type = 'iv'
left join p21_view_class as C2
       on C2.class_id = p21_view_inv_mast.class_id2
      and C2.class_number = 2
      and C2.class_type = 'iv'          -- was C1.class_type (bug in original)
left join p21_view_class as C4
       on C4.class_id = p21_view_inv_mast.class_id4
      and C4.class_number = 4
      and C4.class_type = 'iv'
left join inv_mast_ud
       on inv_mast_ud.inv_mast_uid = p21_view_inv_mast.inv_mast_uid
left join (
        select item_id, sum(qty_on_hand) as qty_on_hand
        from p21_view_inv_loc
        group by item_id
     ) as loc
       on loc.item_id = p21_view_inv_mast.item_id
where class_id4 = 'DISCONT'
order by inv_mast_ud.division, class_id1, p21_view_inv_mast.item_id asc;
