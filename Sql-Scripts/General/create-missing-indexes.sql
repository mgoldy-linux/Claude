CREATE INDEX <index_name> ON [P21].[dbo].[bin] ([location_id], [bin_type_uid], [pick_locked_flag], [frozen_flag])
CREATE INDEX [IX_bin_location_id_bin_type_uid_pick_locked_flag_frozen_flag_A59CE] ON [P21].[dbo].[bin] ([location_id], [bin_type_uid], [pick_locked_flag], [frozen_flag])

CREATE INDEX <index_name> ON [P21].[dbo].[document_summary] ([receiver], [document_group_id])

CREATE INDEX <index_name> ON [QuickShip].[dbo].[ContainerContent] ([ContainerId]) INCLUDE ([ShipmentLineId], [QtyPacked], [CreateDate], [CreatedBy], [ModifyDate], [ModifiedBy], [ErpKey], [HazmatGroupId])

CREATE INDEX <index_name> ON [P21].[dbo].[bin] ([location_id], [pick_locked_flag], [frozen_flag]) INCLUDE ([bin_type_uid])

CREATE INDEX <index_name> ON [P21].[dbo].[inv_xref] ([inv_mast_uid])

CREATE INDEX <index_name> ON [QuickShip].[dbo].[Container] ([ShipmentId])

CREATE INDEX <index_name> ON [QuickShip].[dbo].[ContainerContent] ([ContainerId])

CREATE INDEX <index_name> ON [P21].[dbo].[inv_mast] ([delete_flag],[product_type]) INCLUDE ([inv_mast_uid], [item_desc], [class_id1], [class_id5], [short_code], [price1], [default_sales_discount_group])

CREATE INDEX <index_name> ON [QuickShip].[dbo].[ShipmentHistory] ([ContainerId]) INCLUDE ([ShipmentId], [StartDate], [EndDate], [RecordType], [UserId], [Workstation], [Description], [QtyProcessed], [ValueProcessed], [CreateDate], [CreatedBy], [ModifyDate], [ModifiedBy])

CREATE INDEX <index_name> ON [P21].[dbo].[customer_edi_trans_detail] ([customer_edi_transaction_uid]) INCLUDE ([name], [value])

CREATE INDEX <index_name> ON [P21].[dbo].[_oe_QTM] ([assy_im_uid], [QTM_Location_id]) INCLUDE ([QTM])

CREATE INDEX <index_name> ON [SQLSentry].[dbo].[EventSourceHistory] ([EventSourceID], [Incomplete]) INCLUDE ([RemoteID], [RemoteSequenceID], [RemoteObjectID], [ObjectID], [RunStatus], [Description], [MessageText], [StartTime], [EndTime], [NormalizedStartTime], [NormalizedEndTime], [TimeZoneFactorMinutes], [UtcOffset], [Duration], [ReviewState], [Computer], [Operator], [ErrorNumber], [HistoryType], [FirstDetailRowRemoteSequenceID], [Synchronized], [SubObjectName], [ProcessID], [Application], [Database], [HostProcessID])

CREATE INDEX <index_name> ON [P21].[dbo].[customer_edi_trans_detail] ([customer_edi_transaction_uid], [name]) INCLUDE ([value])

CREATE INDEX <index_name> ON [P21].[dbo].[customer_edi_trans_detail] ([name]) INCLUDE ([customer_edi_transaction_uid], [value])

CREATE INDEX <index_name> ON [QuickShip23].[dbo].[Shipment] ([CompanyId], [ReleaseIdentification])

CREATE INDEX <index_name> ON [QuickShip23].[dbo].[Container] ([ShipmentId])

CREATE INDEX <index_name> ON [QuickShip].[dbo].[IntegrationJobLog] ([IntegrationJobId]) INCLUDE ([Sequence])

CREATE INDEX <index_name> ON [QuickShip].[dbo].[Shipment] ([CompanyId], [ReleaseIdentification])

