-- Все решения должны быть оформлены в виде запросов, и записаны в этот текстовый файл (в том числе создание хранимых процедур, функций и т.д.).
-- Задания рекомендуется выполнять по порядку.
-- Задания **{} - выполнять по желанию.
-- Проверить таблицу BUBuy, для поля IDU значения должны быть не более 350, для поля IDB около 1500. Если наоборот то выполнить запрос:
-- ALTER TABLE bubuy CHANGE COLUMN IDU IDB INT, CHANGE COLUMN IDB IDU INT;

-- ??? - Что такое представление (VIEW). Для решения каких задач применяется VIEW?
-- ??? - Что такое триггер, для каких задач его можно применять, какие ограничения применения есть в MySQL?
	-- triggers are not permitted on views
	-- triggers are not activated by foreign key actions
-- ??? - Какие функции бывают в  MySQL, как их применять?

-- ----------------------------------------------------------------------------------------------------------------------------------------
/* 	№1 Создать таблицу для хранения просмотров книг зарегистрированными пользователями. BUView - состоит из двух полей IDB, IDU. 
	При создании таблицы прописать FOREIGN KEY */
-- Решение:
CREATE TABLE BUView (
    IDB INT,
    FOREIGN KEY (IDB)
        REFERENCES books (IDB),
    IDU INT,
    FOREIGN KEY (IDU)
        REFERENCES users (IDU)
);

-- ----------------------------------------------------------------------------------------------------------------------------------------
/*	№2 Создать таблицу для хранения закладок "BUMark", где пользователь может пометить страницу в купленной книге и оставить короткое 
	текстовое описание, важно также знать время создания закладки.		
    **{При создании таблицы прописать FOREIGN KEY к оптимальной таблице} */
-- Решение:
CREATE TABLE BUMark (
    username VARCHAR(10) PRIMARY KEY,
    IDB INT,
    FOREIGN KEY (IDB)
        REFERENCES books (IDB),
    mpage INT,
    mark VARCHAR(20),
    mtime DATETIME
);

-- ----------------------------------------------------------------------------------------------------------------------------------------
/*	№3 Создать хранимую процедуру для добавления записей в таблицу "BUMark".
	**{Предусмотреть защиту от появления ошибок при заполнения данных}*/
-- Решение:
delimiter //
create procedure add_mark
(username varchar(10), IDB int, mpage int, mark varchar(20), mtime DATETIME)
begin
insert into BUMark values(username, IDB, mpage, mark, mtime);
end //
delimiter ;
drop procedure add_mark;

-- ----------------------------------------------------------------------------------------------------------------------------------------
/*	№4 Добавить в таблицу "BUMark" по 3 записи для пользователей: 'Denis', 'Dunn', 'Dora'.*/
-- Решение:
call add_mark('Denis', 1, 1,'one', now());
call add_mark('Dunn', 2, 2, 'two', now());
call add_mark('Dora', 3, 3, 'three', now());
select * from BUMark;

-- ----------------------------------------------------------------------------------------------------------------------------------------
/*	№5 Для каждого покупателя посчитать скидку в зависимости от количества купленных книг:
	+------------------------+------+-------+-------+-------+-------+
	| Количество книг, более |	0   |	3	|	5	|	7	|	10	|
    +------------------------+------+-------+-------+-------+-------+
    | Скидка, %		    	 |	0	|	1	|	2	|	3	|	5	|
	+------------------------+------+-------+-------+-------+-------+
	Решение этой задачи должно быть таким, чтобы потом им можно было воспользоваться для подсчета стоимости при покупке книги.*/
-- Решение:
drop function discount;
delimiter //
create function discount(userid int) returns int
begin
return
(SELECT 
		CASE
			WHEN COUNT(*) > 0 AND COUNT(*) < 3 THEN 0
			WHEN COUNT(*) >= 3 AND COUNT(*) < 5 THEN 1
			WHEN COUNT(*) >= 5 AND COUNT(*) < 7 THEN 2
			WHEN COUNT(*) >= 7 AND COUNT(*) < 10 THEN 3
			else 5 end
			as discont
	FROM
		bubuy where idu = userid
);
end //
delimiter ;

