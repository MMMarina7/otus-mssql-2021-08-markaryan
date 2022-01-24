-- Какие индексы вам нужны
   
-- Цель:
-- В этом ДЗ вы поработаете с индексами.
   
-- Думаем какие запросы у вас будут в базе и добавляем для них индексы. Проверяем, что они используются в запросе. 

-- Поиск количества заказов по имени покутеля

DROP INDEX IF EXISTS IX_CustomerName ON IM.dbo.Customers;
GO
CREATE INDEX IX_CustomerName ON IM.dbo.Customers (LastName, FirstName);
GO
/*
SELECT c.LastName, COUNT(o.ID_Order) AS Orders
FROM Customers AS c
LEFT JOIN Orders AS o ON o.ID_Customer = c.ID_Customer
WHERE c.FirstName = 'Антон' AND c.LastName = 'Антонов'		-- Порядок неважен
GROUP BY c.LastName;
GO
*/
-- Поиск покуателя по дате заказа
-- Индекс с INCLUDE
DROP INDEX IF EXISTS IX_Orders_OrderDate ON IM.dbo.Orders;
GO
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate ON IM.dbo.Orders (OrderDate ASC) 
INCLUDE(ID_Customer);
GO
/*
SELECT o.ID_Customer
FROM Orders As o
WHERE o.OrderDate BETWEEN '20211201' AND '20211221'
*/