CREATE INDEX <index_name> ON [P21].[dbo].[vendor_edi_transaction_detail] ([vendor_edi_transaction_uid], [name]) INCLUDE ([value])

CREATE INDEX <index_name> ON [QuickShip].[dbo].[Shipment] ([CompanyId], [ReleaseIdentification], [P21ShipmentType])

CREATE INDEX <index_name> ON [SQLSentry].[dbo].[PerformanceAnalysisData] ([DeviceID], [PerformanceAnalysisCounterID], [InstanceName],[Timestamp]) INCLUDE ([Value])

CREATE INDEX <index_name> ON [QuickShip23].[dbo].[Shipment] ([CompanyId], [ReleaseIdentification], [P21ShipmentType])

CREATE INDEX <index_name> ON [QuickShip23].[dbo].[Shipment] ([CompanyId], [ReleaseIdentification], [P21ShipmentType]) INCLUDE ([FacilityId], [ShipmentNumber], [ShipmentDate], [IsOpen], [IsLocked], [OrderReference], [CustomerPOReference], [DueDate], [Status], [PartialPct], [CanShipEarly], [MustShipComplete], [HoldFlag], [CustomerShipToId], [ContactName], [ActualShipCodeId], [CustomerBillingId], [BillingShipCodeId], [EstimatedWeight], [AllocatedValue], [ShipmentValue], [BOLHeaderId], [ShipmentExportId], [ActualFreightCharges], [BillableFreightCharges], [CarrierReferenceNumber], [ShipmentTrackingnumber], [Truck], [Stop], [DeliveryTime], [DeliveryInstructions], [CarrierPosted], [PostToERP], [ERPPosted], [ManifestId], [CreateDate], [CreatedBy], [ModifyDate], [ModifiedBy], [BillingMethodMiscId], [Terms], [FOB], [ShipToAddressId], [ContactPhone], [IsUpsEDS], [ReturnShipmentId], [BillingWeight], [OrderType], [CurrencyCode], [CarrierZone], [IsCarrierLabelSuppressed], [IsCOD], [LTLFreighted], [AutoConfirmShipment], [ShipmentConfirmed], [ConsolidationIdentifier], [JobId], [GenericData], [ParentShipmentId], [WorkstationId], [ShipmentIdentity], [AutoConfirmShipmentStatus], [DgisShipmentConfigurationId], [ActualFreightChargesBeforeConversion], [BillableFreightChargesBeforeConversion], [ShipmentAddtionalDetailsId], [CustomerNotes], [ShipperNotes], [AdditionalInformation1], [AdditionalInformation2])

CREATE INDEX <index_name> ON [QuickShip23].[dbo].[Shipment] ([CompanyId], [ShipmentNumber])

CREATE INDEX <index_name> ON [P21].[dbo].[vessel_receipts_line] ([po_line_uid]) INCLUDE ([vessel_receipts_hdr_uid], [line_no], [vessel_receipts_container_uid], [container_qty_received], [row_status_flag], [container_qty_unloaded])

CREATE INDEX <index_name> ON [QuickShip23].[dbo].[ContainerContent] ([ContainerId])

CREATE INDEX <index_name> ON [P21].[dbo].[vendor_edi_transaction_detail] ([name]) INCLUDE ([vendor_edi_transaction_uid], [value])

CREATE INDEX <index_name> ON [P21].[dbo].[oe_pick_ticket] ([scan_pack_uid])

CREATE INDEX <index_name> ON [P21].[dbo].[oe_hdr] ([order_date]) INCLUDE ([ship2_name], [requested_date], [delete_flag], [projected_order], [location_id], [taker], [third_party_billing_flag], [approved], [cancel_flag])

CREATE INDEX <index_name> ON [QuickShip23].[dbo].[ContainerContent] ([ErpKey])

