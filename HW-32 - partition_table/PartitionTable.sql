-- ��������������� �������
   
-- ����:
-- � ���� �� �� �������� �������-�������� ��� ��������������� � ��������� ��������� �����������������. 
   
-- �������� � ����� ������� �������-�������� ��� ��������������� � ��������� �����������������. 
-- ���� � ������� ��� ����� �������, �� ������ ������ ���� ������ �� ������� ������, �������� ������� � ������ �� ���������������, 
-- � ��������� ������ �� ������� (���������) - ������ �� ����, ��� ������� �������, ����� ������� �������� � ���������������� �������

USE IM;

-- �������� �������� ������ 
ALTER DATABASE [IM] ADD FILEGROUP [YearData];
GO

-- ���������� ����� ��
ALTER DATABASE [IM] ADD FILE
(
	NAME = N'Year',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\Year.ndf',
    SIZE = 1097152KB,
    FILEGROWTH = 65536KB
)
TO FILEGROUP [YearData];
GO

-- �������� ������� ����������������� �� �����
CREATE PARTITION FUNCTION [fnYearPartition](DATE) AS RANGE RIGHT FOR VALUES
('20200101', '20210101', '20220101');																																																									
GO

-- �������� �����
CREATE PARTITION SCHEME [schmYearPartition] AS PARTITION [fnYearPartition] ALL TO ([YearData])
GO

DROP TABLE IF EXISTS dbo.OrdersPartitioned;

-- �������� ���������������� �������
CREATE TABLE [dbo].[OrdersPartitioned]
(
	[ID_Order] [int] NOT NULL,
	[ID_OrderIM] [int] NOT NULL,
	[ID_Customer] [int] NOT NULL,
	[OrderPrice] [decimal](18, 2) NOT NULL,
	[DeliveryPrice] [decimal](18, 2) NOT NULL,
	[OrderDate] [date] NOT NULL,
	[RecordDate] [datetime2](7) NOT NULL,
	[ProcessDate] [datetime2](7) NULL,
) ON [schmYearPartition]([OrderDate])
GO

--IF OBJECT_ID (N'PK_OrdersPartitioned', N'PK') IS NOT NULL  -- PK - ����������� PRIMARY KEY
--	ALTER TABLE [dbo].[OrdersPartitioned] DROP CONSTRAINT [PK_Sales_OrdersPartitioned];  
--GO  

ALTER TABLE [dbo].[OrdersPartitioned] ADD CONSTRAINT PK_OrdersPartitioned
PRIMARY KEY CLUSTERED ([OrderDate], [ID_Order]) ON [schmYearPartition]([OrderDate]);
GO

--IF OBJECT_ID (N'DF_OrdersPartitioned_RecordDate', N'D') IS NOT NULL  -- D - �������� �� ��������� (DEFAULT), � ����������� ��� ���������� ��������
--	ALTER TABLE [dbo].[OrdersPartitioned] DROP CONSTRAINT [DF_OrdersPartitioned_RecordDate];  
--GO 

ALTER TABLE [dbo].[OrdersPartitioned] ADD CONSTRAINT [DF_OrdersPartitioned_RecordDate] DEFAULT (GETDATE()) FOR [RecordDate]
GO

/*
DROP TABLE IF EXISTS dbo.OrdersPartitioned;
DROP PARTITION SCHEME [schmYearPartition];
DROP PARTITION FUNCTION [fnYearPartition];
*/

INSERT INTO dbo.OrdersPartitioned (ID_Order, ID_OrderIM, ID_Customer, OrderPrice, DeliveryPrice, OrderDate, ProcessDate)
SELECT o.ID_Order, o.ID_OrderIM, o.ID_Customer, o.OrderPrice, o.DeliveryPrice, o.OrderDate, o.ProcessDate
FROM dbo.Orders AS o;
GO

-- ��������
/*
USE IM;

SELECT DISTINCT t.name
FROM sys.partitions AS p
JOIN sys.tables AS t ON t.object_id = p.object_id 
WHERE p.partition_number <> 1;

SELECT COUNT(*) OrdCount FROM dbo.Orders;

SELECT $PARTITION.fnYearPartition(OrderDate) AS [Partition], COUNT(*) AS [OrdCount], MIN(OrderDate) AS MinOrderDate, MAX(OrderDate) AS MaxOrderDate
FROM dbo.OrdersPartitioned
GROUP BY $PARTITION.fnYearPartition(OrderDate) 
ORDER BY [Partition];

SELECT *
FROM dbo.OrdersPartitioned AS op
WHERE op.ID_Customer = 1

SELECT *
FROM dbo.OrdersPartitioned AS op
WHERE op.ID_Customer = 1 AND op.OrderDate BETWEEN '20210101' AND '20211231'
*/