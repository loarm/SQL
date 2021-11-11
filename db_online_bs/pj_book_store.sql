/* Вывести все заказы Баранова Павла (id заказа, какие книги, по какой цене и в каком количестве он заказал) 
в отсортированном по номеру заказа и названиям книг виде.*/

SELECT buy_id, title, price, buy_book.amount 
FROM book
    JOIN buy_book USING(book_id)
    JOIN buy USING(buy_id)
    JOIN client USING(client_id)
WHERE client_id = 1
ORDER BY buy_id, title;


/* Посчитать, сколько раз была заказана каждая книга, для книги вывести ее автора (нужно посчитать, 
в каком количестве заказов фигурирует каждая книга).  
Вывести фамилию и инициалы автора, название книги, последний столбец назвать Количество. 
Результат отсортировать сначала  по фамилиям авторов, а потом по названиям книг. */

SELECT name_author, title, COUNT(buy_book.book_id) AS "Количество"
FROM author
    JOIN book USING(author_id)
    LEFT JOIN buy_book USING(book_id)
GROUP BY book_id
ORDER BY name_author, title;


/* Вывести города, в которых живут клиенты, оформлявшие заказы в интернет-магазине. 
Указать количество заказов в каждый город, этот столбец назвать Количество. 
Информацию вывести по убыванию количества заказов, а затем в алфавитном порядке по названию городов. */

SELECT name_city, COUNT(city_id) AS "Количество"
FROM city
    JOIN client USING(city_id)
    JOIN buy USING(client_id)
GROUP BY city_id
ORDER BY Количество DESC;


/* Вывести номера всех оплаченных заказов и даты, когда они были оплачены. */

SELECT buy_id, date_step_end
FROM buy_step JOIN step USING(step_id)
WHERE step_id = 1 AND date_step_end IS NOT NULL;


/* Вывести информацию о каждом заказе: его номер, кто его сформировал (фамилия пользователя) и его стоимость 
(сумма произведений количества заказанных книг и их цены), в отсортированном по номеру заказа виде. 
Последний столбец назвать Стоимость. */

SELECT buy_id, name_client, SUM(price * buy_book.amount) AS "Стоимость"
FROM book
    JOIN buy_book USING(book_id)
    JOIN buy USING(buy_id)
    JOIN client USING(client_id)
GROUP BY buy_id
ORDER BY buy_id;


/* Вывести номера заказов (buy_id) и названия этапов, на которых они в данный момент находятся. 
Если заказ доставлен –  информацию о нем не выводить. Информацию отсортировать по возрастанию buy_id.*/

SELECT buy_id, name_step
FROM buy_step JOIN step USING(step_id)
WHERE date_step_beg IS NOT NULL AND date_step_end IS NULL
ORDER BY buy_id;


/* В таблице city для каждого города указано количество дней, 
за которые заказ может быть доставлен в этот город (рассматривается только этап "Транспортировка"). 
Для тех заказов, которые прошли этап транспортировки, вывести количество дней за которое заказ реально доставлен в город. 
А также, если заказ доставлен с опозданием, указать количество дней задержки, в противном случае вывести 0. 
В результат включить номер заказа (buy_id), а также вычисляемые столбцы Количество_дней и Опоздание. 
Информацию вывести в отсортированном по номеру заказа виде.*/

SELECT buy_id, DATEDIFF(date_step_end, date_step_beg) AS "Количество_дней", GREATEST((SELECT Количество_дней) - days_delivery, 0) AS Опоздание
FROM city
    JOIN client USING(city_id)
    JOIN buy USING(client_id)
    JOIN buy_step USING(buy_id)
    JOIN step USING(step_id)
WHERE step_id = 3 AND date_step_end IS NOT NULL
ORDER BY buy_id;


/* Выбрать всех клиентов, которые заказывали книги Достоевского, информацию вывести в отсортированном по алфавиту виде.*/

SELECT DISTINCT name_client
FROM client
    JOIN buy USING(client_id)
    JOIN buy_book USING(buy_id)
    JOIN book USING(book_id)
    JOIN author USING(author_id)
WHERE name_author LIKE "Достоевский_%"    
ORDER BY name_client;


