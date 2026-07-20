-- Find-Location-WWMS-RF-Flags.sql
-- Looks up the RF / WWMS flag columns on dbo.location for a given location_id
-- Source: Screenshot 2026-07-20 115741.png (Column 35,36,77,78,84,85,86,94,95,105)

DECLARE @location_id INT = 221;

SELECT
    location_id,
    rf_enabled_flag                     AS [Rf Enabled Flag],                      -- Col 35
    wwms_show_bin_alloc_warning         AS [Wwms Show Bin Alloc Warning],          -- Col 36
    use_bins_for_trans_schedule_flag    AS [Use Bins For Trans Schedule Flag],     -- Col 77
    rf_frontcounterpicking_flag         AS [Rf Frontcounterpicking Flag],          -- Col 78
    use_pallets_flag                    AS [Use Pallets Flag],                     -- Col 84
    use_pallet_types_flag               AS [Use Pallet Types Flag],                -- Col 85
    undershipment_allocation_flag       AS [Undershipment Allocation Flag],        -- Col 86
    print_packinglist_in_wwms           AS [Print Packinglist Wwms],               -- Col 94
    print_transfer_packinglist_in_wwms  AS [Pnt Transferpacklist Wwms],             -- Col 95
    adjust_found_items_flag             AS [Adjust Found Items Flag]               -- Col 105
FROM dbo.location
WHERE location_id = @location_id;
