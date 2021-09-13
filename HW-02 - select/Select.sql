/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select si.StockItemID, si.StockItemName
from Warehouse.StockItems si
where si.StockItemName like '%urgent%' or si.StockItemName like 'Animal%' 

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select s.SupplierID, s.SupplierName
from Purchasing.Suppliers s
left join Purchasing.PurchaseOrders po on po.SupplierID = s.SupplierID
where po.PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

set language russian

select distinct o.OrderID, convert(nvarchar(10), o.OrderDate, 104) as OrderDate,
datename(month, o.OrderDate) as MonthOrderDate, datename(quarter, o.OrderDate) as QuarterOrderDate,
case when datepart(month, o.OrderDate) between 1 and 4 then 1
	when datepart(month, o.OrderDate) between 5 and 8 then 2
	when datepart(month, o.OrderDate) between 9 and 12 then 3
	end as ThirdOrderDate,
c.CustomerName
from Sales.Orders o 
join Sales.OrderLines ol on ol.OrderID = o.OrderID 
join Sales.Customers c on c.CustomerID = o.CustomerID
where ol.UnitPrice > 100 or (ol.Quantity > 20 and ol.PickingCompletedWhen is not null)
order by QuarterOrderDate, ThirdOrderDate, OrderDate
-- offset 1000 row fetch first 100 rows only	-- Постраничная выборка

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select /*distinct*/ dm.DeliveryMethodName, po.ExpectedDeliveryDate, s.SupplierName, p.FullName
from Purchasing.PurchaseOrders po 
join Application.DeliveryMethods dm on dm.DeliveryMethodID = po.DeliveryMethodID
join Purchasing.Suppliers s on s.SupplierID = po.SupplierID
join Application.People p on p.PersonID = po.ContactPersonID
where po.ExpectedDeliveryDate between '20130101' and '20130131'
and dm.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
and po.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10 i.OrderID, c.CustomerName, p.FullName
from Sales.Invoices i	-- Продажи?
join Sales.Customers c on c.CustomerID = i.CustomerID
join Application.People p on p.PersonID = i.SalespersonPersonID
order by i.InvoiceDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select /*distinct*/ c.CustomerID, c.CustomerName, c.PhoneNumber
from Sales.Customers c
join Sales.Orders o on o.CustomerID = c.CustomerID
join Sales.OrderLines ol on ol.OrderID = o.OrderID
join Warehouse.StockItems si on si.StockItemID = ol.StockItemID
where si.StockItemName = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(i.InvoiceDate) as InvoiceYear, month(i.InvoiceDate) as InvoiceMonth, 
avg(il.UnitPrice) as AvgPrice, sum(il.ExtendedPrice) as SumInv
from Sales.Invoices i
join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate)
order by InvoiceYear, InvoiceMonth

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(i.InvoiceDate) as InvoiceYear, month(i.InvoiceDate) as InvoiceMonth, 
sum(il.ExtendedPrice) as SumInv
from Sales.Invoices i
join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate)
having sum(il.ExtendedPrice) > 10000
order by InvoiceYear, InvoiceMonth

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(i.InvoiceDate) as InvoiceYear, month(i.InvoiceDate) as InvoiceMonth, 
si.StockItemName, sum(il.ExtendedPrice) as SumInv, min(i.InvoiceDate) as FirstInvoiceDate, 
sum(il.Quantity) as Quantity
from Sales.Invoices i
join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
join Warehouse.StockItems si on si.StockItemID = il.StockItemID
group by year(i.InvoiceDate), month(i.InvoiceDate), si.StockItemName
having sum(il.Quantity) < 50
order by InvoiceYear, InvoiceMonth, si.StockItemName

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

-- 8
select t.y as InvoiceYear, t.m as InvoiceMonth, sum(il.ExtendedPrice) as SumInv
from (values ('2013', '1'), ('2021', '1')) as t (y, m) 
left join Sales.Invoices i on year(i.InvoiceDate) = t.y and month(i.InvoiceDate) = t.m
left join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
group by t.y, t.m
order by InvoiceYear, InvoiceMonth

-- 9
select t.y as InvoiceYear, t.m as InvoiceMonth, si.StockItemName, 
sum(il.ExtendedPrice) as SumInv, min(i.InvoiceDate) as FirstInvoiceDate, 
sum(il.Quantity) as Quantity
from (values ('2013', '1'), ('2021', '1')) as t (y, m) 
left join Sales.Invoices i on year(i.InvoiceDate) = t.y and month(i.InvoiceDate) = t.m
left join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
left join Warehouse.StockItems si on si.StockItemID = il.StockItemID
group by t.y, t.m, si.StockItemName
order by InvoiceYear, InvoiceMonth, si.StockItemName