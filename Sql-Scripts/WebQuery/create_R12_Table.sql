USE [WQMetaDatPlay2]
GO

/****** Object:  Table [dbo].[R12_sales]    Script Date: 10/6/2022 11:03:43 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[R12_sales](
	[company_no] [varchar](8) NOT NULL,
	[sales_location_id] [decimal](19, 0) NOT NULL,
	[inv_mast_uid] [int] NOT NULL,
	[R12DirectQtyShip] [decimal](38, 13) NULL,
	[R12DirectSales] [decimal](38, 17) NULL,
	[R12DirectCost] [decimal](38, 4) NULL,
	[R12DirectGM] [decimal](38, 17) NULL,
	[R12DirectLines] [int] NULL,
	[R12WarehouseQtyShip] [decimal](38, 13) NULL,
	[R12WarehouseSales] [decimal](38, 17) NULL,
	[R12WarehouseCost] [decimal](38, 4) NULL,
	[R12WarehouseGM] [decimal](38, 17) NULL,
	[R12WarehouseLines] [int] NULL,
	[R12QtyShip] [decimal](38, 13) NULL,
	[R12Sales] [decimal](38, 17) NULL,
	[R12Cost] [decimal](38, 4) NULL,
	[R12GM] [decimal](38, 4) NULL,
	[R12Lines] [int] NULL,
	[R12MonthsSold] [int] NULL,
	[r12Avg_unit_price] [decimal](38, 6) NULL,
	[orders_1] [int] NULL,
	[orders_2] [int] NULL,
	[orders_3] [int] NULL,
	[orders_4] [int] NULL,
	[orders_5] [int] NULL,
	[orders_6] [int] NULL,
	[orders_7] [int] NULL,
	[orders_8] [int] NULL,
	[orders_9] [int] NULL,
	[orders_10] [int] NULL,
	[orders_11] [int] NULL,
	[orders_12] [int] NULL,
	[R12OrderAmt] [money] NULL,
	[R12AvgOrderPrice] [money] NULL,
	[last_ship_date] [datetime] NULL,
	[last_sales_date] [datetime] NULL,
	[last_xfer_date] [datetime] NULL,
	[last_prod_order_date] [datetime] NULL,
	[last_order_date] [datetime] NULL,
	[last_purch_date] [datetime] NULL,
	[first_purch_date] [datetime] NULL,
	[max_date] [datetime] NULL,
	[last_xfer_to_date] [datetime] NULL,
	[shipped_1] [int] NULL,
	[shipped_2] [int] NULL,
	[shipped_3] [int] NULL,
	[shipped_4] [int] NULL,
	[shipped_5] [int] NULL,
	[shipped_6] [int] NULL,
	[shipped_7] [int] NULL,
	[shipped_8] [int] NULL,
	[shipped_9] [int] NULL,
	[shipped_10] [int] NULL,
	[shipped_11] [int] NULL,
	[shipped_12] [int] NULL,
	[shipped_mtd] [int] NULL,
	[qty_shipped_30d] [int] NULL,
	[qty_shipped_60d] [int] NULL,
	[qty_shipped_90d] [int] NULL,
	[qty_ship_30] [int] NULL,
	[qty_ship_60] [int] NULL,
	[qty_ship_90] [int] NULL,
	[rma_30] [int] NULL,
	[rma_60] [int] NULL,
	[rma_90] [int] NULL,
	[on_sched] [int] NULL,
 CONSTRAINT [PK_R12_sales] PRIMARY KEY CLUSTERED 
(
	[company_no] ASC,
	[sales_location_id] ASC,
	[inv_mast_uid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


