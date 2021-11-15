/* Вывести абитуриентов, которые хотят поступать на образовательную 
программу «Мехатроника и робототехника» в отсортированном по фамилиям виде.*/

SELECT name_enrollee
FROM enrollee
    JOIN program_enrollee USING(enrollee_id)
    JOIN program USING(program_id)
WHERE name_program = "Мехатроника и робототехника"
ORDER BY 1;


/*  Выведите количество абитуриентов, сдавших ЕГЭ по каждому предмету, максимальное, минимальное 
и среднее значение баллов по предмету ЕГЭ. Вычисляемые столбцы назвать Количество, Максимум, Минимум, Среднее. 
Информацию отсортировать по названию предмета в алфавитном порядке, 
среднее значение округлить до одного знака после запятой.*/

SELECT name_subject, 
       COUNT(result) AS "Количество", 
       MAX(result) AS "Максимум", 
       MIN(result) AS "Минимум", 
       ROUND(AVG(result), 1) AS "Среднее"
FROM subject JOIN enrollee_subject USING(subject_id)
GROUP BY subject_id
ORDER BY 1;


/*  Вывести образовательные программы, для которых минимальный балл ЕГЭ по каждому предмету больше или равен 40 баллам. 
Программы вывести в отсортированном по алфавиту виде.*/

SELECT DISTINCT name_program
FROM program JOIN program_subject USING(program_id)
WHERE program_id IN(
            SELECT program_id
            FROM program_subject
            GROUP BY program_id
            HAVING min(min_result) >= 40
            ) 
GROUP BY program_id
ORDER BY 1;


/* Вывести образовательные программы, которые имеют самый большой план набора,  вместе с этой величиной.*/




/* Посчитать количество баллов каждого абитуриента на каждую образовательную программу, на которую он подал заявление, 
по результатам ЕГЭ. В результат включить название образовательной программы, фамилию и имя абитуриента, 
а также столбец с суммой баллов, который назвать itog. 
Информацию вывести в отсортированном сначала по образовательной программе, а потом по убыванию суммы баллов виде.*/

SELECT name_program, name_enrollee, SUM(result) AS "itog"
FROM enrollee
    JOIN program_enrollee USING(enrollee_id)
    JOIN program USING(program_id)
    JOIN program_subject USING(program_id)
    JOIN enrollee_subject USING(subject_id, enrollee_id)
GROUP BY 1, 2
ORDER BY 1, 3 DESC;


/* Посчитать, сколько дополнительных баллов получит каждый абитуриент. 
Столбец с дополнительными баллами назвать Бонус. 
Информацию вывести в отсортированном по фамилиям виде. */

SELECT name_enrollee, IFNULL(sum(bonus), 0) AS "Бонус"
FROM enrollee
    LEFT JOIN enrollee_achievement USING(enrollee_id)
    LEFT JOIN achievement USING(achievement_id)
GROUP BY 1
ORDER BY 1;


/* Выведите сколько человек подало заявление на каждую образовательную программу и конкурс на нее 
(число поданных заявлений деленное на количество мест по плану), округленный до 2-х знаков после запятой. 
В запросе вывести название факультета, к которому относится образовательная программа, 
название образовательной программы, план набора абитуриентов на образовательную программу (plan), 
количество поданных заявлений (Количество) и Конкурс. 
Информацию отсортировать в порядке убывания конкурса.*/

SELECT name_department, name_program, plan, 
	COUNT(enrollee_id) AS "Количество", 
	ROUND(COUNT(enrollee_id) / plan, 2) AS "Конкурс" 
FROM department
    JOIN program USING(department_id)
    JOIN program_enrollee USING(program_id)
GROUP BY 1, 2, 3
ORDER BY 5 DESC;


/* Вывести название образовательной программы и фамилию тех абитуриентов, которые подавали документы 
на эту образовательную программу, но не могут быть зачислены на нее. 
Эти абитуриенты имеют результат по одному или нескольким предметам ЕГЭ, 
необходимым для поступления на эту образовательную программу, меньше минимального балла. 
Информацию вывести в отсортированном сначала по программам, а потом по фамилиям абитуриентов виде. */

SELECT name_program, name_enrollee
FROM enrollee
    JOIN enrollee_subject USING(enrollee_id)
    JOIN subject USING(subject_id)
    JOIN program_subject USING(subject_id)
    JOIN program USING(program_id)
    JOIN program_enrollee USING(program_id, enrollee_id)
WHERE result < min_result
GROUP BY 1, 2
ORDER BY 1, 2;


/* Из таблицы applicant удалить записи, если абитуриент на выбранную образовательную программу не набрал минимального балла хотя бы по одному предмету. */

DELETE FROM applicant
WHERE (program_id, enrollee_id) IN(
    SELECT program_id, enrollee_id
    FROM enrollee
        JOIN enrollee_subject USING(enrollee_id)
        JOIN subject USING(subject_id)
        JOIN program_subject USING(subject_id)
        JOIN program USING(program_id)
        JOIN program_enrollee USING(program_id, enrollee_id)
    WHERE result < min_result
    GROUP BY 1, 2
    );
    

/* Повысить итоговые баллы абитуриентов в таблице applicant на значения дополнительных баллов. */

UPDATE applicant, (SELECT enrollee_id, IFNULL(sum(bonus), 0) AS "bonus"
                    FROM enrollee
                        LEFT JOIN enrollee_achievement USING(enrollee_id)
                        LEFT JOIN achievement USING(achievement_id)
                    GROUP BY enrollee_id) query_in
SET itog = itog + query_in.bonus
WHERE applicant.enrollee_id = query_in.enrollee_id;


/* Занести в столбец str_id таблицы applicant_order нумерацию абитуриентов, 
которая начинается с 1 для каждой образовательной программы*/

SET @num_pr := 0;
SET @row_num := 1;

UPDATE applicant_order 
SET str_id = if(program_id = @num_pr, @row_num := @row_num + 1, @row_num := 1 AND @num_pr:= @num_pr + 1);


/* Создать таблицу student,  в которую включить абитуриентов, которые могут быть рекомендованы к зачислению
в соответствии с планом набора. 
Информацию отсортировать сначала в алфавитном порядке по названию программ, а потом по убыванию итогового балла.*/

CREATE TABLE student AS
SELECT name_program, name_enrollee, itog
FROM program 
    JOIN applicant_order USING(program_id)
    JOIN enrollee USING(enrollee_id)
WHERE str_id <= plan
GROUP BY 1, 2, 3                              
ORDER BY 1, 3 DESC;