BLOCK-LEVEL ON ERROR UNDO, THROW.

USING PROGRESS.json.*.
USING PROGRESS.json.ObjectModel.*.
USING com.totvs.framework.api.*.

{method/dbotterr.i}
{crmbo/boCrmTar.i TaskPersistent}
{cdp/utils.i}
{utils/ParseIsoDateToDatetimeTZ.i}

{crl/apiTaskV1.i Task}

DEFINE VARIABLE boHandler AS HANDLE NO-UNDO.

/*:T--- FUNCTIONS ---*/

FUNCTION fn-get-last-sync-from-path RETURNS DATETIME (
    INPUT oRequest AS JsonAPIRequestParser
):

    DEFINE VARIABLE cLastSyncFromPath AS CHARACTER          NO-UNDO.
    DEFINE VARIABLE dtmLastSync       AS DATETIME INITIAL ? NO-UNDO.

    ASSIGN cLastSyncFromPath = oRequest:getPathParams():GetCharacter(oRequest:getPathParams():LENGTH).

    MESSAGE ">>>>>>>>>>>>> cLastSyncFromPath " cLastSyncFromPath
        VIEW-AS ALERT-BOX INFO BUTTONS OK.

    /* se tem valor no lastSync do diff e se for diferente do ano default, undefined e null, entao considera o lastSync do path */
    IF LENGTH(cLastSyncFromPath) > 1 AND
       INDEX(cLastSyncFromPath, '-271821') < 1 AND
       INDEX(cLastSyncFromPath, 'undefined') < 1  AND 
       INDEX(cLastSyncFromPath, 'null') < 1 THEN DO:

        ASSIGN dtmLastSync = ParseIsoDateToDatetimeTZ(INPUT cLastSyncFromPath).        
    END.

    RETURN dtmLastSync.
END FUNCTION.

FUNCTION fn-get-id-from-path RETURNS CHARACTER (
    INPUT oRequest AS JsonAPIRequestParser
):
    RETURN oRequest:getPathParams():GetCharacter(1).
END FUNCTION.  

FUNCTION fn-has-row-errors RETURNS LOGICAL ():

    FOR EACH RowErrors 
        WHERE UPPER(RowErrors.ErrorType) = 'INTERNAL':U:
        DELETE RowErrors. 
    END.

    RETURN CAN-FIND(FIRST RowErrors 
        WHERE UPPER(RowErrors.ErrorSubType) = 'ERROR':U).
    
END FUNCTION.

/*:T--- DOMAIN PROCEDURES V1 ---*/

PROCEDURE pi-create-v1:

    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM TABLE FOR RowErrors.

    RUN pi-store-v1 IN THIS-PROCEDURE (
        INPUT oInput,
        INPUT FALSE,
        INPUT FALSE,
        OUTPUT oOutput
    ).

    CATCH eSysError AS Progress.Lang.SysError:
        CREATE RowErrors.
        ASSIGN RowErrors.ErrorNumber = 17006
               RowErrors.ErrorDescription = eSysError:getMessage(1)
               RowErrors.ErrorSubType = "ERROR".
    END.
    FINALLY: 
        IF fn-has-row-errors() THEN DO:
            UNDO, RETURN 'NOK':U.
        END.
    END FINALLY.

END PROCEDURE.

PROCEDURE pi-update-v1:

    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM TABLE FOR RowErrors.

    RUN pi-store-v1 IN THIS-PROCEDURE (
        INPUT oInput,
        INPUT TRUE,
        INPUT FALSE,
        OUTPUT oOutput
    ).

    CATCH eSysError AS Progress.Lang.SysError:
        CREATE RowErrors.
        ASSIGN RowErrors.ErrorNumber = 17006
               RowErrors.ErrorDescription = eSysError:getMessage(1)
               RowErrors.ErrorSubType = "ERROR".
    END.
    FINALLY:
        IF fn-has-row-errors() THEN DO:
            UNDO, RETURN 'NOK':U.
        END.
    END FINALLY.

END PROCEDURE.

PROCEDURE pi-upatch-v1:

    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM TABLE FOR RowErrors.

    RUN pi-store-v1 IN THIS-PROCEDURE (
        INPUT oInput,
        INPUT TRUE,
        INPUT TRUE,
        OUTPUT oOutput
    ).
    
    CATCH eSysError AS Progress.Lang.SysError:
        CREATE RowErrors.
        ASSIGN RowErrors.ErrorNumber = 17006
               RowErrors.ErrorDescription = eSysError:getMessage(1)
               RowErrors.ErrorSubType = "ERROR".
    END.
    FINALLY:
        IF fn-has-row-errors() THEN DO:
            UNDO, RETURN 'NOK':U.
        END.
    END FINALLY.

END PROCEDURE.

