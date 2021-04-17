USE AdventureWorks2012;
select * from HumanResources.Employee;
select * from HumanResources.Department;
select * from HumanResources.EmployeeDepartmentHistory;
select * from HumanResources.Shift;
select * from Person.Person;

--2.1.1|Вывести на экран самую раннюю дату начала работы сотрудника в каждом отделе. Дату вывести для каждого отдела
select dep.Name, min(emp.HireDate) StartDate
from HumanResources.employee emp
join HumanResources.EmployeeDepartmentHistory edh on emp.BusinessEntityID = edh.BusinessEntityID
join HumanResources.Department dep on dep.DepartmentID = edh.DepartmentID
group by dep.Name;

--2.1.2|Вывести на экран название смены сотрудников, работающих на позиции ‘Stocker’.
--	  Замените названия смен цифрами (Day — 1; Evening — 2; Night — 3).
select emp.BusinessEntityID, JobTitle, ShiftID ShiftName
from HumanResources.Employee emp
join HumanResources.EmployeeDepartmentHistory edh on emp.BusinessEntityID = edh.BusinessEntityID
where emp.JobTitle = 'Stocker';

--2.1.3|Вывести на экран информацию обо всех сотрудниках, с указанием отдела, в котором они работают внастоящий момент.
--		В названии позиции каждого сотрудника заменить слово ‘and’ знаком &(амперсанд).
select emp.BusinessEntityID, replace(JobTitle, 'and', '&') JobTitle, GroupName
from HumanResources.Employee emp
join HumanResources.EmployeeDepartmentHistory edh on emp.BusinessEntityID = edh.BusinessEntityID
join HumanResources.Department dep on edh.DepartmentID = dep.DepartmentID

--2.2|a)создайте таблицу dbo.Person с такой же структурой как Person.Person, кроме полей xml,uniqueidentifier,
--		не включая индексы, ограничения и триггеры;
create table dbo.Person
(
	BusinessEntityID int NOT NULL,
	PersonType nchar(2) NOT NULL,
	NameStyle dbo.NameStyle NOT NULL,
	Title nvarchar(8) NULL,
	FirstName dbo.Name NOT NULL,
	MiddleName dbo.Name NULL,
	LastName dbo.Name NOT NULL,
	Suffix nvarchar(10) NULL,
	EmailPromotion int NOT NULL,
	ModifiedDate datetime NOT NULL
);

-- b)используя инструкцию ALTER TABLE,
--	 создайте для таблицы dbo.Person составной первичныйключ из полей BusinessEntityID и PersonType;
alter table Person add primary key (BusinessEntityID, PersonType);

-- c)используя инструкцию ALTER TABLE, создайте для таблицы dbo.Person ограничение для поля PersonType,
--	 чтобы заполнить его можно было только значениями из списка ‘GC’,’SP’,’EM’,’IN’,’VC’,’SC’;
select * from Person.Person pp where pp.PersonType not in ('GC','SP','EM','IN','V','SC');

alter table Person add check (PersonType IN ('GC','SP','EM','IN','V','SC'));
insert into Person values(1, 'SP', 3, 4, 5, 6, 7, 8, 9, 0);

-- d)используя инструкцию ALTER TABLE, создайте для таблицы dbo.Person ограничение DEFAULT для поля Title,
--	 задайте значение по умолчанию ‘n/a’;
alter table Person add default 'n/a' for Title;

-- e)заполните таблицу dbo.Person данными из Person.Person только для тех лиц,
--	 для которых тип контакта в таблице ContactType определен как ‘Owner’. Поле Title заполните значениями по умолчанию; 
select * from Person.ContactType ct where ct.Name = 'Owner';

insert into Person
select pp.BusinessEntityID, PersonType, NameStyle,
	   Title, FirstName, MiddleName, LastName, Suffix,
	   EmailPromotion, pp.ModifiedDate
from Person.Person pp
join Person.BusinessEntityContact bec on bec.BusinessEntityID = pp.BusinessEntityID
join Person.ContactType ct on ct.ContactTypeID = bec.ContactTypeID
where ct.Name = 'Owner' and pp.PersonType in ('GC','SP','EM','IN','V','SC');

-- f)измените размерность поля Title, уменьшите размер поля до 4-ти символов,
--	 также запретите добавлять null значения для этого поля.
alter table Person drop constraint DF__Person__Title__4DB4832C;
alter table Person alter column Title varchar(4) not null;

-- 3.1
-- a)добавьте в таблицу dbo.Person поле EmailAddress типа nvarchar размерностью 50 символов;
alter table Person add EmailAddress nvarchar(50);

-- b)объявите табличную переменную с такой же структурой как dbo.Person и заполните ее данными из dbo.Person.
--	 Поле EmailAddress заполните данными из Person.EmailAddress;
declare @Person table(
	BusinessEntityID int NOT NULL,
	PersonType nchar(2) NOT NULL,
	NameStyle dbo.NameStyle NOT NULL,
	Title nvarchar(8) NULL,
	FirstName dbo.Name NOT NULL,
	MiddleName dbo.Name NULL,
	LastName dbo.Name NOT NULL,
	Suffix nvarchar(10) NULL,
	EmailPromotion int NOT NULL,
	ModifiedDate datetime NOT NULL,
	EmailAddress nvarchar(50));

