-- testing adding token

Declare @return_value int

Exec @return_value = p21_apply_alert_token
	 @alert_type_uid = 16,
	 @token_name = N'Qty_Aval',
	 @token_available_areas = 4,
	 @token_description = N'Quantity Avalaible',
	 @token_data_type_cd = 853,
	 @token_code_group_no = null

Select 'Return Value' = @return_value
