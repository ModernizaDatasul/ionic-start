/*
    Retorna o nome do campo da TEMP-TABLE com base no SERIALIZE-NAME informado
    
    Parametros
        - HANDLE da TEMP-TABLE
        - SERIALIZE-NAME do campo
    Retorno
        - Nome do campo na TEMP-TABLE
*/
FUNCTION getFieldName RETURNS CHARACTER (
    INPUT h-temp-table    AS HANDLE,
    INPUT serializeName   AS CHARACTER):
     
    DEFINE VARIABLE i AS INTEGER     NO-UNDO.

    DO i = 1 TO h-temp-table:DEFAULT-BUFFER-HANDLE:NUM-FIELDS:
        IF h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):SERIALIZE-NAME = serializeName THEN DO:
            RETURN h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):NAME.
        END.      
    END.

    RETURN "".
END.

/*
    Retorna o tipo de dado do campo da TEMP-TABLE com base no SERIALIZE-NAME informado
    
    Parametros
        - HANDLE da TEMP-TABLE
        - SERIALIZE-NAME do campo
    Retorno
        - Tipo de dado do campo em forma de string, exemplo: CHARACTER, INTEGER, LOGICAL
*/
FUNCTION getFieldDataType RETURNS CHARACTER (
    INPUT h-temp-table    AS HANDLE,
    INPUT serializeName   AS CHARACTER):
    
    DEFINE VARIABLE i AS INTEGER     NO-UNDO.

    DO i = 1 TO h-temp-table:DEFAULT-BUFFER-HANDLE:NUM-FIELDS:
        IF h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):SERIALIZE-NAME = serializeName THEN DO:
            RETURN h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):DATA-TYPE.
        END.      
    END.
END.

/*
    Todos as transa��es de informa��o que suportam campos do tipo data/hora, tanto no corpo das mensagens quanto na URI, devem usar um dos seguintes formatos:
    Data (E8601DAw.): yyyy-mm-dd

    Converte a DATA enviada via QUERY PARAM para um DATE
    
    Par�metros:
        - Valor informado no QUERY PARAM
    Retorno
        - Valor formatado para um DATE
*/

FUNCTION convertQueryDateParamToDate RETURNS DATE (
    INPUT c-queryDate AS CHARACTER):
    
    DEFINE VARIABLE d-date AS DATE      NO-UNDO.
    
    ASSIGN d-date = DATE(INT(SUBSTR(c-queryDate, 6, 2)), 
                         INT(SUBSTR(c-queryDate, 9, 2)),
                         INT(SUBSTR(c-queryDate, 1, 4))).

    RETURN d-date.

END FUNCTION.

/*
    Retorna o comando BY que deve ser usado QUERY
    
    Par�netro
        - O JsonArray contendo o QUERY PARAM order
    Retorno
        - O comando BY que deve ser usado na QUERY

*/

FUNCTION buildBy RETURNS CHARACTER (
    INPUT h-temp-table  AS HANDLE,
    INPUT oOrder        AS JsonArray):

    DEFINE VARIABLE c-by            AS CHARACTER    INITIAL ""      NO-UNDO.
    DEFINE VARIABLE i               AS INTEGER                      NO-UNDO.
    DEFINE VARIABLE fieldName       AS CHARACTER                    NO-UNDO.
    
    DO i = 1 TO oOrder:LENGTH.
        ASSIGN fieldName = getFieldName(INPUT h-temp-table, INPUT REPLACE(oOrder:getCharacter(i), "-", "")).

        IF fieldName <> "" THEN DO:
            ASSIGN c-by = c-by + " BY " + fieldName.

            IF oOrder:getCharacter(i) BEGINS "-" THEN
                ASSIGN c-by = c-by + " DESC".
        END.
    END.
    
    RETURN c-by.

END FUNCTION.

/*
    Retorna o comando WHERE que deve ser usado na QUERY
    
    Par�metros
        - JsonObject com os QUERY PARAMS que foram informados na URL
        - Lista de campos que n�o devem ser considerados na moontagem do comando, a lista deve ser informada
          separando os campos por v�rgula e deve ser usado o SERIALIZE-NAME, exemplo: "name,code"
        - QUERY j� existente
    Retorno
        - O comando WHERE que deve ser usado na QUERY
*/