insert into @Person
select p.BusinessEntityID, PersonType, NameStyle, Title, FirstName, MiddleName,
	   LastName, Suffix, EmailPromotion, p.ModifiedDate, email.EmailAddress
from dbo.Person p
join Person.EmailAddress email on email.BusinessEntityID = p.BusinessEntityID;

select * from @Person;

-- c)обновите поле EmailAddress в dbo.Person данными из табличной переменной, убрав из адреса всевстречающиеся нули;
update Person set EmailAddress = replace(EmailAddress, '0', '');

-- d)удалите данные из dbo.Person, для которых тип контакта в таблице PhoneNumberType равен ‘Work’;
delete p
from Person p
join Person.PersonPhone pp on pp.BusinessEntityID = p.BusinessEntityID
join Person.PhoneNumberType pnt on pnt.PhoneNumberTypeID = pp.PhoneNumberTypeID
where Name = 'Work';

-- e)удалите поле EmailAddress из таблицы, удалите все созданные ограничения и значения поумолчанию.
--	 Имена ограничений вы можете найти в метаданных.
--   Имена значений по умолчанию найдите самостоятельно, приведите код, которым пользовались для поиска;
select * from AdventureWorks2012.INFORMATIon_SCHEMA.ConSTRAINT_TABLE_USAGE
where TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Person';

alter table Person drop constraint PK__Person__156BFFF9D43B50FE, CK__Person__PersonTy__4CC05EF3;

-- f)удалите таблицу dbo.Person
drop table Person;

-- 3.2
-- a)выполните код, созданный во втором задании второй лабораторной работы.
--	 Добавьте в таблицу dbo.Person поля TotalGroupSales MonEY и SalesYTD MonEY.
--	 Также создайте в таблице вычисляемое поле RoundSales, округляющее значение в поле SalesYTD до целого числа. 
alter table Person add TotalGroupSales MonEY,
					   SalesYDT MonEY,
					   RoundSales as round(SalesYDT, 1);
-- b)создайте временную таблицу #Person, с первичным ключом по полю BusinessEntityID.
--	 Временная таблица должна включать все поля таблицы dbo.Person за исключением поля RoundSales. 
use tempdb
create type NameStyle from bit NOT NULL
create type Name from nvarchar(50) NULL

create table #Person(
	BusinessEntityID int primary key NOT NULL,
	PersonType nchar(2) NOT NULL,
	NameStyle dbo.NameStyle NOT NULL,
	Title nvarchar(8) NULL,
	FirstName dbo.Name NOT NULL,
	MiddleName dbo.Name NULL,
	LastName dbo.Name NOT NULL,
	Suffix nvarchar(10) NULL,
	EmailPromotion int NOT NULL,
	ModifiedDate datetime NOT NULL,
	EmailAddress nvarchar(50),
	TotalGroupSales MonEY,
	SalesYDT MonEY);

-- c)заполните временную таблицу данными из dbo.Person. Поле SalesYTD заполните значениями из таблицы Sales.SalesTerritory. 
--	 Посчитайте общую сумму продаж (SalesYTD) для каждой группы территорий (Group) в таблице Sales.SalesTerritory
--	 и заполните этими значениями поле TotalGroupSales. Подсчет суммы продаж осуществите в Common Table Expression (CTE). 
use AdventureWorks2012
insert into #Person
select p.BusinessEntityID, p.PersonType, p.NameStyle, p.FirstName, p.MiddleName,
	   p.LastName, p.Suffix, p.EmailPromotion, p.ModifiedDate,
	   sum(st.SalesYTD) over(partition by st.Group) as TotalGroupSales,
	   st.SalesYTD
from Person p
join Sales.SalesPerson sp on sp.BusinessEntityID = p.BusinessEntityID
join Sales.SalesTerritory st on st.TerritoryID = sp.TerritoryID;

-- d)удалите из таблицы dbo.Person строки, где EmailPromotion = 2 
delete from Person where EmailPromotion = 2;

-- e)напишите Merge выражение, использующее dbo.Person как target, а временную таблицу как source. 
--   Для связи target и source используйте BusinessEntityID. Обновите поля TotalGroupSales и SalesYTD, 
--   если запись присутствует в source и target. Если строка присутствует во временной таблице, но не существует в target, 
--   добавьте строку в dbo.Person. Если в dbo.Person присутствует такая строка, которой не существует во временной таблице, 
--   удалите строку из dbo.Person.
merge Person Target_
using #Person Source_
on (Target_.BusinessEntityID = Source_.BusinessEntityID)
when MATCHED then update set TotalGroupSales = Source_.TotalGroupSales, SalesYTD = Source_.SalesYTD
when NOT MATCHED by TARGET then
		insert(BusinessEntityID, PersonType, NameStyle, FirstName, MiddleName,
			   LastName, Suffix, EmailPromotion, ModifiedDate, TotalGroupSales,SalesYTD)

		values(Source_.BusinessEntityID, Source_.PersonType, Source_.NameStyle, Source_.FirstName, Source_.MiddleName,
		       Source_.LastName, Source_.Suffix, Source_.EmailPromotion, Source_.ModifiedDate,
			   Source_.TotalGroupSales,Source_.SalesYTD)
when NOT MATCHED by SOURCE then DELETE;
