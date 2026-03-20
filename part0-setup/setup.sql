-- =============================================
-- Phase 0: Environment Setup
-- WWI_DM Database Creation + WideWorldImporters Restore
-- =============================================

-- Step 1: Create the Data Mart database
CREATE DATABASE WWI_DM;
GO

-- Step 2: Restore WideWorldImporters (OLTP source)
-- Download: https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
-- File: WideWorldImporters-Full.bak
--
-- RESTORE DATABASE WideWorldImporters
-- FROM DISK = N'C:\path\to\WideWorldImporters-Full.bak'
-- WITH MOVE 'WWI_Primary' TO N'C:\...\WideWorldImporters.mdf',
--      MOVE 'WWI_UserData' TO N'C:\...\WideWorldImporters_UserData.ndf',
--      MOVE 'WWI_Log' TO N'C:\...\WideWorldImporters.ldf',
--      MOVE 'WWI_InMemory_Data_1' TO N'C:\...\WideWorldImporters_InMemory_Data_1',
--      REPLACE;
-- GO

-- Step 3: Verify both databases exist
SELECT name, state_desc
FROM sys.databases
WHERE name IN ('WideWorldImporters', 'WWI_DM');
GO
