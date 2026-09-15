-- SA-50563 (was 50653): Move SFS ship-to's from "Sioux Falls 1pm" carrier to "Sioux Falls 3pm" carrier
-- Source: 'SA-50653-SFS Carrier Changes for cut off times.xlsx' (sheet "SFS 3pm carrier changes"), 111 ship-to rows
-- Old carrier: 3020711 "Sioux Falls 1pm" (13:00 cutoff)  ->  New carrier: 3028898 "Sioux Falls 3pm" (15:00 cutoff)
-- Scope: dbo.ship_to.default_carrier_id only — sets the default for FUTURE orders on these ship-to's.
--        Does NOT touch carrier_id on already-open oe_hdr/transfer_hdr rows (separate pass if needed).
use P21Play;

DECLARE @ship_to_ids TABLE (ship_to_id DECIMAL(15,2) PRIMARY KEY);
INSERT INTO @ship_to_ids (ship_to_id) VALUES
    (1001618),(1004235),(1009585),(1012371),(1022148),(1024926),(1035530),(1036692),(1040380),(1040965),
    (1040967),(1040985),(1042058),(1042585),(1043015),(1043230),(1043430),(1043465),(1043490),(1043530),
    (1043550),(1043800),(1044890),(1044910),(1045170),(1045253),(1045320),(1059907),(1059917),(1060438),
    (1060478),(1181181),(1218695),(1221117),(3000178),(3000397),(3000432),(3000463),(3000465),(3000466),
    (3000468),(3000478),(3000522),(3000533),(3000537),(3001857),(3002290),(3003732),(3003733),(3003761),
    (3004186),(3006082),(3008292),(3012950),(3013049),(3013992),(3015315),(3020978),(3021028),(3021597),
    (3021600),(3021687),(3023305),(3023416),(3023427),(3023440),(3023444),(3023445),(3023448),(3023450),
    (3023451),(3023454),(3023816),(3023457),(3023458),(3023486),(3023488),(3023490),(3023491),(3023540),
    (3023542),(3023591),(3023593),(3023600),(3023602),(3023605),(3023619),(3023621),(3023654),(3023656),
    (3023669),(3023715),(3023716),(3023717),(3023718),(3023732),(3023734),(3023763),(3023765),(3023818),
    (3023824),(3023842),(3023861),(3023864),(3024661),(3024921),(3024959),(3025653),(3027287),(3027952),
    (3028670);

-- Preview: current carrier distribution across the 111 rows (expect mostly 3020711, maybe some already 3028898)
SELECT st.default_carrier_id, COUNT(*) AS rows_affected
FROM dbo.ship_to st
INNER JOIN @ship_to_ids t ON t.ship_to_id = st.ship_to_id
GROUP BY st.default_carrier_id
ORDER BY st.default_carrier_id;

UPDATE st
SET default_carrier_id = 3028898,
    date_last_modified  = GETDATE(),
    last_maintained_by  = 'mgoldyn'
FROM dbo.ship_to st
INNER JOIN @ship_to_ids t ON t.ship_to_id = st.ship_to_id
WHERE ISNULL(st.delete_flag, 'N') <> 'Y'
  AND st.default_carrier_id <> 3028898;

-- Verify after: all 111 should now show default_carrier_id = 3028898
SELECT st.default_carrier_id, COUNT(*) AS rows_affected
FROM dbo.ship_to st
INNER JOIN @ship_to_ids t ON t.ship_to_id = st.ship_to_id
GROUP BY st.default_carrier_id
ORDER BY st.default_carrier_id;
