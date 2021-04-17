-- 4.1
-- Работа с представлением VIEW. Изменение данных в таблице через представление.
-- Создание AFTER DML триггера для таблицы. Логгирование изменений в history таблицу.

-- a) Создайте таблицу Person.PhoneNumberTypeHst, которая будет хранить информацию об изменениях в таблице Person.PhoneNumberType. 
--	  Обязательные поля, которые должны присутствовать в таблице: ID — первичный ключ IDENTITY(1,1); Action — совершенное действие 
--    (insert, update или delete); ModifiedDate — дата и время, когда была совершена операция; SourceID — первичный ключ исходной таблицы; 
--    UserName — имя пользователя, совершившего операцию. Создайте другие поля, если считаете их нужными.
CREATE TABLE Person.PhoneNumberTypeHst
(
	ID INT PRIMARY KEY IDENTITY(1,1),
	Action VARCHAR(10) not null,
	ModifiedDate DATETIME not null,
	SourceID INT not null,
	UserName VARCHAR(20) not null
);
GO

-- b) Создайте три AFTER триггера для трех операций INSERT, UPDATE, DELETE для таблицы Person.PhoneNumberType. 
--	  Каждый триггер должен заполнять таблицу Person.PhoneNumberTypeHst с указанием типа операции в поле Action.
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

-- c) Создайте представление VIEW, отображающее все поля таблицы Person.PhoneNumberType. Сделайте невозможным просмотр исходного кода 
--	  представления.
CREATE VIEW View_PersonPhoneNumberType
WITH ENCRYPTION
AS
SELECT * FROM Person.PhoneNumberType;
GO
select * from View_PersonPhoneNumberType

-- d) Вставьте новую строку в Person.PhoneNumberType через представление. Обновите вставленную строку. Удалите вставленную строку. 
--	  Убедитесь, что все три операции отображены в Person.PhoneNumberTypeHst.
insert into View_PersonPhoneNumberType(Name, ModifiedDate)
values('other', GETDATE());

update View_PersonPhoneNumberType set Name='presonal'
where Name='other';

delete from View_PersonPhoneNumberType
where Name='personal';

select * from Person.PhoneNumberTypeHst;
GO

-- 4.2 Индексированное представление. Создание AFTER DML триггера для представления.

-- a) Создайте представление VIEW, отображающее данные из таблиц Person.PhoneNumberType и Person.PersonPhone. 
--	  Создайте уникальный кластерный индекс в представлении по полям PhoneNumberTypeID и BusinessEntityID.
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

-- b) Создайте один INSTEAD OF триггер для представления на три операции INSERT, UPDATE, DELETE. Триггер должен выполнять 
--	  соответствующие операции в таблицах Person.PhoneNumberType и Person.PersonPhone для указанного BusinessEntityID.
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

-- c) Вставьте новую строку в представление, указав новые данные для PhoneNumberType и PersonPhone для существующего BusinessEntityID 
--    (например 1). Триггер должен добавить новые строки в таблицы Person.PhoneNumberType и Person.PersonPhone. Обновите вставленные 
--    строки через представление. Удалите строки.
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
-- 5 Пользовательские функции: scalar-valued, inline table-valued, multistatement table-valued. Операторы CROSS APPLY и OUTER APPLY 

-- Создайте scalar-valued функцию, которая будет принимать в качестве входного параметра id заказа (Sales.SalesOrderHeader.SalesOrderID) 
-- и возвращать итоговую сумму для заказа (сумма по полям SubTotal, TaxAmt, Freight).

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

-- Создайте inline table-valued функцию, которая будет принимать в качестве входного параметра id заказа
-- на производство (Production.WorkOrder.WorkOrderID), а возвращать детали заказа из Production.WorkOrderRouting.

select * from Production.WorkOrder
select * from Production.WorkOrderRouting
GO

CREATE FUNCTION Details(@id INT)
RETURNS TABLE
AS
	RETURN (select * from Production.WorkOrderRouting wor where wor.WorkOrderID=@id)
GO

-- Вызовите функцию для каждого заказа, применив оператор CROSS APPLY.

SELECT * FROM Production.WorkOrder AS wo
CROSS APPLY Details(wo.WorkOrderID) AS wr;
GO

-- Вызовите функцию для каждого заказа, применив оператор OUTER APPLY.

SELECT * FROM Production.WorkOrder AS wo
OUTER APPLY Details(wo.WorkOrderID) AS wr;
GO

-- Измените созданную inline table-valued функцию, сделав ее multistatement table-valued (предварительно сохранив для проверки код создания inline table-valued функции).

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