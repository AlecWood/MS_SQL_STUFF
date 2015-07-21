DECLARE @Case BIT ,
    @Search NVARCHAR(1000) ,
    @Looper INT ,
    @Cnt INT ,
    @DB VARCHAR(100) ,
    @Select NVARCHAR(4000)

SELECT  @Looper = 1 ,
        @Cnt = 0

SELECT  @Case = 0 , -- Set to 1 for case-sensitive search
        @Search = 'datInvoiced' -- The text we're searching for
        
SELECT  @Search = '%' + @Search + '%'

IF OBJECT_ID('tempdb..#ResultsTable') IS NOT NULL
    DROP TABLE #ResultsTable

CREATE TABLE #ResultsTable
    (
      intRow INT IDENTITY(1, 1) ,
      txtDatabase VARCHAR(100) NULL ,
      txtName VARCHAR(100) NULL ,
      txtType VARCHAR(5) NULL
    )

INSERT  INTO #ResultsTable
        ( txtDatabase )
        SELECT  'Search for: ' + @Search
        
IF OBJECT_ID('tempdb..#ObjectTypes') IS NOT NULL
    DROP TABLE #ObjectTypes
    
CREATE TABLE #ObjectTypes
    (
      txtType VARCHAR(5) NULL ,
      txtDesc VARCHAR(50)
    )
    
INSERT  INTO #ObjectTypes
        ( txtDesc
        )
        SELECT  name
        FROM    master.dbo.spt_values
        WHERE   type = 'O9T'        

DELETE  FROM #ObjectTypes
WHERE   CHARINDEX(':', txtDesc) = 0
        OR txtDesc LIKE '%assembly%'
        OR txtDesc LIKE '%key%'
        OR txtDesc LIKE '%extended%'
        OR txtDesc LIKE '%cns%'
        OR txtDesc LIKE '%application%'
        
UPDATE  #ObjectTypes
SET     txtType = LEFT(txtDesc, CHARINDEX(':', txtDesc) - 1)

UPDATE  #ObjectTypes
SET     txtType = LTRIM(RTRIM(txtType)) ,
        txtDesc = RIGHT(txtDesc, LEN(txtDesc) - CHARINDEX(':', txtDesc) - 1)
        
DELETE  FROM #ObjectTypes
WHERE   txtType IN ( 'EN', 'L', 'S', 'SQ', 'RF', 'R' )

IF OBJECT_ID('tempdb..#Databases') IS NOT NULL
    DROP TABLE #Databases
CREATE TABLE #Databases
    (
      intDB INT IDENTITY(1, 1) ,
      txtDB VARCHAR(100)
    )
    
INSERT  INTO #Databases
        ( txtDB
        )
        SELECT  name
        FROM    sys.sysdatabases
        WHERE   dbid > 4 -- id <= 4 are system databases

SELECT  @Cnt = @@IDENTITY

WHILE @Looper <= @Cnt
    BEGIN
        SELECT  @DB = txtDB
        FROM    #Databases
        WHERE   intDB = @Looper
        
        SELECT  @Select = 'INSERT INTO #ResultsTable (txtDatabase, txtName, txtType) '
                + 'SELECT DISTINCT ' + CHAR(39) + @DB + CHAR(39)
                + ', Obj.name, Obj.type FROM ' + @DB
                + '.dbo.sysobjects Obj (NOLOCK) INNER JOIN ' + @DB
                + '.dbo.syscomments Cmt (NOLOCK) on Obj.id = Cmt.id WHERE Cmt.text LIKE '
                + CHAR(39) + @Search + CHAR(39)
        
        IF @Case = 1
            SELECT  @Select = @Select + ' Collate Latin1_General_CS_AS '
        
        SELECT  @Select = @Select + ' ORDER BY Obj.name'

        SELECT  @Looper = @Looper + 1
        
        EXEC sp_executesql @Select
        
    END


SELECT  txtDatabase, txtName, txtDesc
FROM    #ResultsTable
        LEFT OUTER JOIN #ObjectTypes ON #ObjectTypes.txtType = #ResultsTable.txtType
ORDER BY intRow

DROP TABLE #Databases, #ObjectTypes, #ResultsTable

