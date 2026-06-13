/************************************************************
 Autor: Landry Duailibe

 Hands On: Views
*************************************************************/
use Aula
go

/***********************************
 Cria tabelas para o Hands On
************************************/
set nocount on

-- Tabela Customer
DROP TABLE IF exists dbo.Customer
go
CREATE TABLE dbo.Customer (
CustomerID int not null CONSTRAINT pk_Customer PRIMARY KEY, 
Title nvarchar(8) null, 
FirstName nvarchar(50) null, 
MiddleName nvarchar(50) null, 
LastName nvarchar(50) null,
[Name] nvarchar(160) null,
Excluido bit not null DEFAULT (0)) 
go

-- Carrega linhas a partir do AdventureWorks
INSERT dbo.Customer (CustomerID, Title, FirstName, MiddleName, LastName, [Name])
SELECT c.CustomerID, Title, FirstName, MiddleName, LastName, FirstName + isnull(' ' + MiddleName,'') + isnull(' ' + LastName,'') as [Name]
FROM AdventureWorks.Sales.Customer c
JOIN AdventureWorks.Person.Person p on p.BusinessEntityID = c.PersonID
go

-- Tabela SalesOrderHeader
DROP TABLE IF exists dbo.SalesOrderHeader
go
CREATE TABLE dbo.SalesOrderHeader(
SalesOrderID int NOT NULL identity CONSTRAINT pk_SalesOrderHeader PRIMARY KEY,
OrderDate datetime NOT NULL,
Status tinyint NOT NULL,
OnlineOrderFlag bit NOT NULL,
SalesOrderNumber char(200) NOT NULL,
CustomerID int NOT NULL,
SalesPersonID int NULL,
TerritoryID int NULL,
SubTotal money NOT NULL,
TaxAmt money NOT NULL,
Freight money NOT NULL,
TotalDue money NOT NULL,
Comment nvarchar(128) NULL)
go

-- Carrega linhas a partir do AdventureWorks
INSERT dbo.SalesOrderHeader (OrderDate, [Status], OnlineOrderFlag, SalesOrderNumber, CustomerID, SalesPersonID, TerritoryID, SubTotal, TaxAmt, Freight, TotalDue, Comment)
SELECT OrderDate, Status, OnlineOrderFlag, 
SalesOrderNumber, CustomerID, SalesPersonID, TerritoryID,  
SubTotal, TaxAmt, Freight, TotalDue, Comment
FROM AdventureWorks.Sales.SalesOrderHeader
go

set nocount off
/************************* FIM Prepara Hands On ******************************/


/******************************
 Hands On VIEW
*******************************/
-- Consulta completa
SELECT c.Name as Customer, h.SalesOrderID, h.OrderDate, h.TotalDue
FROM dbo.SalesOrderHeader h
JOIN dbo.Customer c on c.CustomerID = h.CustomerID
WHERE h.OrderDate >= '20140101' and h.OrderDate < '20150101'
ORDER BY h.TotalDue desc

go
CREATE or ALTER VIEW dbo.vw_CustomerOrder
AS
SELECT c.Name as Customer, h.SalesOrderID, h.OrderDate, h.TotalDue
FROM dbo.SalesOrderHeader h
JOIN dbo.Customer c on c.CustomerID = h.CustomerID
go

SELECT Customer, SalesOrderID, OrderDate, TotalDue
FROM dbo.vw_CustomerOrder
WHERE OrderDate >= '20140101' and OrderDate < '20150101'
ORDER BY TotalDue desc

-- Acessado a definição original da View
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.vw_CustomerOrder','V'))

EXEC sp_helptext 'dbo.vw_CustomerOrder'

-- Exclui a View
DROP VIEW dbo.vw_CustomerOrder
go

/***************************************
 Hands On STORED PROCEDURE
****************************************/
SELECT * FROM dbo.Customer

-- Stored Procedure para exclusão lógica
go
CREATE or ALTER PROC dbo.spu_Customer_DELETE
@CustomerID int 
as
set nocount on

UPDATE dbo.Customer SET Excluido = 1 
WHERE CustomerID = @CustomerID
go

-- Exclusão lógica de um Cliente
EXEC dbo.spu_Customer_DELETE @CustomerID = 11000

