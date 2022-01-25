/*
������� CLR 

����:
� ���� �� �� ��������� ��������� CLR.

�������� �� (������� ����� ����):

����� ������� dll, ���������� �� � ������������������ �������������. 
��������, https://sqlsharp.com

����� ������� ��������� �� �����-������ ������, ��������������, ���������� dll, ������������������ �������������.
��������, 
https://www.sqlservercentral.com/articles/xlsexport-a-clr-procedure-to-export-proc-results-to-excel

https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/

https://habr.com/ru/post/88396/

�������� ��������� ���� (���-�� ����):
���: JSON � ����������, IP / MAC - ������, ...
�������: ������ � JSON, ...
�������: ������ STRING_AGG, ...
(����� ��� �������)
*/

USE WideWorldImporters;
GO

/*
-- �������� CLR
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;		-- ���������� ���������
EXEC sp_configure 'clr strict security', 0 
GO

-- clr strict security 
-- 1 (Enabled): ���������� Database Engine ������������ �������� PERMISSION_SET � ������� 
-- � ������ ���������������� �� ��� UNSAFE. �� ���������, ������� � SQL Server 2017.

RECONFIGURE;
GO

-- ��� ����������� �������� ������ � EXTERNAL_ACCESS ��� UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 
*/

-- ����������� dll 
CREATE ASSEMBLY UseCLRAssembly
FROM 'C:\1\SimpleDemo.dll'			-- �������� ����
WITH PERMISSION_SET = SAFE;  

-- DROP ASSEMBLY UseCLRAssembly

-- ���� ������ (dll) �� ����� ������ �� �����, ��� ���������� � ��

-- ��� ���������� ������������������ ������ 

-- SSMS
-- <DB> -> Programmability -> Assemblies 

-- ���������� ������������ ������ (SSMS: <DB> -> Programmability -> Assemblies)
SELECT * FROM sys.assemblies;
GO

-- ���������� ������� �� dll - AS EXTERNAL NAME
CREATE FUNCTION dbo.fn_ChangeCase(@Sting NVARCHAR(100), @value nchar(1))  
RETURNS NVARCHAR(100)
AS EXTERNAL NAME [UseCLRAssembly].[ExampleNamespace.DemoClass].ChangeCase;
GO 

-- ��� namespace ����� ���:
-- [SimpleDemoAssembly].[DemoClass].ChangeCase

-- ������������� �������
SELECT dbo.fn_ChangeCase(N'��������� ��������', N'l') AS ToLower;	-- l - lower
SELECT dbo.fn_ChangeCase(N'��������� ��������', N'u') AS ToUpper;	-- u - upper
SELECT dbo.fn_ChangeCase(N'��������� ��������', N'n') AS CurString;	-- ���������� - ��� ���������

-----------------------------

-- ������ ������������ CLR-��������
SELECT * FROM sys.assembly_modules

-- ���������� "���" ������
-- SSMS: <DB> -> Programmability -> Assemblies -> Script Assembly as -> CREATE To

