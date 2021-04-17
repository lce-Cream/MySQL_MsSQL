USE AdventureWorks2012;
select * from HumanResources.Employee;
select * from HumanResources.Department;
select * from HumanResources.EmployeeDepartmentHistory;
select * from HumanResources.Shift;
select * from Person.Person;

--2.1.1|������� �� ����� ����� ������ ���� ������ ������ ���������� � ������ ������. ���� ������� ��� ������� ������
select dep.Name, min(emp.HireDate) StartDate
from HumanResources.employee emp
join HumanResources.EmployeeDepartmentHistory edh on emp.BusinessEntityID = edh.BusinessEntityID
join HumanResources.Department dep on dep.DepartmentID = edh.DepartmentID
group by dep.Name;

--2.1.2|������� �� ����� �������� ����� �����������, ���������� �� ������� �Stocker�.
--	  �������� �������� ���� ������� (Day � 1; Evening � 2; Night � 3).
select emp.BusinessEntityID, JobTitle, ShiftID ShiftName
from HumanResources.Employee emp
join HumanResources.EmployeeDepartmentHistory edh on emp.BusinessEntityID = edh.BusinessEntityID
where emp.JobTitle = 'Stocker';

--2.1.3|������� �� ����� ���������� ��� ���� �����������, � ��������� ������, � ������� ��� �������� ���������� ������.
--		� �������� ������� ������� ���������� �������� ����� �and� ������ &(���������).
select emp.BusinessEntityID, replace(JobTitle, 'and', '&') JobTitle, GroupName
from HumanResources.Employee emp
join HumanResources.EmployeeDepartmentHistory edh on emp.BusinessEntityID = edh.BusinessEntityID
join HumanResources.Department dep on edh.DepartmentID = dep.DepartmentID

--2.2|a)�������� ������� dbo.Person � ����� �� ���������� ��� Person.Person, ����� ����� xml,uniqueidentifier,
--		�� ������� �������, ����������� � ��������;
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

-- b)��������� ���������� ALTER TABLE,
--	 �������� ��� ������� dbo.Person ��������� ������������� �� ����� BusinessEntityID � PersonType;
alter table Person add primary key (BusinessEntityID, PersonType);

-- c)��������� ���������� ALTER TABLE, �������� ��� ������� dbo.Person ����������� ��� ���� PersonType,
--	 ����� ��������� ��� ����� ���� ������ ���������� �� ������ �GC�,�SP�,�EM�,�IN�,�VC�,�SC�;
select * from Person.Person pp where pp.PersonType not in ('GC','SP','EM','IN','V','SC');

alter table Person add check (PersonType IN ('GC','SP','EM','IN','V','SC'));
insert into Person values(1, 'SP', 3, 4, 5, 6, 7, 8, 9, 0);

-- d)��������� ���������� ALTER TABLE, �������� ��� ������� dbo.Person ����������� DEFAULT ��� ���� Title,
--	 ������� �������� �� ��������� �n/a�;
alter table Person add default 'n/a' for Title;

-- e)��������� ������� dbo.Person ������� �� Person.Person ������ ��� ��� ���,
--	 ��� ������� ��� �������� � ������� ContactType ��������� ��� �Owner�. ���� Title ��������� ���������� �� ���������; 
select * from Person.ContactType ct where ct.Name = 'Owner';

insert into Person
select pp.BusinessEntityID, PersonType, NameStyle,
	   Title, FirstName, MiddleName, LastName, Suffix,
	   EmailPromotion, pp.ModifiedDate
from Person.Person pp
join Person.BusinessEntityContact bec on bec.BusinessEntityID = pp.BusinessEntityID
join Person.ContactType ct on ct.ContactTypeID = bec.ContactTypeID
where ct.Name = 'Owner' and pp.PersonType in ('GC','SP','EM','IN','V','SC');

-- f)�������� ����������� ���� Title, ��������� ������ ���� �� 4-�� ��������,
--	 ����� ��������� ��������� null �������� ��� ����� ����.
alter table Person drop constraint DF__Person__Title__4DB4832C;
alter table Person alter column Title varchar(4) not null;

