-- 4.1
-- ������ � �������������� VIEW. ��������� ������ � ������� ����� �������������.
-- �������� AFTER DML �������� ��� �������. ������������ ��������� � history �������.

-- a) �������� ������� Person.PhoneNumberTypeHst, ������� ����� ������� ���������� �� ���������� � ������� Person.PhoneNumberType. 
--	  ������������ ����, ������� ������ �������������� � �������: ID � ��������� ���� IDENTITY(1,1); Action � ����������� �������� 
--    (insert, update ��� delete); ModifiedDate � ���� � �����, ����� ���� ��������� ��������; SourceID � ��������� ���� �������� �������; 
--    UserName � ��� ������������, ������������ ��������. �������� ������ ����, ���� �������� �� �������.
CREATE TABLE Person.PhoneNumberTypeHst
(
	ID INT PRIMARY KEY IDENTITY(1,1),
	Action VARCHAR(10) not null,
	ModifiedDate DATETIME not null,
	SourceID INT not null,
	UserName VARCHAR(20) not null
);
GO

-- b) �������� ��� AFTER �������� ��� ���� �������� INSERT, UPDATE, DELETE ��� ������� Person.PhoneNumberType. 
--	  ������ ������� ������ ��������� ������� Person.PhoneNumberTypeHst � ��������� ���� �������� � ���� Action.
CREATE TRIGGER OnInsert ON Person.PhoneNumberType
AFTER INSERT
AS
INSERT INTO Person.PhoneNumberTypeHst 
SELECT 'ins', GETDATE(), ins.PhoneNumberTypeID, CURRENT_USER FROM inserted ins
GO

CREATE TRIGGER OnUpdate ON Person.PhoneNumberType
AFTER UPDATE
AS
INSERT INTO Person.PhoneNumberTypeHst 
SELECT 'upd', GETDATE(), upd.PhoneNumberTypeID, CURRENT_USER FROM inserted upd
GO

CREATE TRIGGER OnDelete ON Person.PhoneNumberType
AFTER DELETE
AS
INSERT INTO Person.PhoneNumberTypeHst 
SELECT 'del', GETDATE(), del.PhoneNumberTypeID, CURRENT_USER FROM deleted del
GO

-- c) �������� ������������� VIEW, ������������ ��� ���� ������� Person.PhoneNumberType. �������� ����������� �������� ��������� ���� 
--	  �������������.
CREATE VIEW View_PersonPhoneNumberType
WITH ENCRYPTION
AS
SELECT * FROM Person.PhoneNumberType;
GO
select * from View_PersonPhoneNumberType

-- d) �������� ����� ������ � Person.PhoneNumberType ����� �������������. �������� ����������� ������. ������� ����������� ������. 
--	  ���������, ��� ��� ��� �������� ���������� � Person.PhoneNumberTypeHst.
insert into View_PersonPhoneNumberType(Name, ModifiedDate)
values('other', GETDATE());

update View_PersonPhoneNumberType set Name='presonal'
where Name='other';

delete from View_PersonPhoneNumberType
where Name='personal';

select * from Person.PhoneNumberTypeHst;
GO

-- 4.2 ��������������� �������������. �������� AFTER DML �������� ��� �������������.

-- a) �������� ������������� VIEW, ������������ ������ �� ������ Person.PhoneNumberType � Person.PersonPhone. 
--	  �������� ���������� ���������� ������ � ������������� �� ����� PhoneNumberTypeID � BusinessEntityID.
CREATE VIEW View_PersonPersonPhone_PersonPhoneNumberType
WITH SCHEMABINDING
AS
SELECT pp.BusinessEntityID, pp.PhoneNumber, pp.PhoneNumberTypeID, pp.ModifiedDate as PersonModifiedDate, 
	   pnt.Name as TypeName, pnt.ModifiedDate as TypeModifiedDate
FROM Person.PersonPhone pp
JOIN Person.PhoneNumberType pnt on pnt.PhoneNumberTypeID = pp.PhoneNumberTypeID;
GO

CREATE UNIQUE CLUSTERED INDEX PhoneNumberTypeID_BusinessEntityID
ON View_PersonPersonPhone_PersonPhoneNumberType (PhoneNumberTypeID, BusinessEntityID);
select * from View_PersonPersonPhone_PersonPhoneNumberType;
GO

-- b) �������� ���� INSTEAD OF ������� ��� ������������� �� ��� �������� INSERT, UPDATE, DELETE. ������� ������ ��������� 
--	  ��������������� �������� � �������� Person.PhoneNumberType � Person.PersonPhone ��� ���������� BusinessEntityID.
CREATE TRIGGER insteadOfInsert
ON View_PersonPersonPhone_PersonPhoneNumberType
INSTEAD OF INSERT
AS
	INSERT INTO Person.PhoneNumberType(PhoneNumberTypeID, Name, ModifiedDate)
		SELECT PhoneNumberTypeID, TypeName, TypeModifiedDate
		FROM INSERTED;
	INSERT INTO Person.PersonPhone(BusinessEntityID, PhoneNumber, PhoneNumberTypeID, ModifiedDate)
		SELECT BusinessEntityID, PhoneNumber, PhoneNumberTypeID, PersonModifiedDate
		FROM INSERTED;
GO