FUNCTION buildWhere RETURNS CHARACTER (
    INPUT h-temp-table  AS HANDLE,
    INPUT oQueryParams AS JsonObject,
    INPUT cExceptions  AS CHARACTER,
    INPUT cQuery       AS CHARACTER):

    DEFINE VARIABLE cComando        AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE aParam          AS JsonArray   NO-UNDO.
    
    DEFINE VARIABLE c_params        AS CHARACTER    EXTENT  NO-UNDO.
    DEFINE VARIABLE fieldName       AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE dataType        AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE cCommand        AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE cTable          AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE cFilter         AS LONGCHAR             NO-UNDO.
    DEFINE VARIABLE aFilter         AS JsonArray            NO-UNDO.
    // vari�veis utilizadas na convers�o da data, para os casos de par�metros com Filtro Composto
    DEFINE VARIABLE iFieldPosition  AS INTEGER              NO-UNDO.
    DEFINE VARIABLE cDate           AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE cTableAndField  AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE cSearchString   AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE dConvertedDate  AS DATE                 NO-UNDO.

    DEFINE VARIABLE i   AS INTEGER     NO-UNDO.
    DEFINE VARIABLE j   AS INTEGER     NO-UNDO.

    ASSIGN c_params = oQueryParams:getNames().


    // verifica se foi passado os parametros compostos (com o $filter, que � obrigat�rio conforme Guia de API TOTVS)
    ASSIGN aFilter = oQueryParams:GetJsonArray("$filter") NO-ERROR.

    // testa se o objeto est� valido (se ele n�o foi passado, n�o estar� valido)
    IF  VALID-OBJECT(aFilter) THEN
        ASSIGN cFilter = aFilter:getCharacter(1).


    // se foi utilizado Filtro Composto, a vari�vel ter� valor
    IF  cFilter <> "":U THEN DO:

        // busca o nome da tabela utilizada na query, para montar o where corretamente
        ASSIGN cTable = ENTRY(3, cQuery, " ":U).

        // adiciona um espa�o em branco ao inicio da string, para que o REPLACE funcione corretamente
        ASSIGN cFilter = " " + cFilter.

        // percorre os campos da temp-table para substituir o serialize-name pelo nome do campo da tabela
        DO  i = 1 TO h-temp-table:DEFAULT-BUFFER-HANDLE:NUM-FIELDS:
            // casos onde o campo est� no meio da string
            ASSIGN cFilter = REPLACE(cFilter, " " + h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):SERIALIZE-NAME + " ", " " + cTable + "." + h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):NAME + " ").

            // para os casos onde o campo est� no inicio de um agrupamento
            ASSIGN cFilter = REPLACE(cFilter, " (" + h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):SERIALIZE-NAME + " ", " (" + cTable + "." + h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):NAME + " ").
        END.

        // retira o espa�o em branco do inicio, que foi adicionado anteriormente
        ASSIGN cFilter = SUBSTRING(cFilter, 2, LENGTH(cFilter)).


        blk_table:
        DO  i = 1 TO h-temp-table:DEFAULT-BUFFER-HANDLE:NUM-FIELDS:

            // somente faz as convers�es para os campos no formate DATE
            IF  h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):DATA-TYPE = "DATE":U THEN DO:
                // atualiza a vari�vel com o nome da tabela e campo (que � data)
                // ex: cTableAndField ter� este valor -> gg-lote-mov.dat-atualiz
                ASSIGN cTableAndField = cTable + ".":U + h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i):NAME.

                // verifica se este campo da tabela � utilizado na string de filtro (busca)
                IF  INDEX(cFilter, cTableAndField) = 0 THEN
                    NEXT blk_table.

                // atualiza a vari�vel que ser� utilizada na busca
                // ex: cSearchString ter� este valor -> "gg-lote-mov.num-id-lote eq 12 or gg-lote-mov.dat-atualiz eq '2019-12-30' or gg-lote-mov.dat-atualiz eq '2020-01-15' or gg-lote-mov.dat-atualiz eq '2020-01-27'"
                ASSIGN cSearchString = cFilter.

                // busca na string todas as entradas existentes para este campo da tabela
                // no coment�rio "ex: " � um exemplo de execu��o, contando apenas a primeira repeti��o... por�m ele passar� 3 vezes no la�o, visto que existem 3 vezes o campo 'gg-lote-mov.dat-atualiz' na string de filtro
                DO WHILE TRUE:
                
                    // atualiza a posi��o onde o campo foi encontrado dentro da string
                    ASSIGN iFieldPosition = INDEX(cSearchString, cTableAndField).
                
                    // atualiza a string de busca retirando o que vem antes do campo de pesquisa (incluindo ele)
                    // ex: cSearchString ficar� assim -> " eq '2019-12-30' or gg-lote-mov.dat-atualiz eq '2020-01-15' or gg-lote-mov.dat-atualiz eq '2020-01-27'"
                    ASSIGN cSearchString = SUBSTRING(cSearchString, iFieldPosition + LENGTH(cTableAndField), LENGTH(cSearchString)).
                
                    // busca somente a string que contem a informa��o da data (ou date-time), para poder fazer a substitui��o
                    // ex: cDate ter� este valor -> '2019-12-30'
                    ASSIGN cDate = ENTRY(3, cSearchString, "":U).

                    // converte a string em data
                    // ex: dConvertedDate ter� este valor -> 30/12/19
                    ASSIGN dConvertedDate = convertQueryDateParamToDate(REPLACE(cDate, "'":U, "":U)).
                
                    // faz a substitui��o da data em string, para a data no formato date
                    // ex: cFilter ter� este valor -> gg-lote-mov.num-id-lote eq 12 or gg-lote-mov.dat-atualiz eq 30/12/19 or gg-lote-mov.dat-atualiz eq '2020-01-15' or gg-lote-mov.dat-atualiz eq '2020-01-27'
                    ASSIGN cFilter = REPLACE(cFilter, cDate, STRING(dConvertedDate)).
                
                    // verifica se ainda existem mais filtros pelo campo da tabela, considerando a parte da string ainda n�o convertida
                    // ex: cSearchString ter� este valor -> " eq '2019-12-30' or gg-lote-mov.dat-atualiz eq '2020-01-15' or gg-lote-mov.dat-atualiz eq '2020-01-27'"
                    IF  INDEX(cSearchString, cTableAndField) = 0 THEN
                        LEAVE.
                END.
            END.
        END. //blk_table:

        // monta a query com o filtro passado por par�metro (e j� convertido, caso necess�rio)
        ASSIGN cQuery = cQuery + " WHERE ":U + cFilter.

    END.
    ELSE DO: // se n�o foi utilizado o $filter, � um Filtro Simples

        DO i = 1 TO EXTENT(c_params).
            ASSIGN aParam = oQueryParams:GetJsonArray(c_params[i]).
            
            DO j = 1 TO aParam:LENGTH.
                IF LOOKUP(c_params[i], cExceptions) = 0 THEN DO: 
                    ASSIGN dataType  = getFieldDataType (INPUT h-temp-table, INPUT c_params[i])
                           fieldName = getFieldName     (INPUT h-temp-table, INPUT c_params[i]).
    
                    IF fieldName <> "" THEN DO:
                        ASSIGN cCommand = IF INDEX(cQuery, "WHERE") > 0 THEN " AND " ELSE " WHERE ".
    
                        CASE dataType:
                            WHEN "CHARACTER" THEN DO:
                                ASSIGN cQuery = cQuery + cCommand + fieldName + ' MATCHES "':U + aParam:getCharacter(j) + '"':U.
                            END.
                            WHEN "INTEGER" THEN DO:
                                ASSIGN cQuery = cQuery + cCommand + fieldName + ' EQ ':U + STRING(aParam:getCharacter(j)).
                            END.
                            WHEN "DECIMAL" THEN DO:
                                ASSIGN cQuery = cQuery + cCommand + fieldName + ' EQ ':U + STRING(aParam:getCharacter(j)).
                            END.
                            WHEN "LOGICAL" THEN DO:
                                ASSIGN cQuery = cQuery + cCommand + fieldName + ' EQ ':U + STRING(aParam:getCharacter(j)).
                            END.
                            WHEN "DATE" THEN DO:
                                ASSIGN cQuery = cQuery + cCommand + fieldName + ' EQ ':U + STRING(convertQueryDateParamToDate(aParam:getCharacter(j))).
                            END.
                        END CASE.
                    END.
                END.
            END.
        END.
    END.

    RETURN cQuery.
