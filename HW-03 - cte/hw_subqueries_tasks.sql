/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select p.PersonID, p.FullName
from Application.People p 
where p.IsSalesperson = 1 
and p.PersonID not in (select distinct i.SalespersonPersonID from Sales.Invoices i where i.InvoiceDate = '20150704');

with SalesPersonCTE as
(select distinct i.SalespersonPersonID 
from Sales.Invoices i 
where i.InvoiceDate = '20150704')
select p.PersonID, p.FullName
from Application.People p 
left join SalesPersonCTE c on c.SalespersonPersonID = p.PersonID
where p.IsSalesperson = 1 and c.SalespersonPersonID is null

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

select si.StockItemID, si.StockItemName, si.UnitPrice
from Warehouse.StockItems si
where si.UnitPrice = (select min(si.UnitPrice) from Warehouse.StockItems si)

select si.StockItemID, si.StockItemName, si.UnitPrice
from Warehouse.StockItems si
where si.UnitPrice <= all (select si.UnitPrice from Warehouse.StockItems si)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

select c.CustomerID, c.CustomerName
from Sales.Customers c 
where c.CustomerID in (select top 5 ct.CustomerID from Sales.CustomerTransactions ct order by ct.TransactionAmount desc);

with MaxTranCTE as
(select top 5 ct.CustomerID 
from Sales.CustomerTransactions ct 
order by ct.TransactionAmount desc)
select c.CustomerID, c.CustomerName
from Sales.Customers c 
where c.CustomerID in (select CustomerID from MaxTranCTE);

with MaxTranCTE as
(select top 5 ct.CustomerID 
from Sales.CustomerTransactions ct 
order by ct.TransactionAmount desc)
select /*distinct*/ c.CustomerID, c.CustomerName
from Sales.Customers c 
join MaxTranCTE mt on mt.CustomerID = c.CustomerID;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

with PricesCTE as
(select top 3 si.UnitPrice 
from Warehouse.StockItems si 
order by si.UnitPrice desc),
StockItemsCTE as
(select distinct il.InvoiceID
from Sales.InvoiceLines il
where il.UnitPrice in (select p.UnitPrice from PricesCTE p))
select distinct cc.CityID, cc.CityName, p.FullName
from StockItemsCTE s
join Sales.Invoices i on i.InvoiceID = s.InvoiceID
join Sales.Customers c on c.CustomerID = i.CustomerID
join Application.Cities cc on cc.CityID = c.DeliveryCityID
join Application.People p on p.PersonID = i.PackedByPersonID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос
SET STATISTICS IO, TIME ON

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

-- --
-- Выбор прождаж с суммой продажи > 27000, расчет суммы заказа

with SalesTotalsCTE as
(
select il.InvoiceID, sum(il.Quantity * il.UnitPrice) as TotalSumm
from Sales.InvoiceLines il
group by il.InvoiceID
having sum(il.Quantity * il.UnitPrice) > 27000
), 
InvoicesCTE as
(
select i.InvoiceID, i.InvoiceDate, i.SalespersonPersonID, i.OrderID
from Sales.Invoices i
join SalesTotalsCTE st on st.InvoiceID = i.InvoiceID
),
OrdersCTE as
(
select o.OrderId 
from Sales.Orders o
join InvoicesCTE i on i.OrderID = o.OrderID
where o.PickingCompletedWhen is not null
),
TotalSummForPickedItemsCTE as
(
select ol.OrderID, sum(ol.PickedQuantity * ol.UnitPrice) as OrderSum
from Sales.OrderLines ol 
join OrdersCTE o on o.OrderID = ol.OrderID
group by ol.OrderID
)
select i.InvoiceID, i.InvoiceDate, p.FullName as SalesPersonName, st.TotalSumm as TotalSummByInvoice, t.OrderSum
from InvoicesCTE i
join SalesTotalsCTE st on st.InvoiceID = i.InvoiceID
join Application.People p on p.PersonID = i.SalespersonPersonID
join TotalSummForPickedItemsCTE t on t.OrderID = i.OrderID
order by st.TotalSumm desc

--with SalesTotalsCTE as
--(
--select il.InvoiceID, sum(il.Quantity * il.UnitPrice) as TotalSumm
--from Sales.InvoiceLines il
--group by il.InvoiceID
--having sum(il.Quantity * il.UnitPrice) > 27000
--), 
--OrdersCTE as
--(
--select o.OrderId 
--from Sales.Orders o
--where o.PickingCompletedWhen is not null
--),
--TotalSummForPickedItemsCTE as
--(
--select ol.OrderID, sum(ol.PickedQuantity * ol.UnitPrice) as OrderSum
--from Sales.OrderLines ol 
--join OrdersCTE o on o.OrderID = ol.OrderID
--group by ol.OrderID
--)
--select i.InvoiceID, i.InvoiceDate, p.FullName as SalesPersonName, st.TotalSumm as TotalSummByInvoice, t.OrderSum
--from Sales.Invoices i
--join SalesTotalsCTE st on st.InvoiceID = i.InvoiceID
--join Application.People p on p.PersonID = i.SalespersonPersonID
--join TotalSummForPickedItemsCTE t on t.OrderID = i.OrderID
--order by st.TotalSumm desc
