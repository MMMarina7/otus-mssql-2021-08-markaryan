USE [IM]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (N'dbo.Orders', N'U') IS NOT NULL  -- U - пользовательская таблица
	DROP TABLE dbo.Orders;  
GO  

IF OBJECT_ID (N'FK_Orders_ID_Customer_Customers', N'F') IS NOT NULL  -- F - ограничение FOREIGN KEY
	ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_ID_Customer_Customers];  
GO  

IF OBJECT_ID (N'DF_Orders_RecordDate', N'D') IS NOT NULL  -- D - значение по умолчанию (DEFAULT), в ограничении или независимо заданное
	ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [DF_Orders_RecordDate];  
GO 

CREATE TABLE [dbo].[Orders]
(
	[ID_Order] [int] IDENTITY(1, 1) NOT NULL,
	[ID_OrderIM] [int] NOT NULL,
	[ID_Customer] [int] NOT NULL,
	[OrderPrice] [decimal](18, 2) NOT NULL,
	[DeliveryPrice] [decimal](18, 2) NOT NULL,
	[OrderDate] [date] NOT NULL,
	[RecordDate] [datetime2](7) NOT NULL,
	[ProcessDate] [datetime2](7) NULL,
 CONSTRAINT [PK_Orders_ID_Order] PRIMARY KEY CLUSTERED 
(
	[ID_Order] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Orders] WITH CHECK ADD CONSTRAINT [FK_Orders_ID_Customer_Customers] FOREIGN KEY([ID_Customer])
REFERENCES [dbo].[Customers] ([ID_Customer])
GO

ALTER TABLE [dbo].[Orders] ADD CONSTRAINT [DF_Orders_RecordDate] DEFAULT (GETDATE()) FOR [RecordDate]
GO