END FUNCTION.

/*
    Retorna a lista de campos informados no FIELDS do QUERY-PARAM separados por v�rgula
    
    Par�metros:
        - JsonArray com os campos informados no QUERY-PARAM
    Retorno
        - Lista com os campos separados por v�rgula
*/

FUNCTION getFieldsList RETURNS CHARACTER  (
    INPUT aFields AS JsonArray):

    DEFINE VARIABLE i         AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cFields   AS CHARACTER NO-UNDO INITIAL '':U.
    DEFINE VARIABLE cJsonText AS CHARACTER NO-UNDO.

    ASSIGN cJsonText = aFields:getJsonText().
    DO i = 1 TO aFields:LENGTH:
        ASSIGN cFields = cFields + aFields:getCharacter(i) + ',':U. 
    END.

    RETURN cFields.

END FUNCTION.

/*
    Retorna a lista de campos informados no EXPAND do QUERY-PARAM separados por v�rgula
    
    Par�metros:
        - JsonArray com os campos informados no EXPANDS
    Retorno
        - Lista com os campos separados por v�rgula
*/

FUNCTION getExpandsList RETURNS CHARACTER  (
    INPUT aFields AS JsonArray):

    DEFINE VARIABLE i         AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cFields   AS CHARACTER NO-UNDO INITIAL '':U.
    DEFINE VARIABLE cJsonText AS CHARACTER NO-UNDO.

    ASSIGN cJsonText = aFields:getJsonText().
    DO i = 1 TO aFields:LENGTH:
        ASSIGN cFields = cFields + aFields:getCharacter(i) + ',':U. 
    END.

    RETURN cFields.

