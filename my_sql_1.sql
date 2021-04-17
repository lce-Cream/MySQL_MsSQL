create database base;
use base;

create table manuf(
IDM int,
nam varchar(32),
City varchar(32),
primary key(IDM)
);

create table cpu(
IDC int,
IDM int,
nam varchar(32),
Clock float,
primary key(IDC)
);

create table hdisk(
IDD int,
IDM int,
nam varchar(32),
Typ varchar(32),
Size int,
primary key(IDD)
);

create table nb(
IDN int,
IDM int,
nam varchar(32),
IDC int,
IDD int,
primary key(IDN)
);

create table phone(
IDP int,
IDM int,
Numb int,
Managername varchar(32),
primary key(IDP)
);

insert into manuf values 
(1, 'Intel', 'Santa Clara'), 
(2, 'AMD', 'Santa Clara'), 
(3, 'WD', 'San Jose'), 
(4, 'seagete', 'Cupertino'), 
(5, 'Asus', 'Taipei'), 
(6, 'Dell','Round Rock');

insert into CPU values 
(1, 1, 'i5', 3.2),
(2, 1, 'i7', 4.7),
(3, 2, 'Ryzen 5', 3.2),
(4, 2, 'Ryzen 7', 4.7),
(5, null, 'Power9', 3.5);

insert into hdisk values 
(1, 3, 'Green', 'hdd', 1000),
(2, 3, 'Black', 'ssd', 256),
(3, 1, '6000p', 'ssd', 256),
(4, 1, 'Optane', 'ssd', 16);

insert into nb values 
(1, 5, 'Zenbook', 2, 2),
(2, 6, 'XPS', 2, 2),
(3, 9, 'Pavilion', 2, 2),
(4, 6, 'Inspiron', 3, 4),
(5, 5, 'Vivobook', 1, 1),
(6, 6, 'XPS', 4, 1);

-- 4. Заполнить таблицу Phone произвольными данными.

-- 5. Написать запросы чтобы вывести данные: 

-- +5.1	Название фирмы и модель диска (Список не должен содержать значений NULL)
-- ----------------------------------------------------------------------
-- Решение:
SELECT hdisk.nam AS 'DiskName', manuf.nam AS 'FirmName'
FROM hdisk
JOIN manuf ON hdisk.idm = manuf.idm;

-- +5.2	Модель процессора и, если есть информация в БД, название фирмы;
-- ----------------------------------------------------------------------
-- Решение:
SELECT  manuf.nam AS 'FirmName', cpu.nam AS 'CPUname'
FROM cpu
LEFT JOIN manuf ON manuf.idm = cpu.idm;

-- ----------------------------------------------------------------------
-- +5.3	Название фирмы, которая производить несколько типов товара;
-- ----------------------------------------------------------------------
-- Решение:
SELECT DISTINCT m.nam AS 'FirmName' FROM manuf m, cpu c, hdisk h, nb n
WHERE
(m.idm=h.idm and m.idm=n.idm) or (m.idm=h.idm and m.idm=c.idm) or (m.idm=n.idm and m.idm=c.idm);


-- ----------------------------------------------------------------------
-- +5.4	Модели ноутбуков без информации в базе данных о фирме изготовителе;
-- ----------------------------------------------------------------------
-- Решение:
SELECT nb.nam 'NBname', manuf.idm
FROM nb
LEFT JOIN manuf ON manuf.idm is null;


-- ----------------------------------------------------------------------
-- +5.5 Модель ноутбука и название производителя ноутбука, название модели процессора, название модели диска.
-- ----------------------------------------------------------------------
-- Решение:
SELECT nb.nam 'NB Name', manuf.nam 'Manuf Name', cpu.nam 'Cpu Name', hdisk.nam 'Disk Name' from nb
left join manuf on nb.idm=manuf.idm
left join cpu on nb.idc=cpu.idc
left join hdisk on nb.idd=hdisk.idd;

-- ----------------------------------------------------------------------
-- +5.6	Модель ноутбука, фирму производителя ноутбука, а также для этой модели: 
-- 				модель и название фирмы производителя процессора,
-- 				модель и название фирмы производителя диска.
-- ----------------------------------------------------------------------
-- Решение:
SELECT nb.nam As 'NB Name', manuf.nam As 'Manuf Name', 
cpu.nam As 'CPU Name', cpu2.nam As 'CPU Manuf', hdisk.nam As 'Disk Name', hdisk2.nam As 'Disk Manuf'
FROM nb
LEFT JOIN manuf on manuf.IDM = nb.IDM
JOIN cpu on cpu.IDC = nb.IDC
JOIN hdisk on hdisk.IDD = nb.IDD
LEFT JOIN manuf as cpu2 on cpu2.IDM = cpu.IDM
LEFT JOIN manuf as hdisk2 on hdisk2.IDM = hdisk.IDM;

-- ----------------------------------------------------------------------
-- +5.7	 Абсолютно все названия фирмы и все модели процессоров 
-- ----------------------------------------------------------------------
-- Решение:
SELECT manuf.nam 'Manuf Name', cpu.nam 'CPU Name'
FROM manuf
RIGHT JOIN cpu ON manuf.idm = cpu.idm WHERE manuf.idm is NULL
UNION
SELECT manuf.nam, cpu.nam
FROM manuf
LEFT JOIN cpu ON manuf.idm = cpu.idm;

