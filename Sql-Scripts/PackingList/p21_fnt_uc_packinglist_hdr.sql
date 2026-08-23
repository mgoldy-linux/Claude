/*
	@ls_CompanyID, @ls_BegOrderNo, @ls_EndOrderNo, @ls_BeginBranchID, @ls_EndBranchID, @li_BeginCustomerID, @li_EndCustomerID, @ls_BeginZipCode, @ls_EndZipCode, @ls_BeginRoute, @ls_EndRoute, @li_BeginShipTo, @li_EndShipTo, @ldt_BeginDate, @ldt_EndDate, @li_BeginPickTicketNo, @li_EndPickTicketNo, @li_begin_inv_batch_no, @li_end_inv_batch_no, @li_LocationId, @li_BeginCarrierID, @li_EndCarrierID, @ls_BeginRoadnetRoute, @ls_EndRoadnetRoute
*/

select *
FROM p21_fnt_uc_packinglist_hdr('1','0','9999999999',' ','ZZZZZZ',0,99999999,' ','ZZZZZZZZZZ',' ','ZZZZZZ',0,99999999,'1/1/1950 00:00:00','12/31/2049 00:00:00',2171509,2171509,0,9999,NULL,NULL,NULL,NULL,NULL)