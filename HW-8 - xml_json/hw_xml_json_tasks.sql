/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/

/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/

DECLARE @XML XML
DECLARE @DynSQL NVARCHAR(200)
DECLARE @Path NVARCHAR(200) = 'C:\1\StockItems-188-11a700.xml'	-- Заменить путь 

DECLARE @StockItems TABLE ([StockItemName] [nvarchar](100), [SupplierID] [int], [UnitPackageID] [int],
						[OuterPackageID] [int], [QuantityPerOuter] [int], [TypicalWeightPerUnit] [decimal](18, 3),
						[LeadTimeDays] [int], [IsChillerStock] [bit], [TaxRate] [decimal](18, 3), [UnitPrice] [decimal](18, 2))

SELECT @DynSQL = 'SET @XML = (SELECT BulkColumn
FROM OPENROWSET(BULK ''' + @Path + ''', SINGLE_CLOB) AS Data)'

-- SELECT @DynSQL AS [DynSQL]
EXEC sp_executesql @DynSQL, N'@XML XML OUT', @XML = @XML OUT

-- Проверяем, что в @XML
-- SELECT @XML AS [XML]

INSERT INTO @StockItems ([StockItemName], [SupplierID], [UnitPackageID], [OuterPackageID], [QuantityPerOuter], 
					[TypicalWeightPerUnit], [LeadTimeDays], [IsChillerStock], [TaxRate], [UnitPrice])
	
SELECT StockItemName = x.t.value('@Name[1]', 'nvarchar(100)'),
	SupplierID = x.t.value('SupplierID[1]', 'int'),
	UnitPackageID = x.t.value('Package[1]/UnitPackageID[1]', 'int'),
	OuterPackageID = x.t.value('Package[1]/OuterPackageID[1]', 'int'),
	QuantityPerOuter = x.t.value('Package[1]/QuantityPerOuter[1]', 'int'),
	TypicalWeightPerUnit = x.t.value('Package[1]/TypicalWeightPerUnit[1]', 'decimal(18, 3)'),
	LeadTimeDays = x.t.value('LeadTimeDays[1]', 'int'),
	IsChillerStock = x.t.value('IsChillerStock[1]', 'bit'),
	TaxRate = x.t.value('TaxRate[1]', 'decimal(18, 3)'),
	UnitPrice = x.t.value('UnitPrice[1]', 'decimal(18, 3)')
FROM @XML.nodes('/StockItems/Item') AS x(t) 

SELECT * FROM @StockItems

-- Опциональная часть
SELECT wsi.[StockItemName], wsi.[SupplierID], wsi.[UnitPackageID], wsi.[OuterPackageID], wsi.[QuantityPerOuter], 
wsi.[TypicalWeightPerUnit], wsi.[LeadTimeDays], wsi.[IsChillerStock], wsi.[TaxRate], wsi.[UnitPrice]
--UPDATE wsi SET [StockItemName] = si.[StockItemName], [SupplierID] = si.[SupplierID], 
--			[UnitPackageID] = si.[UnitPackageID], [OuterPackageID] = si.[OuterPackageID], 
--			[QuantityPerOuter] = si.[QuantityPerOuter], [TypicalWeightPerUnit] = si.[TypicalWeightPerUnit], 
--			[LeadTimeDays] = si.[LeadTimeDays], [IsChillerStock] = si.[IsChillerStock], 
--			[TaxRate] = si.[TaxRate], [UnitPrice] = si.[UnitPrice]
FROM @StockItems AS si 
JOIN Warehouse.StockItems AS wsi ON wsi.StockItemName = si.StockItemName

