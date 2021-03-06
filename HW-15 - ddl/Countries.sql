USE [IM]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (N'dbo.Countries', N'U') IS NOT NULL  -- U - пользовательская таблица
	DROP TABLE dbo.Countries;  
GO  

CREATE TABLE [dbo].[Countries]
(
	[ID_Country] [int] IDENTITY(1, 1) NOT NULL,
	[CountryName] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_Countries_ID_Country] PRIMARY KEY CLUSTERED 
(
	[ID_Country] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] 
GO

