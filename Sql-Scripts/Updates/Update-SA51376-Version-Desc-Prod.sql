use P21;

-- SA-51376: the DynaChange deploy guide's Step 1 calls for appending a dated changelog line to
-- custom_objects.version_desc before making the column change. This got missed on all 21 Prod
-- role versions during the 2026-08-06 rollout (caught 2026-08-07). Appending it now, matching the
-- established convention (e.g. "-added carrier, class 1 | 20260805 - ...").

DECLARE @uids TABLE (custom_objects_uid int PRIMARY KEY);
INSERT INTO @uids (custom_objects_uid) VALUES
    (158), (909), (910), (911), (913), (914), (916), (917), (919), (921), (922), (923), (924),
    (927), (928), (929), (930), (931), (932), (1754), (2990);

-- === BEFORE ===
SELECT custom_objects_uid, version_id, version_desc
FROM custom_objects
WHERE custom_objects_uid IN (SELECT custom_objects_uid FROM @uids)
ORDER BY version_id;

-- === UPDATE ===
UPDATE custom_objects
SET version_desc = version_desc + ' | 20260806 - SA 51376 Add RMA Reason Code'
WHERE custom_objects_uid IN (SELECT custom_objects_uid FROM @uids);

-- === AFTER ===
SELECT custom_objects_uid, version_id, version_desc
FROM custom_objects
WHERE custom_objects_uid IN (SELECT custom_objects_uid FROM @uids)
ORDER BY version_id;
