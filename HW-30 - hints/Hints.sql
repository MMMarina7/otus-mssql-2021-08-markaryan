/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "30 - ���������� Hint'� � ��������� ������������. ��".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������������� ������.
-- ����: � ���� �� �� ��������� ������������ DMV, ����� � ��� ������ ��� ������� �������.
-- ���������� ��� ���� ���������� ������ ��� ����������� �������� �������. 
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
������� 1. 
�� ������ ����� ������ �� ����� ������ � ������ � ��������, ��� ���� �� �����������, ����� ������� �� ���������, � ��� ����� �����. 
� ���� ������ ����� ��������� ����� �������, ���������� ���� � ���������� �� ������� � ��������� �����\������ �� ����������� � ����� �����������. 
������� ������ ��� ����������� ��� �����������.
*/

/*
������� 2. 
������������� ������ �� �� WorldWideImporters. 
��������� ����� ������� �� ������������ �� ������� � ��������� ����� ������, ������� ������ ��� ����������� ��� �����������.
*/

SET STATISTICS IO, TIME ON

Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
    JOIN Sales.OrderLines AS det
        ON det.OrderID = ord.OrderID
    JOIN Sales.Invoices AS Inv 
        ON Inv.OrderID = ord.OrderID
    JOIN Sales.CustomerTransactions AS Trans
        ON Trans.InvoiceID = Inv.InvoiceID
    JOIN Warehouse.StockItemTransactions AS ItemTrans
        ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
    AND (Select SupplierId
         FROM Warehouse.StockItems AS It
         Where It.StockItemID = det.StockItemID) = 12
    AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
        FROM Sales.OrderLines AS Total
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
        WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
    AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;

-- ����������� ������� ������ �����������, ������ ������� � �������, ������� ���������� �������.

WITH StockItemsCTE AS 
(
	SELECT si.StockItemID FROM Warehouse.StockItems AS si WHERE si.SupplierId = 12
),
CustomersCTE AS
(
	SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice) AS Price, SUM(det.Quantity) AS Quantity, COUNT(ord.OrderID) AS Orders
	FROM Sales.Orders AS ord
	JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID 
	JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID AND Inv.BillToCustomerID <> ord.CustomerID AND Inv.InvoiceDate = ord.OrderDate 
	-- JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID	-- ���������, �����, ����� ���� �������� �����
	WHERE det.StockItemID IN (SELECT si.StockItemID FROM StockItemsCTE si)
	GROUP BY ord.CustomerID, det.StockItemID, Inv.CustomerID
)
SELECT c.CustomerID, c.StockItemID, c.Price, c.Quantity, c.Orders
FROM CustomersCTE c
CROSS APPLY (SELECT SUM(ol.UnitPrice * ol.Quantity) AS OrderSum
			FROM Sales.Orders  AS o
			JOIN Sales.OrderLines AS ol ON ol.OrderID = o.OrderID
			WHERE o.CustomerID = c.CustomerID) AS os 
WHERE os.OrderSum > 250000 
ORDER BY c.CustomerID, c.StockItemID;


