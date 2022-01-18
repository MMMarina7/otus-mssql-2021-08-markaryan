USE [IM]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (N'dbo.Customers', N'U') IS NOT NULL  -- U - пользовательская таблица
	DROP TABLE dbo.Customers;  
GO  

IF OBJECT_ID (N'DF_Customers_IsActive', N'D') IS NOT NULL  -- D - значение по умолчанию (DEFAULT), в ограничении или независимо заданное
	ALTER TABLE [dbo].[Customers] DROP CONSTRAINT [DF_Customers_IsActive];  
GO  

IF OBJECT_ID (N'DF_Customers_RecordDate', N'D') IS NOT NULL  -- D - значение по умолчанию (DEFAULT), в ограничении или независимо заданное
	ALTER TABLE [dbo].[Customers] DROP CONSTRAINT [DF_Customers_RecordDate];  
GO  

CREATE TABLE [dbo].[Customers]
(
	[ID_Customer] [int] IDENTITY(1, 1) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[PhoneNumber] [nvarchar](50) NOT NULL UNIQUE NONCLUSTERED,
	[Email] [nvarchar](50) NOT NULL UNIQUE NONCLUSTERED,
	[BirthDay] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[RecordDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Customers_ID_Customer] PRIMARY KEY CLUSTERED 
(
	[ID_Customer] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [DF_Customers_IsActive] DEFAULT (1) FOR [IsActive]
GO

ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [DF_Customers_RecordDate] DEFAULT (GETDATE()) FOR [RecordDate]
GO