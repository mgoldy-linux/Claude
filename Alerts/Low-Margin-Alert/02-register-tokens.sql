/*==============================================================================
  Low Margin Alert — Step 2: register the alert tokens
  Target : P21Play  (then, unchanged, P21 Prod)
  Author : Mark Goldyn / Claude          Date: 2026-07-14
  Depends on: 01-alter-view-add-margin-columns.sql (tokens reference view columns)

  IDEMPOTENT — p21_apply_alert_token is safe to re-run; the description UPDATE
  at the end is required every time (see below).

  data_type_cd — VERIFIED against code_p21, NOT taken from the how-to doc,
  which is WRONG (it claims 851 = decimal):
        850 = varchar      851 = char       852 = int
        853 = decimal      854 = datetime

  available_areas (bitmask):
        4  = line item body      11 = order header     32 = event/order level
        36 = 32+4 (body AND filterable)

  The percent_profit_* tokens MUST carry bit 32 (hence 36): alert FILTERS read
  event-level tokens, and these two are the triggers.

  p21_apply_alert_token OVERWRITES @token_description with the raw view column
  formula. The UPDATE at the bottom is not optional.
==============================================================================*/

USE P21Play;
GO

SET NOCOUNT ON;
DECLARE @rc INT;

/*--- Line item body: displayed per line in the email ---*/
EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'price_page_description',
     @token_available_areas=4,  @token_description=N'Price Page Description',
     @token_data_type_cd=850,  @token_code_group_no=NULL;                       -- varchar

EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'unit_mac',
     @token_available_areas=4,  @token_description=N'MAC',
     @token_data_type_cd=853,  @token_code_group_no=NULL;                       -- decimal (mirrors unit_price)

EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'unit_standard_cost',
     @token_available_areas=4,  @token_description=N'Standard Cost',
     @token_data_type_cd=853,  @token_code_group_no=NULL;                       -- decimal

/*--- Body AND filter (36 = 4 + 32): these two are the alert TRIGGERS ---*/
EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'percent_profit_off_mac',
     @token_available_areas=36, @token_description=N'Percent Profit off MAC',
     @token_data_type_cd=853,  @token_code_group_no=NULL;                       -- decimal

EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'percent_profit_off_standard_cost',
     @token_available_areas=36, @token_description=N'Percent Profit off Standard Cost',
     @token_data_type_cd=853,  @token_code_group_no=NULL;                       -- decimal

/*--- Event level only: single-row filter for the combined "Team" alert ---*/
EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'low_margin_flag',
     @token_available_areas=32, @token_description=N'Low Margin Flag',
     @token_data_type_cd=851,  @token_code_group_no=NULL;                       -- char (mirrors new_order)

/*--- Header: location NAMES (Evan asked for "Loc # and Name") ---
  available_areas 43 = 32 + 11 -> event AND header.  Bit 11 (8+2+1) is what makes
  a token render in the HEADER block; without it, it comes out as literal text
  (proven live: sales_location_id at 32 rendered as "<sales_location_id>").      */
EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'sales_location_name',
     @token_available_areas=43, @token_description=N'Sales Location Name',
     @token_data_type_cd=850,  @token_code_group_no=NULL;                       -- varchar

EXEC @rc = dbo.p21_apply_alert_token @alert_type_uid=12, @token_name=N'ship_location_name',
     @token_available_areas=43, @token_description=N'Ship Location Name',
     @token_data_type_cd=850,  @token_code_group_no=NULL;                       -- varchar
GO

/*--- REQUIRED: two EXISTING tokens need the header bit -------------------------
  Evan's mock puts Sales Location ID and Ship Location ID in the HEADER, but both
  are registered available_areas = 32 (event only).  A token only renders in the
  header if bit 11 (8+2+1) is set -- proven live: customer_name (11),
  customer_id (43), primary_salesrep_name (139) and taker (171) all rendered;
  sales_location_id (32) and source_location_id (32) came out as the LITERAL TEXT
  "<sales_location_id>" in the test email.  43 = 32 + 11 = event AND header.

  ⚠ SCOPE BY token_uid, NOT BY NAME.  'source_location_id' is a DUPLICATE token
  name: uid 236 = Order Entry (ours), uid 103 = inv_TransferEntry /
  inv_OrderBasedTransferUpdate (NOT ours).  A name-based UPDATE hits both.
------------------------------------------------------------------------------*/
UPDATE t SET t.available_areas = 43, t.date_last_modified = GETDATE()
FROM token t
JOIN alert_type_x_token x ON x.token_uid = t.token_uid
WHERE x.alert_type_uid = 12                                   -- Order Entry ONLY
  AND t.name IN ('sales_location_id','source_location_id')
  AND t.available_areas = 32;
GO

/*--- REQUIRED: the proc overwrites description with the raw column formula ---*/
UPDATE token SET description = 'Price Page Description'            WHERE name = 'price_page_description';
UPDATE token SET description = 'MAC'                               WHERE name = 'unit_mac';
UPDATE token SET description = 'Standard Cost'                     WHERE name = 'unit_standard_cost';
UPDATE token SET description = 'Percent Profit off MAC'            WHERE name = 'percent_profit_off_mac';
UPDATE token SET description = 'Percent Profit off Standard Cost'  WHERE name = 'percent_profit_off_standard_cost';
UPDATE token SET description = 'Low Margin Flag'                   WHERE name = 'low_margin_flag';
UPDATE token SET description = 'Sales Location Name'               WHERE name = 'sales_location_name';
UPDATE token SET description = 'Ship Location Name'                WHERE name = 'ship_location_name';
GO

/*--- Verify: 6 rows, human-readable descriptions, correct areas/types ---*/
SELECT t.token_uid, t.name, t.description, t.available_areas, t.data_type_cd
FROM   token t
JOIN   alert_type_x_token x ON x.token_uid = t.token_uid
WHERE  x.alert_type_uid = 12
  AND  t.name IN ('price_page_description','unit_mac','unit_standard_cost',
                  'percent_profit_off_mac','percent_profit_off_standard_cost','low_margin_flag',
                  'sales_location_name','ship_location_name',
                  'sales_location_id','source_location_id')   -- the 2 repointed to 43
ORDER BY t.name;
GO