/* Вывести жанр (или жанры), в котором было заказано больше всего экземпляров книг, указать это количество . 
Последний столбец назвать Количество.*/

SELECT name_genre, SUM(buy_book.amount) AS "Количество"
FROM buy_book
    JOIN book USING(book_id)
    JOIN genre USING(genre_id)
GROUP BY name_genre
HAVING Количество IN(SELECT MAX(sum_amount)
                     FROM (SELECT SUM(buy_book.amount) AS sum_amount
                           FROM buy_book
                               JOIN book USING(book_id)
                               JOIN genre USING(genre_id)
                           GROUP BY name_genre) query_in
                     );


/* Сравнить ежемесячную выручку от продажи книг за текущий и предыдущий годы. 
Для этого вывести год, месяц, сумму выручки в отсортированном сначала по возрастанию месяцев, 
затем по возрастанию лет виде. 
Название столбцов: Год, Месяц, Сумма.*/

SELECT YEAR(date_payment) AS "Год", MONTHNAME(date_payment) AS "Месяц", SUM(price * amount) AS "Сумма"
FROM buy_archive
GROUP BY 1, 2
UNION 
SELECT YEAR(date_step_end) AS "Год", MONTHNAME(date_step_end) AS "Месяц", SUM(price * buy_book.amount) AS "Сумма"
FROM book 
    INNER JOIN buy_book USING(book_id)
    INNER JOIN buy USING(buy_id) 
    INNER JOIN buy_step USING(buy_id)
    INNER JOIN step USING(step_id)
WHERE  date_step_end IS NOT Null and name_step = "Оплата"
GROUP BY 1, 2
ORDER BY 2, 1;


/*Для каждой отдельной книги необходимо вывести информацию о количестве проданных экземпляров 
и их стоимости за текущий и предыдущий год . Вычисляемые столбцы назвать Количество и Сумма. 
Информацию отсортировать по убыванию стоимости.*/

SELECT title, SUM(Количество) AS "Количество", SUM(Сумма) AS "Сумма"
FROM (
    SELECT title, SUM(buy_archive.amount) AS "Количество", SUM(buy_archive.amount * buy_archive.price) AS "Сумма" 
    FROM book
    JOIN buy_archive USING(book_id)
    GROUP BY title
		UNION ALL
    SELECT title, buy_book.amount AS "Количество", book.price * buy_book.amount  AS "Сумма"
    FROM book
        JOIN buy_book USING(book_id)
        JOIN buy USING(buy_id)
        JOIN buy_step USING(buy_id)
        JOIN step USING(step_id)
    WHERE date_step_end IS NOT NULL AND name_step = "Оплата"
    ) query_in
GROUP BY title
ORDER BY 3 DESC;


/* В таблицу buy_book добавить заказ с номером 5. 
Этот заказ должен содержать книгу Пастернака «Лирика» в количестве двух экземпляров 
и книгу Булгакова «Белая гвардия» в одном экземпляре.*/

INSERT INTO buy_book(buy_id, book_id, amount)
VALUES (5, (SELECT book_id FROM book WHERE title = "Лирика"), 2),
        (5, (SELECT book_id FROM book WHERE title = "Белая гвардия"), 1);


/* Уменьшить количество тех книг на складе, которые были включены в заказ с номером 5.*/

UPDATE book
    JOIN buy_book USING(book_id)
SET book.amount = book.amount - buy_book.amount
WHERE book.book_id IN(SELECT book_id FROM buy_book WHERE buy_id = 5);

SELECT * FROM book;


/* Создать счет (таблицу buy_pay) на оплату заказа с номером 5, в который включить название книг, 
их автора, цену, количество заказанных книг и  стоимость. Последний столбец назвать Стоимость. 
Информацию в таблицу занести в отсортированном по названиям книг виде.*/

CREATE TABLE buy_pay AS
SELECT title, name_author, price, buy_book.amount, (price * buy_book.amount) AS "Стоимость"
FROM buy_book
    JOIN book USING(book_id)
    JOIN author USING(author_id)
WHERE buy_id = 5    
ORDER BY title;