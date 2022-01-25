/*
Создаем CLR 

Цель:
В этом ДЗ вы научитесь создавать CLR.

Варианты ДЗ (сделать любой один):

Взять готовую dll, подключить ее и продемонстрировать использование. 
Например, https://sqlsharp.com

Взять готовые исходники из какой-нибудь статьи, скомпилировать, подключить dll, продемонстрировать использование.
Например, 
https://www.sqlservercentral.com/articles/xlsexport-a-clr-procedure-to-export-proc-results-to-excel

https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/

https://habr.com/ru/post/88396/

Написать полностью свое (что-то одно):
Тип: JSON с валидацией, IP / MAC - адреса, ...
Функция: работа с JSON, ...
Агрегат: аналог STRING_AGG, ...
(любой ваш вариант)
*/

USE WideWorldImporters;
GO

/*
-- Включаем CLR
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;		-- Глобальное включение
EXEC sp_configure 'clr strict security', 0 
GO

-- clr strict security 
-- 1 (Enabled): заставляет Database Engine игнорировать сведения PERMISSION_SET о сборках 
-- и всегда интерпретировать их как UNSAFE. По умолчанию, начиная с SQL Server 2017.

RECONFIGURE;
GO

-- Для возможности создания сборок с EXTERNAL_ACCESS или UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 
*/

-- Подключение dll 
CREATE ASSEMBLY UseCLRAssembly
FROM 'C:\1\SimpleDemo.dll'			-- Изменить путь
WITH PERMISSION_SET = SAFE;  

-- DROP ASSEMBLY UseCLRAssembly

-- Файл сборки (dll) на диске больше не нужен, она копируется в БД

-- Как посмотреть зарегистрированные сборки 

-- SSMS
-- <DB> -> Programmability -> Assemblies 

-- Посмотреть подключенные сборки (SSMS: <DB> -> Programmability -> Assemblies)
SELECT * FROM sys.assemblies;
GO

-- Подключить функцию из dll - AS EXTERNAL NAME
CREATE FUNCTION dbo.fn_ChangeCase(@Sting NVARCHAR(100), @value nchar(1))  
RETURNS NVARCHAR(100)
AS EXTERNAL NAME [UseCLRAssembly].[ExampleNamespace.DemoClass].ChangeCase;
GO 

-- Без namespace будет так:
-- [SimpleDemoAssembly].[DemoClass].ChangeCase

-- Использование функции
SELECT dbo.fn_ChangeCase(N'Изменение регистра', N'l') AS ToLower;	-- l - lower
SELECT dbo.fn_ChangeCase(N'Изменение регистра', N'u') AS ToUpper;	-- u - upper
SELECT dbo.fn_ChangeCase(N'Изменение регистра', N'n') AS CurString;	-- неизвестно - без изменений

-----------------------------

-- Список подключенных CLR-объектов
SELECT * FROM sys.assembly_modules

-- Посмотреть "код" сборки
-- SSMS: <DB> -> Programmability -> Assemblies -> Script Assembly as -> CREATE To

