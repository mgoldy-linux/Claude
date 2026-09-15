-- Deactivate carrier flag for legacy WC carriers after orders/transfers have been migrated to 10002
-- Carriers: Brookfield, Cincinnati, Columbus, Davenport, Eagan, Fort Wayne, Indianapolis,
--           Lexington, Livonia, Louisville, North Kansas City, St Louis, Urbandale, Wyoming
use P21; --P21BusinessRules; --P21Play; --P21; --P21BusinessRules; --

-- Preview before
SELECT id, name, carrier_flag
FROM dbo.address
WHERE id IN (3004267,3001076,3001077,3000550,3004720,3000657,3000552,3000553,3001015,3000667,3000551,3000554,3020714,3006533);

UPDATE dbo.address
SET carrier_flag       = 'N',
    date_last_modified = GETDATE(),
    last_maintained_by = 'mgoldyn'
WHERE id IN (3004267,3001076,3001077,3000550,3004720,3000657,3000552,3000553,3001015,3000667,3000551,3000554,3020714,3006533)
  AND carrier_flag = 'Y';

-- Confirm after (should all show 'N')
SELECT id, name, carrier_flag
FROM dbo.address
WHERE id IN (3004267,3001076,3001077,3000550,3004720,3000657,3000552,3000553,3001015,3000667,3000551,3000554,3020714,3006533);
