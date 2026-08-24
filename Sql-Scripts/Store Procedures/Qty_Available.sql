USE [P21Play] 

go 

SET ansi_nulls ON 

go 

SET quoted_identifier OFF 

go 

CREATE PROCEDURE [dbo].[P21dba_get_qty_assembly] 
AS 
    SET nocount ON 

  BEGIN 
      DECLARE @level        INT, 
              @inv_mast_uid INT 
      DECLARE @assembly_tree TABLE 
        ( 
           location_id            INT, 
           inv_mast_uid           INT, 
           item_id                VARCHAR(255), 
           qty_on_hand            DECIMAL(19, 9), 
           component_inv_mast_uid INT, 
           component_item_id      VARCHAR(255), 
           component_qty_on_hand  DECIMAL (19, 9), 
           level                  INT, 
           quantity_per_assembly  DECIMAL (19, 9), 
           component_total_qty    DECIMAL (19, 9), 
           delete_flag            VARCHAR(1), 
           component_delete_flag  VARCHAR(1), 
           stockable              CHAR(1), 
           component_stockable    CHAR(1) 
        ) 

      SELECT @level = 0 

      INSERT INTO @assembly_tree 
      SELECT inv_loc.location_id, 
             ah.inv_mast_uid, 
             inv_mast.item_id, 
             Isnull(inv_loc.qty_on_hand, 0) - Isnull(inv_loc.qty_allocated, 0), 
             al.component_inv_mast_uid, 
             inv_mast_c.item_id, 
             Isnull(inv_loc_c.qty_on_hand, 0) - 
             Isnull(inv_loc_c.qty_allocated, 0), 
             @level, 
             quantity_per_assembly = CASE 
                                       WHEN al.quantity <= 0 THEN -1 
                                       ELSE al.quantity 
                                     END, 
             NULL, 
             inv_mast.delete_flag, 
             inv_mast_c.delete_flag, 
             inv_loc.stockable, 
             inv_loc_c.stockable 
      FROM   assembly_hdr ah 
             INNER JOIN assembly_line al 
                     ON ah.inv_mast_uid = al.inv_mast_uid 
             INNER JOIN inv_mast 
                     ON inv_mast.inv_mast_uid = ah.inv_mast_uid 
             INNER JOIN inv_mast inv_mast_c 
                     ON inv_mast_c.inv_mast_uid = al.component_inv_mast_uid 
             LEFT JOIN inv_loc 
                    ON inv_mast.inv_mast_uid = inv_loc.inv_mast_uid 
                       AND inv_mast.delete_flag = 'N' 
             --and inv_loc.location_id = @location_id    
             LEFT JOIN inv_loc inv_loc_c 
                    ON inv_mast_c.inv_mast_uid = inv_loc_c.inv_mast_uid 
                       AND inv_mast_c.delete_flag = 'N' 
                       AND inv_loc_c.location_id = inv_loc.location_id 
      WHERE  inv_mast_c.other_charge_item = 'N' 
             AND al.delete_flag = 'N' 

      WHILE @@ROWCOUNT > 0 
        BEGIN 
            SET @level = @level + 1 

            INSERT INTO @assembly_tree 
            SELECT inv_loc.location_id, 
                   ah.inv_mast_uid, 
                   inv_mast.item_id, 
                   Isnull(inv_loc.qty_on_hand, 0) - 
                   Isnull(inv_loc.qty_allocated, 0), 
                   al.component_inv_mast_uid, 
                   inv_mast_c.item_id, 
                   Isnull(inv_loc_c.qty_on_hand, 0) - 
                   Isnull(inv_loc_c.qty_allocated, 0), 
                   @level, 
                   quantity_per_assembly = CASE 
                                             WHEN al.quantity <= 0 THEN 1 
                                             ELSE al.quantity 
                                           END, 
                   NULL, 
                   inv_mast.delete_flag, 
                   inv_mast_c.delete_flag, 
                   inv_loc.stockable, 
                   inv_loc_c.stockable 
            FROM   assembly_hdr ah 
                   INNER JOIN assembly_line al 
                           ON ah.inv_mast_uid = al.inv_mast_uid 
                   INNER JOIN inv_mast 
                           ON inv_mast.inv_mast_uid = ah.inv_mast_uid 
                   INNER JOIN inv_mast inv_mast_c 
                           ON inv_mast_c.inv_mast_uid = 
                              al.component_inv_mast_uid 
                   LEFT JOIN inv_loc 
                          ON inv_mast.inv_mast_uid = inv_loc.inv_mast_uid 
                             AND inv_mast.delete_flag = 'N' 
                   --and inv_loc.location_id = @location_id 
                   LEFT JOIN inv_loc inv_loc_c 
                          ON inv_mast_c.inv_mast_uid = inv_loc_c.inv_mast_uid 
                             AND inv_mast_c.delete_flag = 'N' 
                             AND inv_loc_c.location_id = inv_loc.location_id 
                   --and inv_loc_c.location_id = @location_id 
                   INNER JOIN @assembly_tree a 
                           ON al.inv_mast_uid = a.component_inv_mast_uid 
                              AND a.level = @level - 1 
                              AND a.location_id = inv_loc.location_id 
            WHERE  inv_mast_c.other_charge_item = 'N' 
                   AND al.delete_flag = 'N' 
        END 

      UPDATE @assembly_tree 
      SET    component_total_qty = ( CASE 
                                       WHEN quantity_per_assembly < 0 THEN 
                                       9999999999 
                                       ELSE Round( 
                    component_qty_on_hand / quantity_per_assembly, 0, 1) 
                                     END ) 

      SELECT @level = Max(level) 
      FROM   @assembly_tree 

      WHILE @level > 0 
        BEGIN 
            UPDATE assembly_tree 
            SET    component_total_qty = Round( 
                   der_min.qty / quantity_per_assembly 
                                         , 0, 
                                         1 
                                         ) 
            FROM   @assembly_tree assembly_tree 
                   INNER JOIN (SELECT location_id, 
                                      Min(component_total_qty) + Min(qty_on_hand 
                                      ) 
                                      qty, 
                                      inv_mast_uid 
                               FROM   @assembly_tree 
                               WHERE  level = @level 
                               GROUP  BY location_id, 
                                         inv_mast_uid) der_min 
                           ON der_min.inv_mast_uid = 
                              assembly_tree.component_inv_mast_uid 
                              AND level = @level - 1 
                              AND der_min.location_id = 
                                  assembly_tree.location_id 

            DELETE FROM @assembly_tree 
            WHERE  level = @level 

            SET @level = @level - 1 
        END 

      --Start update process        
      --Used a temp table here because you cannot use aggregates in an update statement 
      SELECT location_id, 
             inv_mast_uid, 
             item_id, 
             qty = Cast(Min(qty_on_hand) + Min(component_total_qty)AS INT) 
      INTO   #qty 
      FROM   @assembly_tree 
      GROUP  BY location_id, 
                inv_mast_uid, 
                item_id 

      UPDATE inv_loc_ud 
      SET    inv_loc_ud.assembly_qty = qty.qty 
      FROM   #qty qty 
             INNER JOIN inv_loc_ud 
                     ON inv_loc_ud.location_id = qty.location_id 
                        AND inv_loc_ud.inv_mast_uid = qty.inv_mast_uid 
      WHERE  inv_loc_ud.assembly_qty <> qty.qty 

      DROP TABLE #qty 
  END 

go 