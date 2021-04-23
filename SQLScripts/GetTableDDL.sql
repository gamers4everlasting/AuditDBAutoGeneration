--CREATE A PROCEDURE --use SMICADB;
CREATE OR ALTER PROCEDURE [dbo].[Sp_getTableDDL] @TBL VARCHAR(255), @outputDDlScript NVARCHAR(max) OUTPUT
AS 
  BEGIN 
      SET nocount ON 

      DECLARE @TBLNAME            VARCHAR(200), 
              @SCHEMANAME         VARCHAR(255), 
              @STRINGLEN          INT, 
              @TABLE_ID           INT, 
              @FINALSQL           VARCHAR(max),
              @vbCrLf             CHAR(2) 

      SET @vbCrLf = Char(13) + Char(10) 

      SELECT @SCHEMANAME = Isnull(Parsename(@TBL, 2), 'dbo'), 
             @TBLNAME = Parsename(@TBL, 1) 

      SELECT @TABLE_ID = [object_id] 
      FROM   sys.objects 
      WHERE  [type] = 'U' 
             AND [name] <> 'dtproperties' 
             AND [name] = @TBLNAME 
             AND [schema_id] = Schema_id(@SCHEMANAME); 

      IF Isnull(@TABLE_ID, 0) = 0 
        BEGIN 
            SET @FINALSQL = 'Table object [' + @SCHEMANAME + '].[' 
                            + Upper(@TBLNAME) 
                            + '] does not exist in Database [' 
                            + Db_name() + ']' 

            SELECT @FINALSQL; 

            RETURN 0 
        END 

      SELECT @FINALSQL = 'CREATE TABLE [' + @SCHEMANAME + '].[' 
                         + (@TBLNAME) + '] ( ' 

      SELECT @TABLE_ID = Object_id(@TBLNAME) 

      SELECT @STRINGLEN = Max(Len(sys.columns.[name])) + 1 
      FROM   sys.objects 
             INNER JOIN sys.columns 
                     ON sys.objects.[object_id] = sys.columns.[object_id] 
                        AND sys.objects.[object_id] = @TABLE_ID; 

      SELECT @FINALSQL = @FINALSQL + 
			CASE
				WHEN sys.columns.[is_computed] = 1 
                THEN @vbCrLf + '[' + (sys.columns.[name]) + '] '
						+ Space(@STRINGLEN - Len(sys.columns.[name])) 
						+ ' NVARCHAR(max) NULL ' + '' 
				ELSE @vbCrLf + '[' + (sys.columns.[name]) + '] ' 
                         + Space(@STRINGLEN - Len(sys.columns.[name])) 
						 + Upper(Type_name(sys.columns.[user_type_id])) 
			+ CASE 
                WHEN Type_name(sys.columns.[user_type_id]) IN ('decimal', 'numeric') 
				THEN '(' + CONVERT(VARCHAR, sys.columns.[precision]) + ',' 
						+ CONVERT(VARCHAR,sys.columns.[scale]) + 
					') ' + Space(6 - Len(CONVERT(VARCHAR, sys.columns.[precision]) + ','
						+ CONVERT(VARCHAR, sys.columns.[scale]))) + Space(2) 
				-- + SPACE(16 - LEN(TYPE_NAME(sys.columns.[user_type_id])))  
            + CASE 
				WHEN Columnproperty ( @TABLE_ID, sys.columns.[name], 'IsIdentity' ) = 0 
				THEN '      ' 
				ELSE '      '--' IDENTITY(' + CONVERT(VARCHAR, Isnull(Ident_seed(@TBLNAME), 1)) + ',' + 
					--CONVERT(VARCHAR, Isnull(Ident_incr(@TBLNAME), 1)) + ')'
			END 
			+ CASE 
				WHEN sys.columns.[is_nullable] = 0 
					THEN '  NULL' 
					ELSE '  NULL'
			END 
						WHEN Type_name(sys.columns.[user_type_id]) IN ('float', 'real') 
							THEN 
								CASE 
									WHEN sys.columns.[precision] = 53 THEN Space(11 - Len(CONVERT(VARCHAR, sys.columns.[precision]))) 
										+ Space(7) + Space(16 - Len(Type_name(sys.columns.[user_type_id])))
								+ CASE 
									WHEN sys.columns.[is_nullable] = 0 
										THEN '  NULL' 
										ELSE '  NULL' 
								END 
							ELSE '(' + CONVERT(VARCHAR, sys.columns.[precision]) + ') ' 
									+ Space(6 - Len(CONVERT(VARCHAR, sys.columns.[precision]))) + Space(7)
									+ Space(16 - Len(Type_name(sys.columns.[user_type_id]))) 
							+ CASE 
							WHEN sys.columns.[is_nullable] = 0 THEN '  NULL' 
							ELSE '   NULL'
							END 
                         END 
						 WHEN Type_name(sys.columns.[user_type_id]) IN ('char', 'varchar') 
						 THEN 
							CASE WHEN sys.columns.[max_length] = -1 
									THEN '(max)' + Space(6 - Len(CONVERT(VARCHAR, sys.columns.[max_length]))) 
										+ Space(7) + Space(16 - Len(Type_name(sys.columns.[user_type_id]))) 
							+ CASE WHEN sys.columns.[is_nullable] = 0 THEN '  NULL' 
									ELSE '   NULL'
									END 
							ELSE '(' + CONVERT(VARCHAR, sys.columns.[max_length]) + ') ' 
								 + Space(6 - Len(CONVERT(VARCHAR, sys.columns.[max_length]))) 
								 + Space(7) + Space(16 - Len(Type_name(sys.columns.[user_type_id]))) 
                         + CASE WHEN sys.columns.[is_nullable] = 0 THEN '  NULL' 
								 ELSE '   NULL' 
								 END
							END WHEN Type_name(sys.columns.[user_type_id]) IN ('nchar', 'nvarchar') 
							THEN 
							CASE WHEN sys.columns.[max_length] = -1 THEN '(max)' 
									+ Space (6 - Len(CONVERT(VARCHAR, (sys.columns.[max_length])))) 
									+ Space(7) + Space(16 - Len(Type_name(sys.columns.[user_type_id]))) 
						   + CASE WHEN sys.columns.[is_nullable] = 0 
								THEN '  NULL'
								ELSE '  NULL' 
								END ELSE '(' + CONVERT(VARCHAR, (sys.columns.[max_length])) + ') '
								+ Space(6 - Len(CONVERT(VARCHAR, (sys.columns.[max_length])))) + Space(7)
								+ Space(16 - Len(Type_name(sys.columns.[user_type_id])))
							+ CASE WHEN sys.columns.[is_nullable] = 0 
								THEN '  NULL' 
								ELSE '  NULL' 
								END 
						END WHEN Type_name(sys.columns.[user_type_id]) IN ('datetime', 'money', 'text', 'image') 
							THEN Space(18 - Len(Type_name(sys.columns.[user_type_id]))) + '              '
						+ CASE WHEN sys.columns.[is_nullable] = 0 
						THEN '  NULL' 
						ELSE '  NULL' 
						END 
						ELSE Space(16 - Len(Type_name(sys.columns.[user_type_id]))) + Space(2) 
						+ CASE WHEN sys.columns.[is_nullable] = 0 
							THEN '  NULL' 
							ELSE '  NULL' 
							END 
						END        
				END --iscomputed         
		+ ',' 
		FROM   sys.columns 
		WHERE  sys.columns.[object_id] = @TABLE_ID 
		ORDER  BY sys.columns.[column_id] 

SELECT @STRINGLEN = Max(Len([name])) + 1 
FROM   sys.objects 



SET @FINALSQL = Substring(@FINALSQL, 1, Len(@FINALSQL) - 1); 
SET @FINALSQL = @FINALSQL + 
'
	,[AuditDateTime] [datetime]  NULL,
	[AuditEvent] CHAR(1)  NULL,
	[IsDeleted] [bit]  NULL' +
')' + @vbCrLf; 

SET @outputDDlScript = @FINALSQL
END 