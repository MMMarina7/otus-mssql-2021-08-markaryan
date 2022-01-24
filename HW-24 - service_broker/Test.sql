USE IM;
GO

DECLARE @ID_Order INT
SELECT TOP 1 @ID_Order = ID_Order
FROM Orders AS o
WHERE o.ProcessDate IS NULL

SELECT @ID_Order ID_Order

-- Запуск очереди вручную
-- Send message
EXEC dbo.spSendOrder @ID_Order = @ID_Order;

SELECT CAST(message_body AS XML), *
FROM [dbo].[TargetQueueIM];

SELECT CAST(message_body AS XML), *
FROM dbo.InitiatorQueueIM;

-- Target
EXEC dbo.spGetOrder;

-- Initiator
EXEC dbo.spConfirmOrder;

SELECT * FROM Orders

SELECT conversation_handle, is_initiator, s.name AS 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints AS ce
LEFT JOIN sys.services AS s ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts AS sc ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;