PROCEDURE pi-delete-v1:

    DEFINE INPUT  PARAM oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM TABLE FOR RowErrors.

    EMPTY TEMP-TABLE RowErrors.

    DEFINE VARIABLE oRequest  AS JsonAPIRequestParser NO-UNDO.

    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput).

    DEFINE VARIABLE tableKey AS integer      NO-UNDO.
    ASSIGN tableKey = INTEGER(fn-get-id-from-path(oRequest)).

    persistenceTransaction:
    DO TRANSACTION:

        IF NOT VALID-HANDLE(boHandler) THEN DO:
            RUN crmbo/boCrmTar.p PERSISTENT SET boHandler.
        END.

        RUN openQueryStatic IN boHandler (INPUT 'Default':U).
        RUN emptyRowErrors  IN boHandler.
        RUN goToKey         IN boHandler (INPUT tableKey).
		
		IF RETURN-VALUE = "NOK" THEN
			RETURN "NOK".
			
        RUN deleteRecord    IN boHandler.
        RUN getRowErrors    IN boHandler (OUTPUT TABLE RowErrors APPEND).
       
        IF fn-has-row-errors() THEN DO:
            LEAVE persistenceTransaction.
        END.
    END.

    CATCH eSysError AS Progress.Lang.SysError:
        CREATE RowErrors.
        ASSIGN RowErrors.ErrorNumber = 17006
               RowErrors.ErrorDescription = eSysError:getMessage(1)
               RowErrors.ErrorSubType = "ERROR".
    END.
    FINALLY: 
        
        DELETE PROCEDURE boHandler NO-ERROR.
        
        IF fn-has-row-errors() THEN DO:
            UNDO, RETURN 'NOK':U.
        END.
    END FINALLY.

END PROCEDURE.

/*:T--- QUERY PROCEDURES V1 ---*/

PROCEDURE pi-get-v1:

    DEFINE INPUT  PARAM oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM oOutput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM TABLE FOR RowErrors.

    DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE cExcept  AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE tableKey AS integer      NO-UNDO.

    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput).

    ASSIGN tableKey = INTEGER(fn-get-id-from-path(oRequest)).


    ASSIGN cExcept = JsonAPIUtils:getTableExceptFieldsBySerializedFields(
        TEMP-TABLE Task:HANDLE, oRequest:getFields()
    ).

    FOR FIRST crm_tar FIELDS (
        nom_telefone num_id num_id_acao num_id_campanha
    ) NO-LOCK 
        WHERE crm_tar.num_id EQ tableKey:
        
        CREATE Task.
        TEMP-TABLE Task:HANDLE:DEFAULT-BUFFER-HANDLE:BUFFER-COPY(
            BUFFER crm_tar:HANDLE, cExcept
        ).

        FOR FIRST crm_campanha NO-LOCK
            WHERE crm_campanha.num_id = crm_tar.num_id_campanha.
            ASSIGN Task.nom_campanha = crm_campanha.nom_campanha.
        END.

        FOR FIRST crm_acao NO-LOCK
            WHERE crm_acao.num_id = crm_tar.num_id_acao.
            ASSIGN Task.nom_acao = crm_acao.nom_acao.
        END.

        ASSIGN oOutput = JsonAPIUtils:convertTempTableFirstItemToJsonObject(
            TEMP-TABLE Task:HANDLE, (LENGTH(TRIM(cExcept)) > 0)
        ).
    END.
    
    CATCH eSysError AS Progress.Lang.SysError:
        CREATE RowErrors.
        ASSIGN RowErrors.ErrorNumber = 17006
               RowErrors.ErrorDescription = eSysError:getMessage(1)
               RowErrors.ErrorSubType = "ERROR".
    END.
    FINALLY: 
        IF fn-has-row-errors() THEN DO:
            UNDO, RETURN 'NOK':U.
        END.
    END FINALLY.

END PROCEDURE.

