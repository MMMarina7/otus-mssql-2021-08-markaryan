/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "30 - Популярные Hint'ы и подсказки оптимизатору. ДЗ".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - Оптимизировать запрос.
-- Цель: В этом ДЗ вы научитесь использовать DMV, хинты и все прочее для сложных случаев.
-- Используем все свои полученные знания для оптимизации сложного запроса. 
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
Вариант 1. 
Вы можете взять запрос со своей работы с планом и показать, что было до оптимизации, какие решения вы применили, и что стало после. 
В этом случае нужно приложить Текст запроса, актуальный план и статистики по времени и операциям ввода\вывода до оптимизации и после оптимизации. 
Опишите кратко ход рассуждений при оптимизации.
*/

/*
Вариант 2. 
Оптимизируйте запрос по БД WorldWideImporters. 
Приложите текст запроса со статистиками по времени и операциям ввода вывода, опишите кратко ход рассуждений при оптимизации.
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

-- Постаралась сделать запрос читабельнее, убрала таблицы и функцию, которые показались лишними.

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
	-- JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID	-- Непонятно, зачем, вроде дает ненужные дубли
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