CREATE INDEX <index_name> ON [P21].[dbo].[vessel_receipts_line] ([row_status_flag]) INCLUDE ([vessel_receipts_hdr_uid], [line_no], [po_line_uid], [vessel_receipts_container_uid], [container_qty_received], [container_qty_unloaded])

CREATE INDEX <index_name> ON [P21].[dbo].[inv_mast] ([delete_flag]) INCLUDE ([default_product_group])

CREATE INDEX <index_name> ON [P21].[dbo].[item_id_change_history] ([inv_mast_uid])

CREATE INDEX <index_name> ON [QuickShip].[dbo].[Shipment] ([CompanyId], [FacilityId]) INCLUDE ([ShipmentNumber], [ShipmentDate], [IsOpen], [IsLocked], [OrderReference], [CustomerPOReference], [DueDate], [Status], [PartialPct], [CanShipEarly], [MustShipComplete], [HoldFlag], [CustomerShipToId], [ContactName], [ReleaseIdentification], [ActualShipCodeId], [CustomerBillingId], [BillingShipCodeId], [EstimatedWeight], [AllocatedValue], [ShipmentValue], [BOLHeaderId], [ShipmentExportId], [ActualFreightCharges], [BillableFreightCharges], [CarrierReferenceNumber], [ShipmentTrackingnumber], [Truck], [Stop], [DeliveryTime], [DeliveryInstructions], [CarrierPosted], [PostToERP], [ERPPosted], [ManifestId], [CreateDate], [CreatedBy], [ModifyDate], [ModifiedBy], [BillingMethodMiscId], [Terms], [FOB], [ShipToAddressId], [ContactPhone], [IsUpsEDS], [ReturnShipmentId], [BillingWeight], [OrderType], [CurrencyCode], [CarrierZone], [IsCarrierLabelSuppressed], [IsCOD], [LTLFreighted], [AutoConfirmShipment], [ShipmentConfirmed], [P21ShipmentType], [ConsolidationIdentifier], [JobId], [GenericData])

CREATE INDEX <index_name> ON [QuickShip23].[dbo].[Shipment] ([CompanyId], [ReleaseIdentification]) INCLUDE ([FacilityId], [ShipmentNumber], [ShipmentDate], [IsOpen], [IsLocked], [OrderReference], [CustomerPOReference], [DueDate], [Status], [PartialPct], [CanShipEarly], [MustShipComplete], [HoldFlag], [CustomerShipToId], [ContactName], [ActualShipCodeId], [CustomerBillingId], [BillingShipCodeId], [EstimatedWeight], [AllocatedValue], [ShipmentValue], [BOLHeaderId], [ShipmentExportId], [ActualFreightCharges], [BillableFreightCharges], [CarrierReferenceNumber], [ShipmentTrackingnumber], [Truck], [Stop], [DeliveryTime], [DeliveryInstructions], [CarrierPosted], [PostToERP], [ERPPosted], [ManifestId], [CreateDate], [CreatedBy], [ModifyDate], [ModifiedBy], [BillingMethodMiscId], [Terms], [FOB], [ShipToAddressId], [ContactPhone], [IsUpsEDS], [ReturnShipmentId], [BillingWeight], [OrderType], [CurrencyCode], [CarrierZone], [IsCarrierLabelSuppressed], [IsCOD], [LTLFreighted], [AutoConfirmShipment], [ShipmentConfirmed], [P21ShipmentType], [ConsolidationIdentifier], [JobId], [GenericData], [ParentShipmentId], [WorkstationId], [ShipmentIdentity], [AutoConfirmShipmentStatus], [DgisShipmentConfigurationId], [ActualFreightChargesBeforeConversion], [BillableFreightChargesBeforeConversion], [ShipmentAddtionalDetailsId], [CustomerNotes], [ShipperNotes], [AdditionalInformation1], [AdditionalInformation2])

CREATE INDEX <index_name> ON [QuickShip23].[dbo].[Shipment] ([ReleaseIdentification])

