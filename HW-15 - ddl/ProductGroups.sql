USE [IM]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (N'dbo.ProductGroups', N'U') IS NOT NULL  -- U - пользовательская таблица
	DROP TABLE dbo.ProductGroups;  
GO  

CREATE TABLE [dbo].[ProductGroups]
(
	[ID_ProductGroup] [int] IDENTITY(1, 1) NOT NULL,
	[ProductGroupName] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_ProductGroups_ID_ProductGroup] PRIMARY KEY CLUSTERED 
(
	[ID_ProductGroup] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] 
GO

