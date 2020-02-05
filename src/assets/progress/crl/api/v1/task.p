USING Progress.Lang.Error.
USING com.totvs.framework.api.JsonApiResponseBuilder.

{utp/ut-api.i}
{utp/ut-api-utils.i}

{utp/ut-api-action.i pi-query-diff GET /diff~*}
{utp/ut-api-action.i pi-query      GET /~*}

{utp/ut-api-action.i pi-create POST /~*}
{utp/ut-api-action.i pi-update PUT /~*}
{utp/ut-api-action.i pi-upatch PATCH /~*}
{utp/ut-api-action.i pi-delete DELETE /~*}

{utp/ut-api-notfound.i}
{utils/GetNowReturnIsoDate.i}
{utils/ParseJsonResponseAddTotvsSyncDate.i}

DEFINE VARIABLE apiHandler AS HANDLE NO-UNDO.

/*:T--- PROCEDURES V1 ---*/

PROCEDURE pi-query-diff:
    
    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE lHasNext AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE aResult  AS JsonArray NO-UNDO.
    DEFINE VARIABLE cNow     AS CHARACTER NO-UNDO.

    ASSIGN cNow = GetNowReturnIsoDate().

    IF NOT VALID-HANDLE(apiHandler) THEN DO:
        RUN crl/apiTask.p PERSISTENT SET apiHandler.
    END.

	RUN pi-query-diff-v1 IN apiHandler  (
        INPUT oInput,
        OUTPUT aResult,
        OUTPUT lHasNext,
        OUTPUT TABLE RowErrors
    ).

 	IF CAN-FIND(FIRST RowErrors WHERE UPPER(RowErrors.ErrorSubType) = 'ERROR':U) THEN DO:
        IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorType <> 'ERROR':U) THEN
            ASSIGN oOutput = JsonApiResponseBuilder:asError(TEMP-TABLE RowErrors:HANDLE).
        ELSE
            ASSIGN oOutput = JsonApiResponseBuilder:asError(
			                 JsonAPIUtils:convertTempTableToJsonArray(TEMP-TABLE RowErrors:HANDLE), 400).
    END.
    ELSE DO:
        ASSIGN oOutput = JsonApiResponseBuilder:ok(aResult, lHasNext)
               oOutput = ParseJsonResponseAddTotvsSyncDate(INPUT oOutput, INPUT cNow).
    END.
    
    CATCH oE AS ERROR:
        ASSIGN oOutput = JsonApiResponseBuilder:asError(oE).
    END CATCH.
    
    FINALLY: DELETE PROCEDURE apiHandler NO-ERROR. END FINALLY.

END PROCEDURE.

PROCEDURE pi-query:
    
    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE lHasNext AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE aResult  AS JsonArray NO-UNDO.
    DEFINE VARIABLE cNow     AS CHARACTER NO-UNDO.

    ASSIGN cNow = GetNowReturnIsoDate().

    IF NOT VALID-HANDLE(apiHandler) THEN DO:
        RUN crl/apiTask.p PERSISTENT SET apiHandler.
    END.

	RUN pi-query-v1 IN apiHandler  (
        INPUT oInput,
        OUTPUT aResult,
        OUTPUT lHasNext,
        OUTPUT TABLE RowErrors
    ).

 	IF CAN-FIND(FIRST RowErrors WHERE UPPER(RowErrors.ErrorSubType) = 'ERROR':U) THEN DO:
        IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorType <> 'ERROR':U) THEN
            ASSIGN oOutput = JsonApiResponseBuilder:asError(TEMP-TABLE RowErrors:HANDLE).
        ELSE
            ASSIGN oOutput = JsonApiResponseBuilder:asError(
			                 JsonAPIUtils:convertTempTableToJsonArray(TEMP-TABLE RowErrors:HANDLE), 400).
    END.
    ELSE DO:
        ASSIGN oOutput = JsonApiResponseBuilder:ok(aResult, lHasNext)
               oOutput = ParseJsonResponseAddTotvsSyncDate(INPUT oOutput, INPUT cNow).
    END.
    
    CATCH oE AS ERROR:
        ASSIGN oOutput = JsonApiResponseBuilder:asError(oE).
    END CATCH.
    
    FINALLY: DELETE PROCEDURE apiHandler NO-ERROR. END FINALLY.

END PROCEDURE.

