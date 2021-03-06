USE [IM]
GO
/****** Object:  StoredProcedure [dbo].[spGetOrder]    Script Date: 24.01.2022 23:39:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description>
-- =============================================
CREATE PROCEDURE [dbo].[spGetOrder]
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@ID_Order INT,
			@Xml XML; 
	
	BEGIN TRANSACTION; 

		-- Receive message from Initiator
		RECEIVE TOP(1) @TargetDlgHandle = Conversation_Handle, @Message = Message_Body, @MessageType = Message_Type_Name
		FROM dbo.TargetQueueIM; 

		SELECT @Message;

		SET @Xml = CAST(@Message AS XML);

		SELECT @ID_Order = R.Ord.value('@ID_Order', 'INT')
		FROM @Xml.nodes('/RequestMessage/Ord') AS R(Ord);

		-- Вызов процедуры создания продажи
		EXEC spCreateSales @ID_Order = @ID_Order
			
		SELECT @Message AS ReceivedRequestMessage, @MessageType; 
	
		-- Confirm and Send a reply
		IF @MessageType = N'//IM/SB/RequestMessage'
		BEGIN
			SET @ReplyMessage = N'<ReplyMessage>Message received</ReplyMessage>'; 
	
			SEND ON CONVERSATION @TargetDlgHandle
			MESSAGE TYPE [//IM/SB/ReplyMessage]
			(@ReplyMessage);
			END CONVERSATION @TargetDlgHandle;
		END 
	
		SELECT @ReplyMessage AS SentReplyMessage; 

	COMMIT TRANSACTION;
END
