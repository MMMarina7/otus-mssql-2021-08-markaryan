/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - DML и для чего он нужен;
операторы INSERT, UPDATE, DELETE, MERGE, Bulk insert;
утилита bcp in\out".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать запросы
-- ---------------------------------------------------------------------------

use WideWorldImporters
/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers
*/

if exists (select * from tempdb..sysobjects where id = object_id('tempdb..#InsRows'))
	drop table #InsRows
create table #InsRows (InsCustomerID int)

insert into Sales.Customers (CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
							DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays,
							PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
							DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
output inserted.CustomerID into #InsRows (InsCustomerID)
select top 5 concat(CustomerName, '111') as CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays,
PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy 
from Sales.Customers c
order by c.CustomerID

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

-- select *
delete c
from Sales.Customers c
where c.CustomerID = (select top 1 i.InsCustomerID from #InsRows i order by i.InsCustomerID)

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

-- select *
update c set c.CustomerName = 'Marina111'
from Sales.Customers c
join (select top 1 c.CustomerID
	from Sales.Customers c
	join #InsRows i on i.InsCustomerID = c.CustomerID
	order by i.InsCustomerID) ic on ic.CustomerID = c.CustomerID


-- select * from Sales.Customers c order by c.CustomerID desc

/*
4. Написать MERGE, который вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

declare @Customers table (Customer_id int, CustomerName nvarchar(100))
insert into @Customers (Customer_id, CustomerName)
select c.CustomerID, c.CustomerName
from Sales.Customers c
where c.CustomerName = 'Marina111'

select * from @Customers

merge @Customers as target
using (select c.CustomerID, CustomerName
	from Sales.Customers c
	where c.CustomerName in ('Marina111', 'Agrita Abele')) as source on source.CustomerID = target.Customer_id 
when matched then
	update set CustomerName = 'MarinaM'
when not matched then
	insert (Customer_id, CustomerName)
	values (source.CustomerID, source.CustomerName);

-- select * from Sales.Customers c

select * from @Customers

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

-- 5.1 bcp out
-- To allow advanced options to be changed.  
exec sp_configure 'show advanced options', 1;  
go  
-- To update the currently configured value for advanced options.  
reconfigure;
go

-- To enable the feature.  
exec sp_configure 'xp_cmdshell', 1;  
go  
-- To update the currently configured value for this feature.  
reconfigure;
go

declare @ServerName nvarchar(50) = @@servername,
		@DynSql nvarchar(200)

-- Другой разделитель 
select @DynSql = 'bcp "[WideWorldImporters].Application.Countries" out  "C:\1\Countries111.txt" -T -w -t"@eu&$1&" -S' + @ServerName
  
-- select @ServerName as ServerName, @DynSql as DynSql

-- select count(*) as CountriesRowCount from Application.Countries
   
exec master..xp_cmdshell @DynSql

-- select * from Application.Countries

-- 5.2 bulk insert
drop table if exists [Application].[Countries_test]

create table [Application].[Countries_test]
(
	[CountryID] [int] not null,
	[CountryName] [nvarchar](60) not null,
	[FormalName] [nvarchar](60) not null,
	[IsoAlpha3Code] [nvarchar](3) null,
	[IsoNumericCode] [int] null,
	[CountryType] [nvarchar](20) null,
	[LatestRecordedPopulation] [bigint] null,
	[Continent] [nvarchar](30) not null,
	[Region] [nvarchar](30) not null,
	[Subregion] [nvarchar](30) not null,
	[Border] [geography] null,
	[LastEditedBy] [int] not null,
	[ValidFrom] [datetime2](7) not null,
	[ValidTo] [datetime2](7) not null
)

-- select * from Application.Countries_test

bulk insert [WideWorldImporters].[Application].[Countries_test]
from "C:\1\Countries111.txt"
with (batchsize = 1000,
	  datafiletype = 'widechar',
	  fieldterminator = '@eu&$1&',
	  rowterminator ='\n',
	  keepnulls,
	  tablock);

select * from Application.Countries_test

-- select count(*) as Countries_testRowCount from Application.Countries_test

truncate table Application.Countries_test