SELECT 
    idb, title,
    idu, price,
    discount(idu) as 'discount%',
    ROUND(price * DISCOUNT(idu) / 100, 2) AS 'discount$',
    ROUND(price - price * DISCOUNT(idu) / 100, 2) AS total_price
FROM
    books,
    users
WHERE
    idb IN (1 , 5) AND idu IN (1 , 5);

-- ----------------------------------------------------------------------------------------------------------------------------------------
/*	№6 Создать представление, которое будет выводить список 10 самых покупаемых книг за предыдущий месяц 
(при одинаковом значении проданных книг, сортировать по алфавиту) */
-- Решение:
drop view vie;
CREATE VIEW vie AS
    SELECT 
        MONTH(datatime) AS month, COUNT(*) AS amount, books.title
    FROM
        BUBuy
            JOIN
        books USING (IDB)
    WHERE
        MONTH(datatime) = MONTH(CURRENT_DATE()) - 1
    GROUP BY MONTH(datatime) , IDB
    ORDER BY amount DESC , title
    LIMIT 10;

select * from vie;

-- ----------------------------------------------------------------------------------------------------------------------------------------
-- **{Сделать выборку по условию задачи №6 и добавить к решению нумерацию строк}
-- Решение:
set @i=0;
select *, @i:=@i+1 as num from vie;

-- ----------------------------------------------------------------------------------------------------------------------------------------
/*	№7 Написать хранимую процедуру. Для книг (если название и автор совпадает) вывести количество изданий, минимальную и максимальную стоимость. 
Отобразить только те записи, у которых есть несколько упоминаний.*/
-- Решение:
delimiter //
create procedure min_max_price()
begin
select title, nameA, count(*) as amount, min(price) as min_price, max(price) as max_price from books
join BA using (IDB)
group by title, nameA;
end //
delimiter ;
call min_max_price();

-- ----------------------------------------------------------------------------------------------------------------------------------------
/*	№8 Создать триггер который будет копировать исходную строку в "новую архивную таблицу" при редактирование данных в таблице "USERS".	*/
-- Решение:
CREATE TABLE users_archive(
    IDU INT,
    mail TEXT,
    login VARCHAR(30),
    pass VARCHAR(15)
); drop table users_archive;

delimiter //
create trigger `archive_user` BEFORE update ON users
for each row
begin
   INSERT INTO users_archive values(Old.IDU, Old.mail, Old.login, Old.pass);
end //
delimiter ;

drop trigger `archive_user`;
update users set pass=1001 where IDU=1;

select * from users_archive;

-- ----------------------------------------------------------------------------------------------------------------------------------------
/* №9 Написать хранимую процедуру. Какая книга или книги, самая популярная как первая купленная.*/
-- Решение:
delimiter //
create PROCEDURE most_pop_first()
begin
SELECT
    IDB, amount
FROM
    (SELECT 
        IDB, COUNT(*) AS amount
    FROM
        (SELECT 
        IDB, MIN(datatime)
    FROM
        BUBuy
    GROUP BY IDU) AS A
    GROUP BY A.IDB) AS B
WHERE
    amount = (SELECT 
            MAX(amount)
        FROM
            (SELECT 
                IDB, COUNT(*) AS amount
            FROM
                (SELECT 
                IDB, MIN(datatime)
            FROM
                BUBuy
            GROUP BY IDU) AS C
            GROUP BY C.IDB) AS D);
end //
delimiter ;

drop procedure most_pop_first;
call most_pop_first();

-- ----------------------------------------------------------------------------------------------------------------------------------------
/*	№10 Вывести пользователей которые не проявили никакой активности (не просматривали книги, ничего не покупали)*/
-- Решение:
SELECT 
    *
FROM
    users
WHERE
    IDU NOT IN (SELECT DISTINCT
            IDU
        FROM
            users
                JOIN
            BUBuy USING (IDU)
                JOIN
            BUView USING (IDU));

-- ----------------------------------------------------------------------------------------------------------------------------------------