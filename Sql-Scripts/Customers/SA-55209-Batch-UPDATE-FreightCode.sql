/* SA 55209 - Batch fix: flip the confirmed 173 ship-to accounts from Prepaid (6) to
   Out Freight (2). Michelle DeBartolo / Lynette Glenn approved the list 2026-09-29.

   RUN IN PLAY FIRST (per the user's own call) before this ever touches Prod. Same script,
   same list, either environment -- nothing here is env-specific except which server SSMS
   is pointed at.

   The list below is the exact 173 ship_to_id's from the confirmed Excel
   (Reports\SA-55209-ShipTo-Terms-vs-FreightCode-2026-09-23.xlsx), hardcoded rather than
   re-derived from a live query -- so this touches exactly the confirmed set even if terms/
   freight codes have shifted for anyone since 9/23.

   SCOPE STILL OPEN: whether to include the two flagged accounts (3023115 "Transfer To
   Blakely" -- looks like a placeholder/reassignment record; 3000889 "NE Dept of
   Correctional Services" -- government entity, may have non-standard billing). Set
   @exclude_flagged = 1 below to leave those two untouched; 0 to include them. Confirm this
   before running against Prod.
*/

DECLARE @exclude_flagged BIT = 0;   -- 0 = include all 173, 1 = exclude the two flagged ship_to_id's

DECLARE @ship_to_ids TABLE (ship_to_id INT PRIMARY KEY);
INSERT INTO @ship_to_ids (ship_to_id) VALUES
(1001535),(1005000),(1011370),(1013940),(1014465),(1018585),(1019930),(1022427),(1023759),(1024418),
(1025528),(1028175),(1028230),(1029117),(1032600),(1033605),(1033971),(1034148),(1034420),(1037110),
(1038348),(1038900),(1042486),(1044727),(1046630),(1049135),(1051850),(1063302),(1100507),(1103028),
(1106416),(1109530),(1115667),(1118525),(1120357),(1120829),(1122428),(1123647),(1126564),(1126566),
(1128965),(1129192),(1130038),(1130578),(1131993),(1154674),(1161877),(1164318),(1165451),(1166805),
(1167234),(1167773),(1168471),(1169103),(1169157),(1172040),(1175378),(1176750),(1178675),(1178823),
(1179587),(1181412),(1184047),(1184938),(1185069),(1185458),(1192019),(1192271),(1202645),(1205342),
(1206624),(1207596),(1208057),(1208483),(1209174),(1209192),(1209772),(1210073),(1212245),(1213275),
(1214463),(1215075),(1215946),(1217134),(1218115),(1221485),(1221878),(1223442),(1223767),(1223826),
(1224555),(1224629),(1224679),(1224833),(1225440),(1225505),(1225966),(1226038),(1227748),(1227960),
(1228414),(1228651),(1230176),(1230888),(1230945),(3000071),(3000155),(3000748),(3000851),(3000889),
(3001329),(3001467),(3001624),(3001673),(3001710),(3001712),(3001850),(3001905),(3001928),(3001973),
(3001975),(3002192),(3002225),(3002382),(3003758),(3003802),(3005657),(3005658),(3006064),(3006396),
(3006601),(3006875),(3007162),(3007459),(3008125),(3008285),(3008380),(3010877),(3011296),(3011921),
(3014142),(3014195),(3014947),(3014978),(3015252),(3020958),(3021204),(3021970),(3022191),(3022206),
(3022389),(3023114),(3023115),(3023414),(3023812),(3023813),(3023814),(3023815),(3023818),(3023841),
(3023847),(3023857),(3023858),(3023861),(3023870),(3023921),(3025188),(3025234),(3025276),(3025788),
(3026113),(3027576),(3028794);

IF @exclude_flagged = 1
    DELETE FROM @ship_to_ids WHERE ship_to_id IN (3023115, 3000889);


-- =====================================================================================
-- STEP 1: BEFORE -- confirm the target set and current state. Row count should be 173
-- (or 171 if @exclude_flagged = 1), and every row should currently show freight_code_uid = 6.
-- =====================================================================================
SELECT COUNT(*) AS target_row_count FROM @ship_to_ids;

SELECT s.ship_to_id, s.freight_code_uid, fc.freight_desc
FROM   ship_to s
JOIN   @ship_to_ids t ON t.ship_to_id = s.ship_to_id
LEFT JOIN p21_view_freight_code fc ON fc.freight_code_uid = s.freight_code_uid AND fc.row_status = 704
WHERE  s.freight_code_uid <> 6;   -- should return ZERO rows -- anything listed here already changed since 9/23


-- =====================================================================================
-- STEP 2: THE UPDATE. Commented out on purpose -- uncomment only after STEP 1 looks right.
-- =====================================================================================
-- UPDATE s
-- SET    s.freight_code_uid = 2   -- Out Freight
-- FROM   ship_to s
-- JOIN   @ship_to_ids t ON t.ship_to_id = s.ship_to_id;


-- =====================================================================================
-- STEP 3: AFTER -- confirm exactly the target row count changed, and nothing else did.
-- =====================================================================================
SELECT COUNT(*) AS rows_now_out_freight
FROM   ship_to s
JOIN   @ship_to_ids t ON t.ship_to_id = s.ship_to_id
WHERE  s.freight_code_uid = 2;   -- expect this to match STEP 1's target_row_count

SELECT s.ship_to_id, s.freight_code_uid, fc.freight_desc
FROM   ship_to s
JOIN   @ship_to_ids t ON t.ship_to_id = s.ship_to_id
LEFT JOIN p21_view_freight_code fc ON fc.freight_code_uid = s.freight_code_uid AND fc.row_status = 704
WHERE  s.freight_code_uid <> 2;   -- expect ZERO rows after the UPDATE
