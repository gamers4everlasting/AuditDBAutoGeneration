IF NOT EXISTS(SELECT * FROM master.sys.databases WHERE name = 'SmicaAuditTrail')
BEGIN 
		CREATE DATABASE SmicaAuditTrail
END