CREATE TRIGGER insteadOfUpdate
ON View_PersonPersonPhone_PersonPhoneNumberType
INSTEAD OF UPDATE
AS
	UPDATE Person.PhoneNumberType SET Name=(select TypeName from INSERTED),
									  ModifiedDate=(select TypeModifiedDate from INSERTED)  
		WHERE PhoneNumberTypeID=(select PhoneNumberTypeID from INSERTED);

	UPDATE Person.PersonPhone SET PhoneNumber=(select PhoneNumber from INSERTED),
								  ModifiedDate=(select PersonModifiedDate from INSERTED),
								  PhoneNumberTypeID=(select PhoneNumberTypeID from INSERTED)
		WHERE BusinessEntityID=(select BusinessEntityID from inserted) and PhoneNumberTypeID=(select PhoneNumberTypeID from INSERTED);
GO

CREATE TRIGGER insteadOfDelete
ON View_PersonPersonPhone_PersonPhoneNumberType
INSTEAD OF DELETE
AS
	DELETE FROM Person.PersonPhone 
		WHERE BusinessEntityID=(select BusinessEntityID FROM DELETED) and
			  PhoneNumberTypeID=(select PhoneNumberTypeID from DELETED)
	DELETE FROM Person.PhoneNumberType
		WHERE PhoneNumberTypeID=(select PhoneNumberTypeID from DELETED);
GO

drop trigger insteadOfInsert, InsteadOfUpdate, InsteadOfDelete

-- c) �������� ����� ������ � �������������, ������ ����� ������ ��� PhoneNumberType � PersonPhone ��� ������������� BusinessEntityID 
--    (�������� 1). ������� ������ �������� ����� ������ � ������� Person.PhoneNumberType � Person.PersonPhone. �������� ����������� 
--    ������ ����� �������������. ������� ������.
insert into View_PersonPersonPhone_PersonPhoneNumberType
(BusinessEntityID, PhoneNumber, PhoneNumberTypeID, PersonModifiedDate, TypeName, TypeModifiedDate)
values (0, '01234', '1', GETDATE(), 'Cell',  (select ModifiedDate from Person.PhoneNumberType where Name='Cell'));
GO

UPDATE View_PersonPersonPhone_PersonPhoneNumberType SET PhoneNumber='0000' WHERE (BusinessEntityID=2 and PhoneNumberTypeID=1);
GO

DELETE FROM View_PersonPersonPhone_PersonPhoneNumberType WHERE (BusinessEntityID=2 and PhoneNumberTypeID=1);
GO

select * from Person.PhoneNumberType
select * from Person.PersonPhone
select * from View_PersonPersonPhone_PersonPhoneNumberType
GO
-- 5 ���������������� �������: scalar-valued, inline table-valued, multistatement table-valued. ��������� CROSS APPLY � OUTER APPLY 

-- �������� scalar-valued �������, ������� ����� ��������� � �������� �������� ��������� id ������ (Sales.SalesOrderHeader.SalesOrderID) 
-- � ���������� �������� ����� ��� ������ (����� �� ����� SubTotal, TaxAmt, Freight).

CREATE FUNCTION OrderSum(@id INT)
RETURNS INT AS
BEGIN
	DECLARE @RESULT DECIMAL
	SET @RESULT = (select SubTotal+TaxAmt+Freight from Sales.SalesOrderHeader soh where soh.SalesOrderID=@id)
	RETURN @RESULT
END
GO

select dbo.OrderSum(43659) as ordersum;
GO

-- �������� inline table-valued �������, ������� ����� ��������� � �������� �������� ��������� id ������
-- �� ������������ (Production.WorkOrder.WorkOrderID), � ���������� ������ ������ �� Production.WorkOrderRouting.

select * from Production.WorkOrder
select * from Production.WorkOrderRouting
GO

CREATE FUNCTION Details(@id INT)
RETURNS TABLE
AS
	RETURN (select * from Production.WorkOrderRouting wor where wor.WorkOrderID=@id)
GO

-- �������� ������� ��� ������� ������, �������� �������� CROSS APPLY.

SELECT * FROM Production.WorkOrder AS wo
CROSS APPLY Details(wo.WorkOrderID) AS wr;
GO

-- �������� ������� ��� ������� ������, �������� �������� OUTER APPLY.

SELECT * FROM Production.WorkOrder AS wo
OUTER APPLY Details(wo.WorkOrderID) AS wr;
GO

-- �������� ��������� inline table-valued �������, ������ �� multistatement table-valued (�������������� �������� ��� �������� ��� �������� inline table-valued �������).

CREATE FUNCTION DetailsMulti(@id INT)
RETURNS @routing TABLE
(
	WorkOrderID INT,
	ProductID INT,
	OperationSequence SMALLINT,
	LocationID SMALLINT,
	ScheduledStartDate DATETIME,
	ScheduledEndDate DATETIME,
	ActualStartDate DATETIME NULL,
	ActualEndDate DATETIME NULL,
	ActualResourceHrs DECIMAL(9, 4) NULL,
	PlannedCost MONEY,
	ActualCost MONEY NULL,
	ModifiedDate DATETIME
)
AS
BEGIN
	INSERT INTO @routing
	SELECT WorkOrderID, ProductID, OperationSequence, LocationID, ScheduledStartDate, ScheduledEndDate, 
		   ActualStartDate, ActualEndDate, ActualResourceHrs, PlannedCost, ActualCost, ModifiedDate 
	FROM Production.WorkOrderRouting  
	WHERE WorkOrderID = @id
	RETURN;
END
GO

select * from DetailsMulti(39)