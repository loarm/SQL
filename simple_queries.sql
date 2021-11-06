CREATE TABLE book(
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(50),
    author VARCHAR(30),
    price DECIMAL(8, 2),
    amount INT
    );
	
INSERT INTO book(title, author, price, amount) VALUES('Белая гвардия', 'Булгаков М.А.', 540.50, 5);
INSERT INTO book(title, author, price, amount) VALUES('Идиот', 'Достоевский Ф.М.', 460.00, 10);
INSERT INTO book(title, author, price, amount) VALUES('Братья Карамазовы', 'Достоевский Ф.М.', 799.01, 2);
	

/* Задание
Для каждого автора вычислить суммарную стоимость книг S (имя столбца Стоимость), 
а также вычислить налог на добавленную стоимость  для полученных сумм (имя столбца НДС ), 
который включен в стоимость и составляет k = 18%,  а также стоимость книг  (Стоимость_без_НДС) без него. 
Значения округлить до двух знаков после запятой.*/

SELECT author, ROUND(SUM(price * amount), 2) AS Стоимость, 
	ROUND(SUM(price * amount) * 0.18 / 1.18, 2) AS НДС, 
	ROUND(SUM(price * amount) / 1.18, 2) AS Стоимость_без_НДС
FROM book
GROUP BY author;
 
 
 /* Задание
Посчитать стоимость всех экземпляров каждого автора без учета книг «Идиот» и «Белая гвардия». 
В результат включить только тех авторов, у которых суммарная стоимость книг более 5000 руб. 
Вычисляемый столбец назвать Стоимость. 
Результат отсортировать по убыванию стоимости. */

SELECT author, ROUND(SUM(price * amount), 2) AS Стоимость
FROM book
WHERE title != "Идиот" AND title != "Белая гвардия"
GROUP BY author 
HAVING SUM(price * amount) >= 5000
ORDER BY ROUND(SUM(price * amount), 2) DESC;


/* Задание
Посчитать сколько и каких экземпляров книг нужно заказать поставщикам, 
чтобы на складе стало одинаковое количество экземпляров каждой книги, 
равное значению самого большего количества экземпляров одной книги на складе. 
Вывести название книги, ее автора, текущее количество экземпляров на складе 
и количество заказываемых экземпляров книг. 
Последнему столбцу присвоить имя Заказ. */

SELECT title, author, amount,
    ((SELECT MAX(amount)
     FROM book) - amount) AS Заказ
FROM book
WHERE ((SELECT MAX(amount)
     FROM book) - amount) > 0;


/* Вывести название, жанр и цену тех книг, количество которых больше 8, в отсортированном по убыванию цены виде.*/

SELECT title, name_genre, price
FROM book 
	INNER JOIN genre ON genre.genre_id = book.genre_id
WHERE amount > 8
ORDER BY price DESC;


/* Вывести все жанры, которые не представлены в книгах на складе.*/

SELECT name_genre
FROM genre 
	LEFT JOIN book ON genre.genre_id = book.genre_id
WHERE title is NULL;


/* Необходимо в каждом городе провести выставку книг каждого автора в течение 2020 года. 
Дату проведения выставки выбрать случайным образом. Создать запрос, который выведет город, 
автора и дату проведения выставки. Последний столбец назвать Дата. Информацию вывести, 
отсортировав сначала в алфавитном порядке по названиям городов, а потом по убыванию дат проведения выставок.*/

SELECT name_city, name_author, DATE_ADD("2020-01-01", INTERVAL FLOOR(RAND()* 365)DAY) AS "Дата"
FROM city 
	CROSS JOIN author
ORDER BY name_city, Дата DESC;


/*Посчитать количество экземпляров  книг каждого автора из таблицы author.  
Вывести тех авторов,  количество книг которых меньше 10, 
в отсортированном по возрастанию количества виде. Последний столбец назвать Количество. */

SELECT name_author, SUM(amount) AS "Количество"
FROM author 
	LEFT JOIN book ON author.author_id = book.author_id
GROUP BY name_author
HAVING Количество < 10 OR Количество is NULL
ORDER BY Количество;


/*Вывести информацию о книгах (название книги, фамилию и инициалы автора, название жанра, цену и 
количество экземпляров книг), написанных в самых популярных жанрах, 
в отсортированном в алфавитном порядке по названию книг виде. 
Самым популярным считать жанр, общее количество экземпляров книг которого на складе максимально. */

SELECT title, name_author, name_genre, price, amount
FROM book
    JOIN genre ON genre.genre_id = book.genre_id
    JOIN author ON author.author_id = book.author_id 
WHERE book.genre_id IN(
    SELECT genre_id
    FROM book
    GROUP BY genre_id
    HAVING SUM(amount) >= ALL(SELECT SUM(amount) 
                              FROM book 
                              GROUP BY genre_id) 
	)
ORDER BY book.title;


/* Если в таблицах supply  и book есть одинаковые книги, которые имеют равную цену, 
вывести их название и автора, а также посчитать общее количество экземпляров книг в таблицах supply и book, 
столбцы назвать Название, Автор  и Количество. */

SELECT book.title AS "Название", author.name_author AS "Автор", book.amount + supply.amount AS "Количество"
FROM author
    JOIN book USING(author_id)
    JOIN supply ON book.title = supply.title 
WHERE book.price = supply.price;


/* Для книг, которые уже есть на складе (в таблице book), но по другой цене, чем в поставке (supply),  
необходимо в таблице book увеличить количество на значение, указанное в поставке, и пересчитать цену. 
А в таблице  supply обнулить количество этих книг. */

UPDATE book
    JOIN author ON book.author_id = author.author_id
    JOIN supply ON book.title = supply.title and supply.author = author.name_author
SET book.amount = book.amount + supply.amount,
    book.price = (((book.price * book.amount) + (supply.price * supply.amount)) / (supply.amount + book.amount)),
    supply.amount = 0
WHERE book.price != supply.price;


/* Включить новых авторов в таблицу author с помощью запроса на добавление, а затем вывести все данные из таблицы author.  
Новыми считаются авторы, которые есть в таблице supply, но нет в таблице author.*/

INSERT INTO author(name_author)
SELECT supply.author
FROM author
    RIGHT JOIN supply ON supply.author = author.name_author
WHERE name_author is NULL;


/* Добавить новые книги из таблицы supply в таблицу book на основе сформированного выше запроса. 
Затем вывести для просмотра таблицу book.*/

INSERT INTO book(title, author_id, price, amount)
SELECT title, author_id, price, amount 
FROM author
    JOIN supply ON supply.author = author.name_author
WHERE amount <> 0;


/* Удалить всех авторов и все их книги, общее количество книг которых меньше 20. */

DELETE FROM author
WHERE author_id IN(
    SELECT author_id
    FROM book
    GROUP BY author_id
    HAVING SUM(amount) < 20
    );