--INSERT INTO Warehouse.StockItems ([StockItemName], [SupplierID], [UnitPackageID], [OuterPackageID], [QuantityPerOuter], 
--								[TypicalWeightPerUnit], [LeadTimeDays], [IsChillerStock], [TaxRate], [UnitPrice])
SELECT si.[StockItemName], si.[SupplierID], si.[UnitPackageID], si.[OuterPackageID], si.[QuantityPerOuter], 
si.[TypicalWeightPerUnit], si.[LeadTimeDays], si.[IsChillerStock], si.[TaxRate], si.[UnitPrice]
FROM @StockItems AS si 
LEFT JOIN Warehouse.StockItems AS wsi ON wsi.StockItemName = si.StockItemName
WHERE wsi.StockItemID IS NULL

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/
DECLARE @XML_ XML
SET @XML_ = (SELECT TOP 10 
			wsi.[StockItemName] AS [@Name], 
			wsi.[SupplierID], 
			wsi.[UnitPackageID] AS [Package/UnitPackageID], 
			wsi.[OuterPackageID] AS [Package/OuterPackageID], 
			wsi.[QuantityPerOuter] AS [Package/QuantityPerOuter], 
			wsi.[TypicalWeightPerUnit] AS [Package/TypicalWeightPerUnit], 
			wsi.[LeadTimeDays], 
			wsi.[IsChillerStock], 
			wsi.[TaxRate], 
			wsi.[UnitPrice]
			FROM Warehouse.StockItems AS wsi 
			FOR XML PATH('Item'), ROOT('StockItems'))

SELECT @XML_ AS [XML_]

-- Экспорт в файл
-- Путь заменить
DECLARE @ServerName NVARCHAR(50) = @@servername,
		@DynSql_ NVARCHAR(2000)

SELECT @DynSql_ = 'bcp "SELECT [StockItemName] AS [@Name], [SupplierID], [UnitPackageID] AS [Package/UnitPackageID],'
				+ '[OuterPackageID] AS [Package/OuterPackageID], [QuantityPerOuter] AS [Package/QuantityPerOuter],' 
				+ '[TypicalWeightPerUnit] AS [Package/TypicalWeightPerUnit], [LeadTimeDays], [IsChillerStock], [TaxRate], [UnitPrice]'
				+ 'FROM WideWorldImporters.Warehouse.StockItems FOR XML PATH(''Item''), ROOT(''StockItems'')" queryout C:\1\StockItemsXML.xml -w -T -S' + @ServerName
EXEC xp_cmdshell @DynSql_

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT si.StockItemID, si.StockItemName, 
JSON_VALUE(si.CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
JSON_VALUE(si.CustomFields, '$.Tags[0]') AS FirstTag 
FROM Warehouse.StockItems AS si

-- Дополнительный вариант
/*
SELECT si.StockItemID, si.StockItemName, j.CountryOfManufacture, a.Tag
FROM Warehouse.StockItems AS si
OUTER APPLY OPENJSON (si.CustomFields)
  WITH (
    CountryOfManufacture VARCHAR(200) N'$.CountryOfManufacture',
	Tagss NVARCHAR(MAX) N'$.Tags' AS JSON
  ) AS j
OUTER APPLY (SELECT TOP 1 tj.Tag FROM OPENJSON (Tagss)
  WITH (Tag NVARCHAR(200) N'$') AS tj) AS a
*/

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

-- В опциональной части не совсем поняла, какие теги имелись в виду (столбец cf или t)
SELECT si.StockItemID, si.StockItemName
,STRING_AGG(cf.[key], ', ') AS cf		-- Теги эти?
-- ,STRING_AGG(t.[value], ', ') AS t			
FROM Warehouse.StockItems AS si
CROSS APPLY OPENJSON (si.CustomFields, '$.Tags') AS Tags
CROSS APPLY OPENJSON (si.CustomFields) AS cf
-- CROSS APPLY OPENJSON (si.CustomFields, '$.Tags') AS t
WHERE Tags.value = 'Vintage'
GROUP BY si.StockItemID, si.StockItemName


--select si.CustomFields, si.Tags, * 
--from Warehouse.StockItems as si
--where si.CustomFields like '%Vintage%'

