/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2017 
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [IM]
GO
/****** Object:  ServiceQueue [InitiatorQueueIM] ******/
ALTER QUEUE [dbo].[InitiatorQueueIM] WITH STATUS = ON, RETENTION = OFF, POISON_MESSAGE_HANDLING (STATUS = OFF),
ACTIVATION (STATUS = ON, PROCEDURE_NAME = dbo.spConfirmOrder, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER);	-- Процедура активации
GO

ALTER QUEUE [dbo].[TargetQueueIM] WITH STATUS = ON, RETENTION = OFF, POISON_MESSAGE_HANDLING (STATUS = OFF), 
ACTIVATION (STATUS = ON, PROCEDURE_NAME = dbo.spGetOrder, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER); 
GO