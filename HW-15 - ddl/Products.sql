USE [IM]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (N'dbo.Products', N'U') IS NOT NULL  -- U - пользовательская таблица
	DROP TABLE dbo.Products;  
GO  

CREATE TABLE [dbo].[Products]
(
	[ID_Product] [int] IDENTITY(1, 1) NOT NULL,
	[ProductName] [nvarchar](250) NOT NULL,
	[ID_Supplier] [int] NOT NULL,
	[ID_ProductGroup] [int] NOT NULL,
	[RecordDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Products_ID_Product] PRIMARY KEY CLUSTERED 
(
	[ID_Product] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Products] WITH CHECK ADD CONSTRAINT [FK_Products_ID_Supplier_Suppliers] FOREIGN KEY([ID_Supplier])
REFERENCES [dbo].[Suppliers] ([ID_Supplier])
GO

ALTER TABLE [dbo].[Products] WITH CHECK ADD CONSTRAINT [FK_Products_ID_ProductGroup_ProductGroups] FOREIGN KEY([ID_ProductGroup])
REFERENCES [dbo].[ProductGroups] ([ID_ProductGroup])
GO

ALTER TABLE [dbo].[Products] ADD CONSTRAINT [DF_Products_RecordDate] DEFAULT (GETDATE()) FOR [RecordDate]
GO