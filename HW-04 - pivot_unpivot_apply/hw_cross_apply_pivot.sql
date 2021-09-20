/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select convert(nvarchar(10), (datefromparts(pvt.InvoiceYear, pvt.InvoiceMonth, 1)), 104) as InvoiceMonth, 
[Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND]
from (select substring(c.CustomerName, charindex('(', c.CustomerName) + 1, charindex(')', c.CustomerName) - (charindex('(', c.CustomerName) + 1)) as CustomerName, 
	i.InvoiceID, year(i.InvoiceDate) as InvoiceYear, month(i.InvoiceDate) as InvoiceMonth
	from Sales.Customers c 
	join Sales.Invoices i on i.CustomerID = c.CustomerID 
	where c.CustomerID between 2 and 6) as s
pivot (count(InvoiceID) for CustomerName in ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND])) as pvt
order by pvt.InvoiceYear, pvt.InvoiceMonth

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select unp.CustomerName, unp.AddressLine
from (select c.CustomerName, c.DeliveryAddressLine1,c.DeliveryAddressLine2, c.PostalAddressLine1, c.PostalAddressLine2
	from Sales.Customers c 
	where c.CustomerName like 'Tailspin Toys%') c
unpivot (AddressLine for AddrLine in (c.DeliveryAddressLine1,c.DeliveryAddressLine2, c.PostalAddressLine1, c.PostalAddressLine2)) unp

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select unp.CountryID, unp.CountryName, unp.Code
from (select c.CountryID, c.CountryName, c.IsoAlpha3Code, convert(nvarchar(3), c.IsoNumericCode) IsoNumericCode
	from Application.Countries c) c
unpivot (Code for C in (c.IsoAlpha3Code, c.IsoNumericCode)) unp

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
-- Название товара или имя клиента???

select c.CustomerID, c.CustomerName, cp.StockItemID, cp.UnitPrice, cp.InvoiceDate
from Sales.Customers c
cross apply (select il.StockItemID, il.UnitPrice, i.InvoiceDate,
		row_number() over (partition by i.CustomerID order by il.UnitPrice desc) as RN
		from Sales.Invoices i
		join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
		where i.CustomerID = c.CustomerID) as cp
where cp.RN <= 2
order by c.CustomerID, cp.UnitPrice desc, cp.InvoiceDate

--;
--with DataCTE as
--(select i.CustomerID, si.StockItemID, si.StockItemName, si.UnitPrice, i.InvoiceDate,
--row_number() over (partition by i.CustomerID order by si.UnitPrice desc) as RN
--from Sales.Invoices i
--join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
--join Warehouse.StockItems si on si.StockItemID = il.StockItemID)
--select d.CustomerID, d.StockItemID, d.StockItemName, d.UnitPrice, d.InvoiceDate
--from DataCTE d
--where d.RN <= 2
--order by d.CustomerID, d.UnitPrice desc, d.InvoiceDate




