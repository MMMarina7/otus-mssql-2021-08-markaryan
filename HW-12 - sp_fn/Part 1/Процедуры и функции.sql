USE WideWorldImporters;
GO

SET STATISTICS TIME OFF; 
GO

--1. �������� ������� ������������ ������� � ���������� ������ �������.

IF OBJECT_ID(N'[Sales].[fnCustInvMaxSum]', N'FN') IS NOT NULL
	DROP FUNCTION [Sales].[fnCustInvMaxSum]
GO

CREATE FUNCTION [Sales].[fnCustInvMaxSum]()
RETURNS INT
AS
BEGIN
	DECLARE @CustomerID INT
	SELECT TOP 1 @CustomerID = a.CustomerID	
	FROM (SELECT i.CustomerID, SUM(il.UnitPrice * il.Quantity) AS InvSum
		FROM Sales.Invoices i
		JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
		GROUP BY i.CustomerID) AS a
	ORDER BY a.InvSum DESC

	RETURN @CustomerID
END;
GO

SELECT Sales.fnCustInvMaxSum() AS CustomerID;
GO

--2. �������� �������� ��������� � �������� ���������� �ustomerID, ��������� ����� ������� �� ����� �������. 
--   ������������ ������� : Sales.Customers Sales.Invoices Sales.InvoiceLines

/*
��� ������ ��������� � �� ������������ ������� �������� SERIALIZABLE, �. �. ��� ��� �������������� "��������� ������". 
������ ����� ������ � �������� �� ����������, � ���������� �����.
*/

IF OBJECT_ID(N'[Sales].[spCustInvSum]', N'P') IS NOT NULL
	DROP PROCEDURE [Sales].[spCustInvSum];
GO

CREATE PROCEDURE [Sales].[spCustInvSum] 
	@CustomerID INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @RetTab TABLE (CustomerID INT, CustomerName NVARCHAR(500), CustInvSum DECIMAL(18, 2))
	INSERT INTO @RetTab (CustomerID, CustomerName, CustInvSum)
	SELECT i.CustomerID, c.CustomerName, SUM(il.UnitPrice * il.Quantity) CustInvSum
	FROM Sales.Invoices i
	JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
	JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
	WHERE i.CustomerID = @CustomerID
	GROUP BY i.CustomerID, c.CustomerName

	SELECT CustomerID, CustomerName, CustInvSum
	FROM @RetTab
END;
GO

DECLARE @CustomerID INT = 132;
EXEC Sales.spCustInvSum @CustomerID = @CustomerID;
GO

--3. ������� ���������� ������� � �������� ���������, ���������� � ��� ������� � ������������������ � ������.

IF OBJECT_ID(N'[Sales].[ftCustInvSum]', N'TF') IS NOT NULL
	DROP FUNCTION [Sales].[ftCustInvSum];
GO

CREATE FUNCTION [Sales].[ftCustInvSum] 
(
	@CustomerID INT
)
RETURNS @RetTab TABLE (CustomerID INT, CustomerName NVARCHAR(500), CustInvSum DECIMAL(18, 2))
AS
BEGIN
	INSERT INTO @RetTab (CustomerID, CustomerName, CustInvSum)
	SELECT i.CustomerID, c.CustomerName, SUM(il.UnitPrice * il.Quantity) CustInvSum
	FROM Sales.Invoices i
	JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
	JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
	WHERE i.CustomerID = @CustomerID
	GROUP BY i.CustomerID, c.CustomerName
	
	RETURN 
END
GO

SET STATISTICS TIME ON;

DECLARE @CustomerID INT = 132;
EXEC Sales.spCustInvSum @CustomerID = @CustomerID;		-- ��������� �� ������ 2

SELECT cs.CustomerID, cs.CustomerName, cs.CustInvSum
FROM Sales.ftCustInvSum(@CustomerID) AS cs;
GO

SET STATISTICS TIME OFF; 
GO
--4. �������� ��������� ������� �������� ��� �� ����� ������� ��� ������ ������ result set'� ��� ������������� �����.

SELECT c.CustomerID, c.CustomerName, cs.CustInvSum
FROM Sales.Customers c
CROSS APPLY Sales.ftCustInvSum(c.CustomerID) AS cs;		-- ������� �� ������ 3
GO

--5. �����������. �� ���� ���������� ������� ����� ������� �������� ���������� �� �� ������������ � ������.

-- ����� ��� �������� ���������
