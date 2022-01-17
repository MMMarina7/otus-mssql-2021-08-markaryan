USE [IM]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (N'dbo.Customers', N'U') IS NOT NULL  -- U - пользовательская таблица
	DROP TABLE dbo.Customers;  
GO  

CREATE TABLE [dbo].[Customers]
(
	[ID_Customer] [int] IDENTITY(1, 1) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[PhoneNumber] [nvarchar](50) NOT NULL UNIQUE NONCLUSTERED,
	[E-mail] [nvarchar](50) NOT NULL UNIQUE NONCLUSTERED,
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