-- Системные представления

SELECT * FROM sys.service_contract_message_usages; 
SELECT * FROM sys.service_contract_usages;
SELECT * FROM sys.service_queue_usages;
 
SELECT * FROM sys.transmission_queue;	-- Мониторить особенно когда общение между серверами
GO

USE master;
GO
-- ALTER DATABASE [IM] SET ENABLE_BROKER;		-- Компонент Service Broker включен по умолчанию и его нельзя отключить.

ALTER DATABASE [IM] SET TRUSTWORTHY ON;
GO
ALTER AUTHORIZATION ON DATABASE:: [IM] TO [sa];
GO
---------------------------------------------------------------------------------------
-- Создание типов сообщений
USE IM;
GO
-- For Request
CREATE MESSAGE TYPE [//IM/SB/RequestMessage]
VALIDATION = WELL_FORMED_XML;
GO

-- For Reply
CREATE MESSAGE TYPE [//IM/SB/ReplyMessage]
VALIDATION = WELL_FORMED_XML; 
GO

-- Создание контракта
CREATE CONTRACT [//IM/SB/Contract]
([//IM/SB/RequestMessage] SENT BY INITIATOR,
 [//IM/SB/ReplyMessage] SENT BY TARGET);
GO

-- Создание очередей
CREATE QUEUE TargetQueueIM;

CREATE SERVICE [//IM/SB/TargetService] ON QUEUE TargetQueueIM ([//IM/SB/Contract]);
GO

CREATE QUEUE InitiatorQueueIM;

CREATE SERVICE [//IM/SB/InitiatorService] ON QUEUE InitiatorQueueIM ([//IM/SB/Contract]);
GO

SELECT * 
FROM dbo.InitiatorQueueIM;

SELECT * 
FROM dbo.TargetQueueIM;

SELECT name, is_broker_enabled
FROM sys.databases;

SELECT conversation_handle, is_initiator, s.name AS 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints AS ce
LEFT JOIN sys.services AS s ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts AS sc ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;