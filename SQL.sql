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

