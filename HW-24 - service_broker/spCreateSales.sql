USE [IM]
GO
/****** Object:  StoredProcedure [dbo].[spCreateSales]    Script Date: 24.01.2022 23:38:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Создание продажи по заказу>
-- =============================================
CREATE PROCEDURE [dbo].[spCreateSales]
	@ID_Order INT
AS
BEGIN
	SET NOCOUNT ON;

    -- Расписать логику создание накладной

	-- Проставить время обработки
	UPDATE o SET o.ProcessDate = GETDATE()
	FROM dbo.Orders AS o WITH (NOLOCK)
	WHERE o.ID_Order = @ID_Order

END
