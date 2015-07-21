DECLARE @tablename VARCHAR(50)
SELECT @tablename = 'tblSearch'

IF EXISTS ( SELECT  *
                FROM    dbo.sysobjects
                WHERE   id = OBJECT_ID(N'[dbo].[' + @tableName + ']')
                        AND OBJECTPROPERTY(id, N'IsUserTable') = 1 )
        SELECT  cols.name AS 'Name' ,
                typs.name AS 'Type' ,
                cols.Length ,
                cols.prec AS 'Precision' ,
                cols.Scale ,
                Allownulls AS 'Allow Nulls'
        FROM    syscolumns cols
                INNER JOIN systypes typs ON cols.xusertype = typs.xusertype
        WHERE   id = OBJECT_ID(@tableName) 
    ELSE
        PRINT 'No table named ' + @tableName + ' in the ' + DB_NAME() + ' Database' 