PROCEDURE pi-create:

    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.

    IF NOT VALID-HANDLE(apiHandler) THEN DO:
        RUN crl/apiTask.p PERSISTENT SET apiHandler.
    END.

    RUN pi-create-v1 IN apiHandler (
        INPUT oInput,
        OUTPUT oOutput,
        OUTPUT TABLE RowErrors
    ).

	IF CAN-FIND(FIRST RowErrors WHERE UPPER(RowErrors.ErrorSubType) = 'ERROR':U) THEN DO:
        IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorType <> 'ERROR':U) THEN
            ASSIGN oOutput = JsonApiResponseBuilder:asError(TEMP-TABLE RowErrors:HANDLE).
        ELSE
            ASSIGN oOutput = JsonApiResponseBuilder:asError(
			                 JsonAPIUtils:convertTempTableToJsonArray(TEMP-TABLE RowErrors:HANDLE), 400).
    END.
    ELSE DO:
        ASSIGN oOutput = JsonApiResponseBuilder:ok(oOutput, 201).
    END.

    CATCH oE AS Error:
        ASSIGN oOutput = JsonApiResponseBuilder:asError(oE).
    END CATCH.
    
    FINALLY: DELETE PROCEDURE apiHandler NO-ERROR. END FINALLY.

END PROCEDURE.

PROCEDURE pi-update:

    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.

    IF NOT VALID-HANDLE(apiHandler) THEN DO:
        RUN crl/apiTask.p PERSISTENT SET apiHandler.
    END.

    RUN pi-update-v1 IN apiHandler (
        INPUT oInput,
        OUTPUT oOutput,
        OUTPUT TABLE RowErrors
    ).

	IF CAN-FIND(FIRST RowErrors WHERE UPPER(RowErrors.ErrorSubType) = 'ERROR':U) THEN DO:
        IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorType <> 'ERROR':U) THEN
            ASSIGN oOutput = JsonApiResponseBuilder:asError(TEMP-TABLE RowErrors:HANDLE).
        ELSE
            ASSIGN oOutput = JsonApiResponseBuilder:asError(
			                 JsonAPIUtils:convertTempTableToJsonArray(TEMP-TABLE RowErrors:HANDLE), 400).
    END.
    ELSE IF oOutput EQ ? THEN DO:
        ASSIGN oOutput = JsonApiResponseBuilder:empty(404).
    END.
    ELSE DO:
        ASSIGN oOutput = JsonApiResponseBuilder:ok(oOutput).
    END.

    CATCH oE AS Error:
        ASSIGN oOutput = JsonApiResponseBuilder:asError(oE).
    END CATCH.
    
    FINALLY: DELETE PROCEDURE apiHandler NO-ERROR. END FINALLY.

END PROCEDURE.

PROCEDURE pi-upatch:
    
    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.

    IF NOT VALID-HANDLE(apiHandler) THEN DO:
        RUN crl/apiTask.p PERSISTENT SET apiHandler.
    END.

    RUN pi-upatch-v1 IN apiHandler (
        INPUT oInput,
        OUTPUT oOutput,
        OUTPUT TABLE RowErrors
    ).

    IF CAN-FIND(FIRST RowErrors WHERE UPPER(RowErrors.ErrorSubType) = 'ERROR':U) THEN DO:
        IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorType <> 'ERROR':U) THEN
            ASSIGN oOutput = JsonApiResponseBuilder:asError(TEMP-TABLE RowErrors:HANDLE).
        ELSE
            ASSIGN oOutput = JsonApiResponseBuilder:asError(
			                 JsonAPIUtils:convertTempTableToJsonArray(TEMP-TABLE RowErrors:HANDLE), 400).
    END.
    ELSE IF oOutput EQ ? THEN DO:
        ASSIGN oOutput = JsonApiResponseBuilder:empty(404).
    END.
    ELSE DO:
        ASSIGN oOutput = JsonApiResponseBuilder:ok(oOutput).
    END.

    CATCH oE AS Error:
        ASSIGN oOutput = JsonApiResponseBuilder:asError(oE).
    END CATCH.
    
    FINALLY: DELETE PROCEDURE apiHandler NO-ERROR. END FINALLY.

END PROCEDURE.

PROCEDURE pi-delete:
    
    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.
   
    IF NOT VALID-HANDLE(apiHandler) THEN DO:
        RUN crl/apiTask.p PERSISTENT SET apiHandler.
    END.

    RUN pi-delete-v1 IN apiHandler (
        INPUT oInput,
        OUTPUT TABLE RowErrors
    ).

    IF CAN-FIND(FIRST RowErrors WHERE UPPER(RowErrors.ErrorSubType) = 'ERROR':U) THEN DO:
        IF CAN-FIND(FIRST RowErrors WHERE RowErrors.ErrorType <> 'ERROR':U) THEN
            ASSIGN oOutput = JsonApiResponseBuilder:asError(TEMP-TABLE RowErrors:HANDLE).
        ELSE
            ASSIGN oOutput = JsonApiResponseBuilder:asError(
			                 JsonAPIUtils:convertTempTableToJsonArray(TEMP-TABLE RowErrors:HANDLE), 400).
    END.
    ELSE DO:
        ASSIGN oOutput = JsonApiResponseBuilder:empty().
    END.

    CATCH oE AS Error:
        ASSIGN oOutput = JsonApiResponseBuilder:asError(oE).
    END CATCH.
    
    FINALLY: DELETE PROCEDURE apiHandler NO-ERROR. END FINALLY.

END PROCEDURE.
