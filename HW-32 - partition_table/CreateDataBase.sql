USE master;
GO
CREATE DATABASE IM
ON
( 
	NAME = IM_dat,
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\IM.mdf',
    SIZE = 10,
    MAXSIZE = 50,
    FILEGROWTH = 5 
)
LOG ON
( 
	NAME = IM_log,
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\IM.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB 
);
GO