-- Написать хранимую процедуру возвращающую Клиента с набольшей разовой суммой покупки. 

IF OBJECT_ID(N'[Sales].[spMaxInvSum]', N'P') IS NOT NULL
	DROP PROCEDURE [Sales].[spMaxInvSum];
GO

CREATE PROCEDURE [Sales].[spMaxInvSum] 
AS
BEGIN
	WITH InvSumCTE AS
	(
		SELECT i.InvoiceID, i.CustomerID, SUM(il.UnitPrice * il.Quantity) AS InvSum
		FROM Sales.Invoices i
		JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
		GROUP BY i.InvoiceID, i.CustomerID
	),
	MaxInvSumCTE AS
	(
		SELECT MAX(InvSum) AS MaxInvSum
		FROM InvSumCTE
	)
	SELECT c.CustomerID, c.CustomerName
	FROM InvSumCTE i
	JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
	WHERE i.InvSum = (SELECT MaxInvSum FROM MaxInvSumCTE)
END;
GO;

EXEC [Sales].[spMaxInvSum] 
GO;