END FUNCTION.

/*
    Retorna a lista de campos indexados em uma tabela.
    
    Par�metros:
        - Nome da tabela
    Retorno
        - Lista com os campos separados por v�rgula
*/
FUNCTION getIndexedFields RETURNS CHARACTER (
    INPUT c-table-name   AS CHARACTER):

    DEFINE VARIABLE i-cont   AS INTEGER    NO-UNDO.
    DEFINE VARIABLE i-index  AS INTEGER    NO-UNDO.
    DEFINE VARIABLE c-index  AS CHARACTER  NO-UNDO.

    DEFINE VARIABLE h-buffer AS HANDLE NO-UNDO.
    CREATE BUFFER h-buffer FOR TABLE c-table-name NO-ERROR.

    ASSIGN i-cont = 1.
    REPEAT WHILE h-buffer:INDEX-INFORMATION(i-cont) <> ?:
        REPEAT i-index = 5 TO NUM-ENTRIES(h-buffer:INDEX-INFORMATION(i-cont),","):
            IF  ENTRY(i-index,h-buffer:INDEX-INFORMATION(i-cont),",") <> "0"
            AND ENTRY(i-index,h-buffer:INDEX-INFORMATION(i-cont),",") <> "1"
            AND INDEX(c-index,ENTRY(i-index,h-buffer:INDEX-INFORMATION(i-cont),",") + ",") = 0 THEN
                ASSIGN c-index = c-index + ENTRY(i-index,h-buffer:INDEX-INFORMATION(i-cont),",") + ",".
        END.
        ASSIGN i-cont = i-cont + 1.
    END.

    RETURN c-index.
END.

/*
    Retorna a lista de campos (SERIALIZE-NAME) que n�o est�o indexados em uma tabela.
    
    Par�metros:
        - HANDLE temp-table 
        - Nome da tabela
    Retorno
        - Lista com os campos(SERIALIZE-NAME) separados por v�rgula
*/
FUNCTION getUnindexedFields RETURNS CHARACTER (
    INPUT h-temp-table    AS HANDLE,
    INPUT c-table-name   AS CHARACTER):

    DEFINE VARIABLE i-cont   AS INTEGER    NO-UNDO.
    DEFINE VARIABLE c-index  AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE c-fields AS CHARACTER  NO-UNDO.

    ASSIGN c-index = getIndexedFields(c-table-name).

    DO i-cont = 1 TO h-temp-table:DEFAULT-BUFFER-HANDLE:NUM-FIELDS:
        IF INDEX(c-index,h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i-cont):NAME + ",") = 0 THEN
            ASSIGN c-fields = c-fields + h-temp-table:DEFAULT-BUFFER-HANDLE:BUFFER-FIELD(i-cont):SERIALIZE-NAME + ",".
    END.

    RETURN c-fields.
END.

