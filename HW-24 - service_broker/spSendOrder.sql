USE [IM]
GO
/****** Object:  StoredProcedure [dbo].[spSendOrder]    Script Date: 24.01.2022 23:39:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Отправка>
-- =============================================
ALTER PROCEDURE [dbo].[spSendOrder]
	@ID_Order INT
AS
BEGIN
	SET NOCOUNT ON;

    -- Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRANSACTION; 

	-- Prepare the Message
	SELECT @RequestMessage = (SELECT ID_Order
							  FROM Orders AS Ord
							  WHERE ID_Order = @ID_Order
							  FOR XML AUTO, root('RequestMessage')); 
	
	-- Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE [//IM/SB/InitiatorService]
	TO SERVICE '//IM/SB/TargetService'
	ON CONTRACT [//IM/SB/Contract]
	WITH ENCRYPTION = OFF; 

	-- Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE [//IM/SB/RequestMessage]
	(@RequestMessage);

	SELECT @RequestMessage AS SentRequestMessage;

	COMMIT TRANSACTION; 
END
