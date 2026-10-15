-- SA 57028: stock in any bin whose bin_type has quarantine_flag = 'Y', PLUS Jerome's named bins
-- (EDS-LOST is typed WOOD DALE / pickable, so the flag alone misses it), ALL locations.
-- v2 adds first/last 'added' date + user from inv_bin_audit / lot_bin_xref_audit (positive qty movements).
-- Replaces the location-100-only "Lost and Quarantine Bin.xlsx" query. Source: DW (asdwdb01 / P21).
with bins as (
select
    x.inv_mast_uid
  , x.location_id
  , x.bin_cd
  , bt.bin_type
  , bt.pickable_flag
  , m.item_id
  , m.extended_desc
  , x.qty_linked
  , x.lot_cd
  , l.sku_cost
  , x.qty_linked * l.sku_cost ext_cost
  , GETDATE() last_refresh
from p21_view_lot_bin_xref x
    inner join bin bn on bn.location_id = x.location_id and bn.bin_id = x.bin_cd
    inner join bin_type bt on bt.bin_type_uid = bn.bin_type_uid
    left join p21_view_inv_mast m on x.inv_mast_uid = m.inv_mast_uid
    left join p21_view_lot l
        on x.lot_cd = l.lot
        and x.inv_mast_uid = l.inv_mast_uid
        and x.location_id = l.location_id
where x.qty_linked <> 0
    and (bt.quarantine_flag = 'Y' or x.bin_cd in ('LOST','EDS-LOST','QUARANTINED','QUARANTINE'))

union all

select
    i.inv_mast_uid, i.location_id, i.bin, bt.bin_type, bt.pickable_flag, m.item_id, m.extended_desc
  , i.quantity qty_linked, '' lot, loc.moving_average_cost
  , i.quantity * loc.moving_average_cost ext_cost, GETDATE() last_refresh
from p21_view_inv_bin i
    inner join bin bn on bn.location_id = i.location_id and bn.bin_id = i.bin
    inner join bin_type bt on bt.bin_type_uid = bn.bin_type_uid
    inner join p21_view_inv_mast m on i.inv_mast_uid = m.inv_mast_uid
    left join p21_view_inv_loc loc
        on i.inv_mast_uid = loc.inv_mast_uid
        and i.location_id = loc.location_id
where m.track_lots = 'n'
    and i.quantity <> 0
    and (bt.quarantine_flag = 'Y' or i.bin in ('LOST','EDS-LOST','QUARANTINED','QUARANTINE'))
)
select
    b.location_id
  , b.bin_cd
  , b.bin_type
  , b.pickable_flag
  , b.item_id
  , b.extended_desc
  , b.qty_linked
  , b.lot_cd
  , b.sku_cost
  , b.ext_cost
  , a1.date_last_modified   first_added_date
  , a1.last_maintained_by   first_added_by
  , a2.date_last_modified   last_added_date
  , a2.last_maintained_by   last_added_by
  , b.last_refresh
from bins b
    outer apply (   -- lot-tracked rows: lot_bin_xref_audit; non-lot rows (lot_cd = ''): inv_bin_audit
        select top (1) u.date_last_modified, u.last_maintained_by
        from (
            select la.date_last_modified, la.last_maintained_by
            from lot_bin_xref_audit la
            where b.lot_cd <> '' and la.inv_mast_uid = b.inv_mast_uid and la.location_id = b.location_id
                and la.lot_cd = b.lot_cd and la.bin_cd = b.bin_cd and la.qty_linked_delta > 0
            union all
            select ia.date_last_modified, ia.last_maintained_by
            from inv_bin_audit ia
            where b.lot_cd = '' and ia.inv_mast_uid = b.inv_mast_uid and ia.location_id = b.location_id
                and ia.bin = b.bin_cd and ia.quantity_delta > 0
        ) u
        order by u.date_last_modified asc
    ) a1
    outer apply (
        select top (1) u.date_last_modified, u.last_maintained_by
        from (
            select la.date_last_modified, la.last_maintained_by
            from lot_bin_xref_audit la
            where b.lot_cd <> '' and la.inv_mast_uid = b.inv_mast_uid and la.location_id = b.location_id
                and la.lot_cd = b.lot_cd and la.bin_cd = b.bin_cd and la.qty_linked_delta > 0
            union all
            select ia.date_last_modified, ia.last_maintained_by
            from inv_bin_audit ia
            where b.lot_cd = '' and ia.inv_mast_uid = b.inv_mast_uid and ia.location_id = b.location_id
                and ia.bin = b.bin_cd and ia.quantity_delta > 0
        ) u
        order by u.date_last_modified desc
    ) a2
