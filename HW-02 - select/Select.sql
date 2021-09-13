/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, GROUP BY, HAVING".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

select si.StockItemID, si.StockItemName
from Warehouse.StockItems si
where si.StockItemName like '%urgent%' or si.StockItemName like 'Animal%' 

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

select s.SupplierID, s.SupplierName
from Purchasing.Suppliers s
left join Purchasing.PurchaseOrders po on po.SupplierID = s.SupplierID
where po.PurchaseOrderID is null

/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
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
-- offset 1000 row fetch first 100 rows only	-- ������������ �������

/*
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
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
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
*/

select top 10 i.OrderID, c.CustomerName, p.FullName
from Sales.Invoices i	-- �������?
join Sales.Customers c on c.CustomerID = i.CustomerID
join Application.People p on p.PersonID = i.SalespersonPersonID
order by i.InvoiceDate desc

/*
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
*/

select /*distinct*/ c.CustomerID, c.CustomerName, c.PhoneNumber
from Sales.Customers c
join Sales.Orders o on o.CustomerID = c.CustomerID
join Sales.OrderLines ol on ol.OrderID = o.OrderID
join Warehouse.StockItems si on si.StockItemID = ol.StockItemID
where si.StockItemName = 'Chocolate frogs 250g'

/*
7. ��������� ������� ���� ������, ����� ����� ������� �� �������
�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ������� ���� �� ����� �� ���� �������
* ����� ����� ������ �� �����

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

select year(i.InvoiceDate) as InvoiceYear, month(i.InvoiceDate) as InvoiceMonth, 
avg(il.UnitPrice) as AvgPrice, sum(il.ExtendedPrice) as SumInv
from Sales.Invoices i
join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate)
order by InvoiceYear, InvoiceMonth

/*
8. ���������� ��� ������, ��� ����� ����� ������ ��������� 10 000

�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ����� ����� ������

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

select year(i.InvoiceDate) as InvoiceYear, month(i.InvoiceDate) as InvoiceMonth, 
sum(il.ExtendedPrice) as SumInv
from Sales.Invoices i
join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate)
having sum(il.ExtendedPrice) > 10000
order by InvoiceYear, InvoiceMonth

/*
9. ������� ����� ������, ���� ������ �������
� ���������� ���������� �� �������, �� �������,
������� ������� ����� 50 �� � �����.
����������� ������ ���� �� ����,  ������, ������.

�������:
* ��� �������
* ����� �������
* ������������ ������
* ����� ������
* ���� ������ �������
* ���������� ����������

������� �������� � ������� Sales.Invoices � ��������� ��������.
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
-- �����������
-- ---------------------------------------------------------------------------
/*
�������� ������� 8-9 ���, ����� ���� � �����-�� ������ �� ���� ������,
�� ���� ����� ����� ����������� �� � �����������, �� ��� ���� ����.
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