PROCEDURE pi-query-v1:

    DEFINE INPUT  PARAM oInput   AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM aOutput  AS JsonArray  NO-UNDO.
    DEFINE OUTPUT PARAM lHasNext AS LOGICAL    NO-UNDO INITIAL FALSE.
    DEFINE OUTPUT PARAM TABLE FOR RowErrors.

    EMPTY TEMP-TABLE RowErrors.
    EMPTY TEMP-TABLE Task.

    DEFINE VARIABLE oRequest   AS JsonAPIRequestParser  NO-UNDO.
    DEFINE VARIABLE iCount     AS INTEGER INITIAL 0     NO-UNDO.

    DEFINE VARIABLE cExcept    AS CHARACTER             NO-UNDO.
    DEFINE VARIABLE cQuery     AS CHARACTER             NO-UNDO.
    DEFINE VARIABLE cQueryName AS CHARACTER             NO-UNDO.
	DEFINE VARIABLE cBy        AS CHARACTER             NO-UNDO.

    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput).    

    ASSIGN cExcept = JsonAPIUtils:getTableExceptFieldsBySerializedFields(
        TEMP-TABLE Task:HANDLE, oRequest:getFields()
    ).

    ASSIGN cQuery = 'FOR EACH crm_tar NO-LOCK'.

    DEFINE QUERY findQuery FOR crm_tar 
        FIELDS(nom_telefone num_id num_id_acao num_id_campanha)
    SCROLLING.

    QUERY findQuery:QUERY-PREPARE(cQuery).
    QUERY findQuery:QUERY-OPEN().
    QUERY findQuery:REPOSITION-TO-ROW(oRequest:getStartRow()).

    REPEAT:

        GET NEXT findQuery.
        IF QUERY findQuery:QUERY-OFF-END THEN LEAVE.

        IF oRequest:getPageSize() EQ iCount THEN DO:
            ASSIGN lHasNext = TRUE.
            LEAVE.
        END.

        CREATE Task.
        TEMP-TABLE Task:HANDLE:DEFAULT-BUFFER-HANDLE:BUFFER-COPY(
            BUFFER crm_tar:HANDLE, cExcept
        ).

        FOR FIRST crm_campanha NO-LOCK
            WHERE crm_campanha.num_id = crm_tar.num_id_campanha.
            ASSIGN Task.nom_campanha = crm_campanha.nom_campanha.
        END.

        FOR FIRST crm_acao NO-LOCK
            WHERE crm_acao.num_id = crm_tar.num_id_acao.
            ASSIGN Task.nom_acao = crm_acao.nom_acao.
        END.
        
        ASSIGN iCount = iCount + 1.
    END.

    ASSIGN aOutput = JsonAPIUtils:convertTempTableToJsonArray(
        TEMP-TABLE Task:HANDLE, (LENGTH(TRIM(cExcept)) > 0)
    ).

    CATCH eSysError AS Progress.Lang.SysError:
        CREATE RowErrors.
        ASSIGN RowErrors.ErrorNumber = 17006
               RowErrors.ErrorDescription = eSysError:getMessage(1)
               RowErrors.ErrorSubType = "ERROR".
    END.
    FINALLY: 
        IF fn-has-row-errors() THEN DO:
            UNDO, RETURN 'NOK':U.
        END.
    END FINALLY.

END PROCEDURE.

PROCEDURE pi-query-diff-v1:

    DEFINE INPUT  PARAM oInput   AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAM aOutput  AS JsonArray  NO-UNDO.
    DEFINE OUTPUT PARAM lHasNext AS LOGICAL    NO-UNDO INITIAL FALSE.
    DEFINE OUTPUT PARAM TABLE FOR RowErrors.

    EMPTY TEMP-TABLE RowErrors.
    EMPTY TEMP-TABLE Task.

    DEFINE VARIABLE oRequest   AS JsonAPIRequestParser  NO-UNDO.
    DEFINE VARIABLE iCount     AS INTEGER INITIAL 0     NO-UNDO.
    DEFINE VARIABLE cQuery     AS CHARACTER   NO-UNDO.

    DEFINE VARIABLE dtmLastSync        AS DATETIME   NO-UNDO.

    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput)
           dtmLastSync = fn-get-last-sync-from-path(oRequest).

    MESSAGE ">>>>>>>>>> dtmLastSync " dtmLastSync
        VIEW-AS ALERT-BOX INFO BUTTONS OK.

    ASSIGN cQuery = "FOR EACH crm_tar NO-LOCK ".

    IF dtmLastSync <> ? THEN DO:
        ASSIGN cQuery = cQuery + ' WHERE crm_tar.dtm_modif >= DATETIME("' + STRING(dtmLastSync) + '")'.
    END.


    DEFINE QUERY findQuery FOR crm_tar 
        FIELDS(nom_telefone num_id num_id_acao num_id_campanha)
    SCROLLING.

    QUERY findQuery:QUERY-PREPARE(cQuery).
    QUERY findQuery:QUERY-OPEN().
    QUERY findQuery:REPOSITION-TO-ROW(oRequest:getStartRow()).

    REPEAT:

        GET NEXT findQuery.
        IF QUERY findQuery:QUERY-OFF-END THEN LEAVE.

        IF oRequest:getPageSize() EQ iCount THEN DO:
            ASSIGN lHasNext = TRUE.
            LEAVE.
        END.

        CREATE Task.
        TEMP-TABLE Task:HANDLE:DEFAULT-BUFFER-HANDLE:BUFFER-COPY(
            BUFFER crm_tar:HANDLE, ''
        ).
        
        FOR FIRST crm_campanha NO-LOCK
            WHERE crm_campanha.num_id = crm_tar.num_id_campanha.
            ASSIGN Task.nom_campanha = crm_campanha.nom_campanha.
        END.

        FOR FIRST crm_acao NO-LOCK
            WHERE crm_acao.num_id = crm_tar.num_id_acao.
            ASSIGN Task.nom_acao = crm_acao.nom_acao.
        END.

        ASSIGN iCount = iCount + 1.
    END.

    ASSIGN aOutput = JsonAPIUtils:convertTempTableToJsonArray(
        TEMP-TABLE Task:HANDLE, FALSE
    ).

    CATCH eSysError AS Progress.Lang.SysError:
        CREATE RowErrors.
        ASSIGN RowErrors.ErrorNumber = 17006
               RowErrors.ErrorDescription = eSysError:getMessage(1)
               RowErrors.ErrorSubType = "ERROR".
    END.
    FINALLY: 
        IF fn-has-row-errors() THEN DO:
            UNDO, RETURN 'NOK':U.
        END.
    END FINALLY.