SELECT * FROM dbo.Customer
WHERE CustomerID = 11000

SELECT count(*) FROM dbo.Customer -- 19.119
WHERE Excluido = 0 -- 19118

-- Exclui Procedure
DROP PROC dbo.spu_Customer_DELETE

/***************************************
 Hands On FUNCTION
****************************************/

/*********************
 Função Escalar
*********************/
go
CREATE or ALTER FUNCTION dbo.UltimoDiaMesAnterior (@Data date)
RETURNS date
AS 
BEGIN
  RETURN dateadd(day, - DAY(@Data), @Data)
END
go

SELECT dbo.UltimoDiaMesAnterior(getdate()), getdate()
SELECT dbo.UltimoDiaMesAnterior('2017-01-01')

-- Exclui
DROP FUNCTION dbo.UltimoDiaMesAnterior

/*********************************
 Função Table-Valued
**********************************/
go
CREATE OR ALTER FUNCTION dbo.fnu_CustomerOrder_Day (@Data date)
RETURNS TABLE
AS 
RETURN (
SELECT c.Name as Customer, h.SalesOrderID, h.OrderDate, h.TotalDue
FROM dbo.SalesOrderHeader h
JOIN dbo.Customer c on c.CustomerID = h.CustomerID
WHERE h.OrderDate >= @Data and h.OrderDate < dateadd(dd,1,@Data))
go

SELECT * FROM dbo.fnu_CustomerOrder_Day('20140101')

-- Excclui Função
DROP FUNCTION dbo.fnu_CustomerOrder_Day



/***************************************
 Hands On TRIGGER
****************************************/

/*******************************
 Cria tabela para Auditoria
********************************/
DROP TABLE IF exists dbo.AuditCustomer
go
-- TRUNCATE TABLE dbo.AuditCustomer
CREATE TABLE dbo.AuditCustomer (
AuditCustomer_ID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
TipoAtualizacao varchar(20) NOT NULL,
UserLogin varchar(100) NULL,
Host varchar(100) NULL,
CustomerID int NOT NULL,
Title nvarchar(8) NULL,
FirstName nvarchar(50) NOT NULL,
MiddleName nvarchar(50) NULL,
Lastname nvarchar(50) NULL,
[Name] nvarchar(160) NULL,
Excluido bit NULL)
go
-- SELECT * FROM dbo.AuditCustomer

/*******************************
 Trigger INSERT/UPDATE
********************************/
-- DROP TRIGGER trg_Customer_Audit
go
CREATE or ALTER TRIGGER trg_Customer_Audit
ON dbo.Customer AFTER INSERT, UPDATE
as
set nocount on

DECLARE @TipoAtualizacao varchar(20)

IF exists (SELECT * FROM deleted)
	SET @TipoAtualizacao = 'UPDATE'
ELSE
	SET @TipoAtualizacao = 'INSERT'

INSERT dbo.AuditCustomer
(TipoAtualizacao, UserLogin, Host, 
CustomerID, Title, FirstName, MiddleName, Lastname, [Name], Excluido)

SELECT @TipoAtualizacao,system_user as UserLogin, host_name() as Host,
CustomerID, Title, FirstName, MiddleName, Lastname, [Name], Excluido
FROM Inserted
go

-- Executando alterações

SELECT * FROM dbo.Customer ORDER BY CustomerID desc

-- Provoca disparo da Trigger operação INSERT
INSERT dbo.Customer (CustomerID, Title, FirstName, MiddleName, Lastname, [Name], Excluido)
VALUES (90000,'Mr.','Jose','M.','da Silva','Jose M. da Silva',0)

-- Provoca disparo da Trigger operação UPDATE
UPDATE  dbo.Customer SET Title = 'Sr.'
WHERE CustomerID = 90000

-- Verifica tabela de Auditoria
SELECT * FROM dbo.Customer WHERE CustomerID = 90000

SELECT * FROM dbo.AuditCustomer


/******************
 Exclui Tabelas
*******************/
DROP TABLE IF exists dbo.Customer
DROP TABLE IF exists dbo.AuditCustomer
DROP TABLE IF exists dbo.SalesOrderHeader