FUNCTION fn-get-date-from-payload RETURNS DATE (
    INPUT oPayload     AS JsonObject, /* Body da requisi��o                                   */
    INPUT fieldName    AS CHARACTER,  /* Campo que deve ser retornado do Body                 */
    INPUT isUpdate     AS LOGICAL,    /* � um PUT?                                            */
    INPUT isParcial    AS LOGICAL,    /* � um PATCH?                                          */
    INPUT currentValue AS DATE        /* Valor atual do campo, ser� usado quando for um PATCH */
):                                    /* para manter o valor atual                            */  
    IF oPayload:has(fieldName) THEN DO:
        RETURN oPayload:getDate(fieldName).
    END.
    ELSE DO:
        IF isUpdate AND NOT isParcial THEN DO:
            RETURN ?.
        END.
    END.

    RETURN currentValue.
END FUNCTION.

FUNCTION fn-get-char-from-payload RETURNS CHARACTER (
    INPUT oPayload     AS JsonObject, /* Body da requisi��o                                   */  
    INPUT fieldName    AS CHARACTER,  /* Campo que deve ser retornado do Body                 */  
    INPUT isUpdate     AS LOGICAL,    /* � um PUT?                                            */  
    INPUT isParcial    AS LOGICAL,    /* � um PATCH?                                          */  
    INPUT currentValue AS CHARACTER   /* Valor atual do campo, ser� usado quando for um PATCH */  
):                                    /* para manter o valor atual                            */  
    IF oPayload:has(fieldName) THEN DO:
        RETURN oPayload:getCharacter(fieldName).
    END.
    ELSE DO:
        IF isUpdate AND NOT isParcial THEN DO:
            RETURN "".
        END.
    END.

    RETURN currentValue.
END FUNCTION.

FUNCTION fn-get-int-from-payload RETURNS INTEGER (
    INPUT oPayload     AS JsonObject, /* Body da requisi��o                                   */  
    INPUT fieldName    AS CHARACTER,  /* Campo que deve ser retornado do Body                 */  
    INPUT isUpdate     AS LOGICAL,    /* � um PUT?                                            */  
    INPUT isParcial    AS LOGICAL,    /* � um PATCH?                                          */  
    INPUT currentValue AS INTEGER     /* Valor atual do campo, ser� usado quando for um PATCH */  
):                                    /* para manter o valor atual                            */  
    IF oPayload:has(fieldName) THEN DO:
        RETURN oPayload:getInteger(fieldName).
    END.
    ELSE DO:
        IF isUpdate AND NOT isParcial THEN DO:
            RETURN 0.
        END.
    END.

    RETURN currentValue.
END FUNCTION.


FUNCTION fn-get-dec-from-payload RETURNS DECIMAL (
    INPUT oPayload     AS JsonObject, /* Body da requisi��o                                   */  
    INPUT fieldName    AS CHARACTER,  /* Campo que deve ser retornado do Body                 */  
    INPUT isUpdate     AS LOGICAL,    /* � um PUT?                                            */  
    INPUT isParcial    AS LOGICAL,    /* � um PATCH?                                          */  
    INPUT currentValue AS DECIMAL     /* Valor atual do campo, ser� usado quando for um PATCH */  
):                                    /* para manter o valor atual                            */  
    IF oPayload:has(fieldName) THEN DO:
        RETURN oPayload:getDecimal(fieldName).
    END.
    ELSE DO:
        IF isUpdate AND NOT isParcial THEN DO:
            RETURN 0.
        END.
    END.

    RETURN currentValue.
END FUNCTION.

FUNCTION fn-get-log-from-payload RETURNS LOGICAL (
    INPUT oPayload     AS JsonObject, /* Body da requisi��o                                   */  
    INPUT fieldName    AS CHARACTER,  /* Campo que deve ser retornado do Body                 */  
    INPUT isUpdate     AS LOGICAL,    /* � um PUT?                                            */  
    INPUT isParcial    AS LOGICAL,    /* � um PATCH?                                          */  
    INPUT currentValue AS LOGICAL     /* Valor atual do campo, ser� usado quando for um PATCH */  
):                                    /* para manter o valor atual                            */  
    IF oPayload:has(fieldName) THEN DO:
        RETURN oPayload:getLogical(fieldName).
    END.
    ELSE DO:
        IF isUpdate AND NOT isParcial THEN DO:
            RETURN NO.
        END.
    END.

    RETURN currentValue.
END FUNCTION.
