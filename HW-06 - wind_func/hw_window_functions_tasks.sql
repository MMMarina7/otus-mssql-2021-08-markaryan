/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
set statistics time, io on;

with InvoceSumCTE as
(
	select i.InvoiceID, c.CustomerName, i.InvoiceDate, eomonth(i.InvoiceDate) as InvEOMonthDate,
	sum(ct.TransactionAmount) as InvoceSum	
	from Sales.Invoices i 
	join Sales.CustomerTransactions ct on ct.InvoiceID = i.InvoiceID	
	join Sales.Customers c on c.CustomerID = i.CustomerID
	where i.InvoiceDate between '20150101' and '20210925' 
	group by i.InvoiceID, c.CustomerName, i.InvoiceDate
),
TotalCTE as
(
	select eomonth(i.InvoiceDate) as EOMonthDate, sum(i.InvoceSum) +
	(select isnull(sum(ii.InvoceSum), 0)
	from InvoceSumCTE ii
	where eomonth(ii.InvoiceDate) < eomonth(i.InvoiceDate)) as Total
	from InvoceSumCTE i 
	group by eomonth(i.InvoiceDate) 
)
select i.InvoiceID, i.CustomerName, i.InvoiceDate, i.InvoceSum, t.Total
from InvoceSumCTE i
join TotalCTE t on t.EOMonthDate = InvEOMonthDate
order by i.InvoiceDate, i.InvoiceID

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select i.InvoiceID, c.CustomerName, i.InvoiceDate,
sum(ct.TransactionAmount) over (partition by i.InvoiceID) as InvoceSum, 
sum(ct.TransactionAmount) over (order by year(i.InvoiceDate), month(i.InvoiceDate)) as Total
from Sales.Invoices i 
join Sales.CustomerTransactions ct on ct.InvoiceID = i.InvoiceID
join Sales.Customers c on c.CustomerID = i.CustomerID
where i.InvoiceDate between '20150101' and '20210925'
order by i.InvoiceDate, i.InvoiceID;

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select distinct i.InvoiceMonth, i.StockItemID, wsi.StockItemName
from Sales.Invoices si
cross apply (select top 2 il.StockItemID, month(i.InvoiceDate) InvoiceMonth, sum(il.Quantity) as Quantity
			from Sales.Invoices i 
			join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
			where i.InvoiceDate between '20160101' and '20161231'
			and month(i.InvoiceDate) = month(si.InvoiceDate)
			group by il.StockItemID, month(i.InvoiceDate)
			order by InvoiceMonth, Quantity desc) i
join Warehouse.StockItems wsi on wsi.StockItemID = i.StockItemID
where si.InvoiceDate between '20160101' and '20161231'
order by i.InvoiceMonth;

with ItemsCTE as
(
	select distinct month(i.InvoiceDate) InvoiceMonth, il.StockItemID,
	sum(il.Quantity) over (partition by il.StockItemID, month(i.InvoiceDate)) as Quantity 
	from Sales.Invoices i 
	join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
	where i.InvoiceDate between '20160101' and '20161231'
),
MaxQuantityCTE as
(
	select i.InvoiceMonth, i.StockItemID, i.Quantity,
	row_number() over (partition by i.InvoiceMonth order by Quantity desc) as RN 
	from ItemsCTE i
)
select mq.InvoiceMonth, mq.StockItemID, mq.Quantity
from MaxQuantityCTE mq
where mq.RN <= 2
order by mq.InvoiceMonth, mq.StockItemID, mq.Quantity desc;

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select si.StockItemID, si.StockItemName, si.Brand, si.UnitPrice,
row_number() over (partition by left(si.StockItemName, 1) order by si.StockItemName) as NameRN,
count(si.StockItemID) over() as AllItemsCount,
count(si.StockItemID) over (partition by left(si.StockItemName, 1)) as ItemsCount,
lead(si.StockItemID) over (order by si.StockItemName) as LeadSI,
lag(si.StockItemID) over (order by si.StockItemName) as LagSI,
lag(si.StockItemName, 2, 'No items') over (order by si.StockItemName) as LagSN_2,
ntile(30) over (order by si.TypicalWeightPerUnit) as WeightPerUnitGroups
from Warehouse.StockItems si;

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

select p.PersonID, p.FullName, c.CustomerID, c.CustomerName, o.OrderDate, o.OrderSum
from Application.People p
cross apply (select top 1 o.CustomerID, o.OrderDate, ol.Quantity * ol.UnitPrice as OrderSum
			from Sales.Orders o
			join Sales.OrderLines ol on ol.OrderID = o.OrderID
			where o.SalespersonPersonID = p.PersonID
			order by o.OrderDate desc, o.OrderID desc) as o
join Sales.Customers c on c.CustomerID = o.CustomerID
order by p.PersonID;

with OrdersCTE as
(
	select o.SalespersonPersonID, o.CustomerID, o.OrderDate, ol.Quantity * ol.UnitPrice as OrderSum,
	row_number() over (partition by o.SalespersonPersonID order by o.OrderDate desc, o.OrderID desc) as RN
	from Sales.Orders o
	join Sales.OrderLines ol on ol.OrderID = o.OrderID
)
select o.SalespersonPersonID, p.FullName, o.CustomerID, c.CustomerName, o.OrderDate, o.OrderSum
from OrdersCTE o
join Sales.Customers c on c.CustomerID = o.CustomerID
join Application.People p on p.PersonID = o.SalespersonPersonID
where o.RN = 1;

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select c.CustomerID, c.CustomerName, cp.StockItemID, cp.UnitPrice, cp.InvoiceDate
from Sales.Customers c
cross apply (select top 2 il.StockItemID, il.UnitPrice, i.InvoiceDate
		from Sales.Invoices i
		join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
		where i.CustomerID = c.CustomerID
		order by il.UnitPrice desc) as cp
order by c.CustomerID, cp.UnitPrice desc, cp.InvoiceDate;

with DataCTE as
(
	select i.CustomerID, il.StockItemID, il.UnitPrice, i.InvoiceDate,
	row_number() over (partition by i.CustomerID order by il.UnitPrice desc) as RN
	from Sales.Invoices i
	join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
)
select d.CustomerID, c.CustomerName, d.StockItemID, d.UnitPrice, d.InvoiceDate
from Sales.Customers c 
join DataCTE d on d.CustomerID = c.CustomerID
where d.RN <= 2
order by d.CustomerID, d.UnitPrice desc, d.InvoiceDate;

-- Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 