-- 3.1
-- a)�������� � ������� dbo.Person ���� EmailAddress ���� nvarchar ������������ 50 ��������;
alter table Person add EmailAddress nvarchar(50);

-- b)�������� ��������� ���������� � ����� �� ���������� ��� dbo.Person � ��������� �� ������� �� dbo.Person.
--	 ���� EmailAddress ��������� ������� �� Person.EmailAddress;
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

-- c)�������� ���� EmailAddress � dbo.Person ������� �� ��������� ����������, ����� �� ������ ���������������� ����;
update Person set EmailAddress = replace(EmailAddress, '0', '');

-- d)������� ������ �� dbo.Person, ��� ������� ��� �������� � ������� PhoneNumberType ����� �Work�;
delete p
from Person p
join Person.PersonPhone pp on pp.BusinessEntityID = p.BusinessEntityID
join Person.PhoneNumberType pnt on pnt.PhoneNumberTypeID = pp.PhoneNumberTypeID
where Name = 'Work';

-- e)������� ���� EmailAddress �� �������, ������� ��� ��������� ����������� � �������� �����������.
--	 ����� ����������� �� ������ ����� � ����������.
--   ����� �������� �� ��������� ������� ��������������, ��������� ���, ������� ������������ ��� ������;
select * from AdventureWorks2012.INFORMATIon_SCHEMA.ConSTRAINT_TABLE_USAGE
where TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Person';

alter table Person drop constraint PK__Person__156BFFF9D43B50FE, CK__Person__PersonTy__4CC05EF3;

-- f)������� ������� dbo.Person
drop table Person;

-- 3.2
-- a)��������� ���, ��������� �� ������ ������� ������ ������������ ������.
--	 �������� � ������� dbo.Person ���� TotalGroupSales MonEY � SalesYTD MonEY.
--	 ����� �������� � ������� ����������� ���� RoundSales, ����������� �������� � ���� SalesYTD �� ������ �����. 
alter table Person add TotalGroupSales MonEY,
					   SalesYDT MonEY,
					   RoundSales as round(SalesYDT, 1);
-- b)�������� ��������� ������� #Person, � ��������� ������ �� ���� BusinessEntityID.
--	 ��������� ������� ������ �������� ��� ���� ������� dbo.Person �� ����������� ���� RoundSales. 
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

-- c)��������� ��������� ������� ������� �� dbo.Person. ���� SalesYTD ��������� ���������� �� ������� Sales.SalesTerritory. 
--	 ���������� ����� ����� ������ (SalesYTD) ��� ������ ������ ���������� (Group) � ������� Sales.SalesTerritory
--	 � ��������� ����� ���������� ���� TotalGroupSales. ������� ����� ������ ����������� � Common Table Expression (CTE). 
use AdventureWorks2012
insert into #Person
select p.BusinessEntityID, p.PersonType, p.NameStyle, p.FirstName, p.MiddleName,
	   p.LastName, p.Suffix, p.EmailPromotion, p.ModifiedDate,
	   sum(st.SalesYTD) over(partition by st.Group) as TotalGroupSales,
	   st.SalesYTD
from Person p
join Sales.SalesPerson sp on sp.BusinessEntityID = p.BusinessEntityID
join Sales.SalesTerritory st on st.TerritoryID = sp.TerritoryID;

-- d)������� �� ������� dbo.Person ������, ��� EmailPromotion = 2 
delete from Person where EmailPromotion = 2;

-- e)�������� Merge ���������, ������������ dbo.Person ��� target, � ��������� ������� ��� source. 
--   ��� ����� target � source ����������� BusinessEntityID. �������� ���� TotalGroupSales � SalesYTD, 
--   ���� ������ ������������ � source � target. ���� ������ ������������ �� ��������� �������, �� �� ���������� � target, 
--   �������� ������ � dbo.Person. ���� � dbo.Person ������������ ����� ������, ������� �� ���������� �� ��������� �������, 
--   ������� ������ �� dbo.Person.
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
