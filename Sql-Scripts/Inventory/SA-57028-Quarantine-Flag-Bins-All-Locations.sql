-- SA 57028: stock in any bin whose bin_type has quarantine_flag = 'Y', PLUS Jerome's named bins
-- (EDS-LOST is typed WOOD DALE / pickable, so the flag alone misses it), ALL locations.
-- Replaces the location-100-only "Lost and Quarantine Bin.xlsx" query. Source: DW (asdwdb01 / P21).
select
    x.location_id
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
    i.location_id, i.bin, bt.bin_type, bt.pickable_flag, m.item_id, m.extended_desc
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
