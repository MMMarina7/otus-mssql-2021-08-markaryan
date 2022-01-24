SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE dbo.spConfirmOrder
AS
BEGIN
	SET NOCOUNT ON;

    -- Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRANSACTION; 

		RECEIVE TOP(1) @InitiatorReplyDlgHandle = Conversation_Handle, @ReplyReceivedMessage = Message_Body
		FROM dbo.InitiatorQueueIM; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; 

	COMMIT TRANSACTION; 

END
GO