END PROCEDURE.
/*:T--- PRIVATE PROCEDURES ---*/

PROCEDURE pi-store-v1:

    DEFINE INPUT  PARAM oInput    AS JsonObject NO-UNDO.
    DEFINE INPUT  PARAM isUpdate  AS LOGICAL    NO-UNDO INITIAL FALSE.
    DEFINE INPUT  PARAM isParcial AS LOGICAL    NO-UNDO INITIAL FALSE.
    DEFINE OUTPUT PARAM oOutput   AS JsonObject NO-UNDO.

    EMPTY TEMP-TABLE RowErrors.
    EMPTY TEMP-TABLE TaskPersistent.

    DEFINE VARIABLE oRequest  AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE oPayload  AS JsonObject           NO-UNDO.
    
    DEFINE VARIABLE tableKey AS integer      NO-UNDO.
    
    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput).
    ASSIGN oPayload = oRequest:getPayload().

    IF isUpdate THEN DO:
        ASSIGN tableKey = INTEGER(fn-get-id-from-path(oRequest)).
    END.
    
    persistenceTransaction:
    DO TRANSACTION:

        IF NOT VALID-HANDLE(boHandler) THEN DO:
            RUN crmbo/boCrmTar.p PERSISTENT SET boHandler.
        END.

        RUN openQueryStatic IN boHandler (INPUT 'Default':U).
        RUN emptyRowErrors  IN boHandler.

        IF isUpdate THEN DO:
            
            RUN goToKey IN boHandler (INPUT tableKey).
            
            IF UPPER(RETURN-VALUE) EQ 'NOK':U THEN DO:
                LEAVE persistenceTransaction.
            END.

            RUN getRecord IN boHandler (OUTPUT TABLE TaskPersistent).
        END.
        ELSE DO:
            CREATE TaskPersistent.
        END.

        FIND FIRST TaskPersistent NO-LOCK NO-ERROR.

		TaskPersistent.nom_telefone = fn-get-char-from-payload(oPayload, "phone", isUpdate, isParcial, TaskPersistent.nom_telefone).
		TaskPersistent.num_id_acao = fn-get-int-from-payload(oPayload, "actionId", isUpdate, isParcial, TaskPersistent.num_id_acao).
		TaskPersistent.num_id_campanha = fn-get-int-from-payload(oPayload, "campaignId", isUpdate, isParcial, TaskPersistent.num_id_campanha).
		
		
        RUN setRecord      IN boHandler (INPUT TABLE TaskPersistent).
        RUN emptyRowErrors IN boHandler.
      
        IF isUpdate THEN DO:
            RUN updateRecord IN boHandler.
        END.
        ELSE DO:
            RUN createRecord IN boHandler.
        END.

        EMPTY TEMP-TABLE Task.
        EMPTY TEMP-TABLE TaskPersistent.

        RUN getRowErrors IN boHandler (OUTPUT TABLE RowErrors APPEND).
        RUN getRecord    IN boHandler (OUTPUT TABLE TaskPersistent).

        IF fn-has-row-errors() THEN DO:
            LEAVE persistenceTransaction.
        END.

        FOR FIRST TaskPersistent:
            CREATE Task.
            BUFFER-COPY TaskPersistent TO Task.              
        END.
        
        ASSIGN oOutput = JsonAPIUtils:convertTempTableFirstItemToJsonObject(
            TEMP-TABLE Task:HANDLE
        ).
    END.
    
    CATCH eSysError AS Progress.Lang.SysError:
        CREATE RowErrors.
        ASSIGN RowErrors.ErrorNumber = 17006
               RowErrors.ErrorDescription = eSysError:getMessage(1)
               RowErrors.ErrorSubType = "ERROR".
    END.
    FINALLY:
        DELETE PROCEDURE boHandler NO-ERROR.
    END FINALLY.

END PROCEDURE.
