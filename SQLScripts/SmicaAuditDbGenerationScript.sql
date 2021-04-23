
DECLARE @SmicaTables TABLE (name NVARCHAR(max));
DECLARE @SmicaColumns TABLE (name NVARCHAR(max));
DECLARE @tablename SYSNAME,
		@trailTableId int,
		@smicaTableId int,
		@triggerSql NVARCHAR(MAX) = '',
		@columns NVARCHAR(MAX) = '',
		@NewTableDDlScript NVARCHAR(max),
		@newTableName NVARCHAR(max);
       
INSERT INTO @SmicaTables SELECT name FROM SMICADB.sys.tables WHERE type = 'U' AND name NOT IN ('__EFMigrationsHistory', 'Mailings') --AND name = 'AnswerOptionIndicators' --add mailing tables;

DECLARE cur CURSOR 
FOR SELECT name FROM @SmicaTables
OPEN cur
FETCH NEXT FROM cur INTO @tablename

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @trailTableId = object_id FROM SmicaAuditTrail.sys.tables WHERE name = @tablename;
	SELECT @smicaTableId = object_id FROM SMICADB.sys.tables WHERE name = @tablename;
	
	IF NOT EXISTS (SELECT * FROM SmicaAuditTrail.sys.objects AS sat WHERE sat.name = @tablename AND sat.type='U')
		BEGIN
			exec SMICADB.dbo.[Sp_getTableDDL] @TBL = @tablename, @outputDDlScript = @NewTableDDlScript OUT
			print('Generated a DDL script for not existing table: ' +@NewTableDDlScript)
            USE SmicaAuditTrail;
			EXEC(@NewTableDDlScript)
		END
	ELSE 
		BEGIN 
			/*rename the current database as (tbname (currentDate)) if the columns and column types are different and create a new table with new columns;*/
			DELETE FROM @SmicaColumns;
			INSERT INTO @SmicaColumns SELECT Concat(name, system_type_id) FROM SMICADB.sys.columns WHERE object_id = @smicaTableId;			
			IF EXISTS ((SELECT * FROM @SmicaColumns 
							EXCEPT
						SELECT Concat(ac.name,ac.system_type_id) FROM SmicaAuditTrail.sys.columns as ac
								WHERE ac.object_id = @trailTableId AND ac.name NOT IN ('AuditDateTime','AuditEvent','IsDeleted'))
						UNION ALL
						(SELECT Concat(ac.name,ac.system_type_id) FROM SmicaAuditTrail.sys.columns as ac
							WHERE ac.object_id = @trailTableId AND ac.name NOT IN ('AuditDateTime','AuditEvent','IsDeleted')
						EXCEPT
						SELECT * FROM @SmicaColumns))
				BEGIN
					SELECT @newTableName = Convert(varchar, @tablename)+ ' ' + Convert(varchar, FORMAT(GetDate(), 'dd/MM/yyyy hh:mm:ss'))
					USE SmicaAuditTrail;
					EXEC sp_rename @tablename, @newTableName;
					EXEC SMICADB.dbo.[Sp_getTableDDL] @TBL = @tablename, @outputDDlScript = @NewTableDDlScript OUT					
					EXEC(@NewTableDDlScript)
				END;
	    END;
	--GENERATE TRIGGERS	
    SELECT @columns = STRING_AGG(QUOTENAME(name), ',')
    FROM SMICADB.sys.columns
    WHERE object_id = @smicaTableId;
    EXEC SMICADB.dbo.[SP_GenerateAuditDbTriggers] @tablename = @tablename, @columns = @columns
    	
	FETCH NEXT FROM cur INTO @tablename
END;
CLOSE cur;
DEALLOCATE cur;