USE [IM]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (N'dbo.Suppliers', N'U') IS NOT NULL  -- U - пользовательская таблица
	DROP TABLE dbo.Suppliers;  
GO  

CREATE TABLE [dbo].[Suppliers]
(
	[ID_Supplier] [int] IDENTITY(1, 1) NOT NULL,
	[SupplierName] [nvarchar](100) NOT NULL,
	[ID_Country] [int] NOT NULL,
	[RecordDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Suppliers_ID_Supplier] PRIMARY KEY CLUSTERED 
(
	[ID_Supplier] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Suppliers] WITH CHECK ADD CONSTRAINT [FK_Suppliers_ID_Country_Countries] FOREIGN KEY([ID_Country])
REFERENCES [dbo].[Countries] ([ID_Country])
GO

ALTER TABLE [dbo].[Suppliers] ADD CONSTRAINT [DF_Suppliers_RecordDate] DEFAULT (GETDATE()) FOR [RecordDate]
GO