CREATE INDEX <index_name> ON [P21].[dbo].[oe_line] ([delete_flag], [detail_type],[qty_on_pick_tickets]) INCLUDE ([inv_mast_uid])

CREATE INDEX <index_name> ON [P21].[dbo].[inv_mast] ([delete_flag],[class_id1], [product_type]) INCLUDE ([inv_mast_uid], [item_desc], [class_id5], [short_code], [price1], [default_sales_discount_group])

CREATE INDEX <index_name> ON [P21].[dbo].[oe_pick_ticket] ([scan_pack_uid]) INCLUDE ([order_no], [carrier_id])

CREATE INDEX <index_name> ON [P21].[dbo].[oe_hdr] ([delete_flag], [company_id], [projected_order], [rma_flag],[approved]) INCLUDE ([customer_id], [order_date], [ship2_name], [ship2_add1], [ship2_city], [ship2_state], [po_no], [completed], [po_no_append], [location_id], [taker], [source_location_id], [cancel_flag], [oe_hdr_uid], [source_id], [source_code_no], [order_type], [prepaid_invoice_flag], [web_reference_no])

CREATE INDEX <index_name> ON [QuickShip].[dbo].[ShipmentHistory] ([ContainerId],[ShipmentId]) INCLUDE ([StartDate], [EndDate], [RecordType], [UserId], [Workstation], [Description], [QtyProcessed], [ValueProcessed], [CreateDate], [CreatedBy], [ModifyDate], [ModifiedBy])

CREATE INDEX <index_name> ON [P21].[dbo].[inv_mast] ([delete_flag],[product_type]) INCLUDE ([inv_mast_uid], [item_desc], [class_id1], [class_id5], [catalog_item], [short_code], [default_selling_unit], [use_revisions_flag])

CREATE INDEX <index_name> ON [P21].[dbo].[document_summary] ([sender_type], [row_status], [acknowledge_status],[date_created]) INCLUDE ([document_id], [transaction_id], [receiver], [receiver_type], [format], [document_type])

CREATE INDEX <index_name> ON [P21].[dbo].[document_summary] ([sender_type], [row_status], [acknowledge_status],[receiver_type], [date_created]) INCLUDE ([document_id], [transaction_id], [receiver], [format], [document_type])

CREATE INDEX <index_name> ON [P21Play].[dbo].[document_summary] ([sender_type], [row_status], [acknowledge_status],[date_created]) INCLUDE ([document_id], [transaction_id], [receiver], [receiver_type], [format], [document_type])

CREATE INDEX <index_name> ON [P21Play].[dbo].[document_summary] ([sender_type], [row_status], [acknowledge_status],[receiver_type], [date_created]) INCLUDE ([document_id], [transaction_id], [receiver], [format], [document_type])

CREATE INDEX <index_name> ON [P21].[dbo].[price_page] ([row_status_flag], [on_contract_flag]) INCLUDE ([price_page_type_cd], [pricing_method_cd], [source_price_cd], [price], [calculation_method_cd], [totaling_method_cd], [totaling_basis_cd], [other_cost_type_cd], [other_cost_value], [other_cost_source_cd], [cost_calculation_method_cd], [cost_calculation_value], [currency_id], [values_currency_id], [calculator_type], [apply_freight_factor], [freight_factor_source_cd], [no_charge_flag], [rolled_item_pricing_type_cd])

CREATE INDEX <index_name> ON [SQLSentry].[dbo].[AlertingChannelLog] ([NormalizedStartTimeUtc]) INCLUDE ([ObjectID], [Severity])

CREATE INDEX <index_name> ON [SQLSentry].[dbo].[PerformanceAnalysisData] ([DeviceID], [PerformanceAnalysisCounterID],[Timestamp])

CREATE INDEX <index_name> ON [P21].[dbo].[inv_xref] ([company_id], [delete_flag], [inv_mast_uid])