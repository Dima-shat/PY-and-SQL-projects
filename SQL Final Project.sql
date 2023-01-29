-- 1.Покажите среднюю зарплату сотрудников за каждый год 
SELECT year(from_date) AS year, avg(salary)
FROM employees.salaries
GROUP BY year
ORDER BY year;

-- 2.Покажите среднюю зарплату сотрудников по каждому отделу. Примечание: принять в расчет только текущие отделы и текущую заработную плату.
SELECT ede.dept_no, avg(es.salary) AS Average_salary
FROM employees.salaries AS es
INNER JOIN employees.dept_emp AS ede ON(es.emp_no = ede.emp_no)
WHERE curdate() BETWEEN es.from_date AND es.to_date AND
	curdate() BETWEEN ede.from_date AND ede.to_date
GROUP BY ede.dept_no
ORDER BY ede.dept_no;

-- 3.Покажите среднюю зарплату сотрудников по каждому отделу за каждый год. 
-- Примечание: для средней зарплаты отдела X в году Y нам нужно взять среднее значение всех зарплат в году Y сотрудников,
-- которые были в отделе X в году Y
SELECT dept_no, year(es.from_date) AS year, avg(es.salary) AS Average_salary
FROM employees.salaries AS es
INNER JOIN employees.dept_emp AS ede ON(es.emp_no = ede.emp_no)
WHERE year(es.from_date) BETWEEN year(ede.from_date) AND year(es.to_date)
GROUP BY year, dept_no
ORDER BY ede.dept_no, year;

-- 4.Покажите для каждого года самый крупный отдел (по количеству сотрудников) в этом году и его среднюю зарплату.
SELECT 
	Year, 
    dept_no, 
    max(quantity) AS Quantity_of_employees, 
    AVG_salary
FROM (SELECT 
		de.dept_no, 
        year(es.from_date) AS year, 
        count(de.emp_no) AS quantity, 
        avg(salary) AS AVG_salary
	FROM  employees.salaries AS es
	INNER JOIN dept_emp AS de ON(es.emp_no=de.emp_no)
	WHERE year(es.from_date) BETWEEN year(de.from_date) AND year(es.to_date)
	GROUP BY dept_no, year
	ORDER BY year(es.from_date), count(de.emp_no) DESC) AS subq
GROUP BY year;
	

-- 5.Покажите подробную информацию о менеджере, который дольше всех исполняет свои обязанности на данный момент.
SELECT 
	dm.emp_no, 
    e.first_name,
    e.last_name, 
    e.gender, 
    dm.dept_no, 
    e.hire_date, 
    concat(dm.from_date, ' - ', dm.to_date) AS 'Work on meneger position',
    e.birth_date, 
    timestampdiff(day, from_date, curdate()) AS work_days
FROM 
	dept_manager AS dm
INNER JOIN employees AS e USING(emp_no)
WHERE 
	curdate() BETWEEN dm.from_date AND dm.to_date
ORDER BY work_days DESC
LIMIT 1;

-- 6!!!.Покажите топ-10 нынешних сотрудников компании с наибольшей разницей между их зарплатой и текущей средней зарплатой в их отделе
SELECT 
	emp_no,
    salary AS Cur_sal,
    dept_no,
	abs((avg(salary) OVER (PARTITION BY dept_no)) - salary) AS Dif_sal
FROM salaries AS s
INNER JOIN dept_emp AS de USING(emp_no)
WHERE curdate() BETWEEN s.from_date AND s.to_date AND
	curdate() BETWEEN de.from_date AND de.to_date
ORDER BY dif_sal DESC
LIMIT 10;
	
    
/* 7!!!.Из-за кризиса на одно подразделение на своевременную выплату зарплаты выделяется всего 500 тысяч долларов. 
Правление решило, что низкооплачиваемые сотрудники будут первыми получать зарплату.
 Показать список всех сотрудников, которые будут вовремя получать зарплату 
 (обратите внимание, что мы должны платить зарплату за один месяц, но в базе данных мы храним годовые суммы). */
 SELECT *
 FROM (	SELECT 
		de.emp_no, 
		de.dept_no, s.salary,
		salary/12 AS month_sal,
		sum(salary/12) OVER (PARTITION BY dept_no ORDER BY salary 
			RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS Sum_sal
	 FROM dept_emp AS de
	 INNER JOIN salaries AS s USING(emp_no)
	 WHERE curdate() BETWEEN de.from_date AND de.to_date AND
		curdate() BETWEEN s.from_date AND s.to_date) as sabq
WHERE sum_sal <= 500000;


/* 1!!!.Разработайте базу данных для управления курсами. База данных содержит следующие сущности:
a) students: student_no, teacher_no, course_no, student_name, email, birth_date.
b) teachers: teacher_no, teacher_name, phone_no
c) courses: course_no, course_name, start_date, end_date.
● Секционировать по годам, таблицу students по полю birth_date с помощью механизма range
● В таблице students сделать первичный ключ в сочетании двух полей student_no и birth_date
● Создать индекс по полю students.email
● Создать уникальный индекс по полю teachers.phone_no */
CREATE DATABASE IF NOT EXISTS Courses;

CREATE TABLE Students (
	student_no INT AUTO_INCREMENT,
    teacher_no INT,
    course_no INT NOT NULL,
    student_name VARCHAR(20) NOT NULL,
    email VARCHAR(30),
    birth_date DATE,
		PRIMARY KEY (student_no, birth_date)
);

CREATE TABLE teachers (
	teacher_no INT,
    teacher_name VARCHAR(20) NOT NULL,
    phone_no CHAR (13)
    );
    
-- c) courses: course_no, course_name, start_date, end_date.
CREATE TABLE courses (
	course_no INT NOT NULL,
    course_name VARCHAR(40) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

-- Секционировать по годам, таблицу students по полю birth_date с помощью механизма range
ALTER TABLE students PARTITION BY RANGE (year(birth_date)) (
	PARTITION p_1980 VALUES LESS THAN(1981),
    PARTITION p_1981 VALUES LESS THAN(1982),
    PARTITION p_1982 VALUES LESS THAN(1983),
    PARTITION p_1983 VALUES LESS THAN(1984),
    PARTITION p_1984 VALUES LESS THAN(1985),
    PARTITION p_1985 VALUES LESS THAN(1986),
    PARTITION p_1986 VALUES LESS THAN(1987),
    PARTITION p_1987 VALUES LESS THAN(1988),
    PARTITION p_1988 VALUES LESS THAN(1989),
    PARTITION p_1989 VALUES LESS THAN(1990),
    PARTITION p_1990 VALUES LESS THAN(1991),
    PARTITION p_1991 VALUES LESS THAN(1992),
    PARTITION p_1992 VALUES LESS THAN(1993),
    PARTITION p_1993 VALUES LESS THAN(1994),
    PARTITION p_1994 VALUES LESS THAN(1995),
    PARTITION p_1995 VALUES LESS THAN(1996),
    PARTITION p_1996 VALUES LESS THAN(1997),
    PARTITION p_1997 VALUES LESS THAN(1998),
    PARTITION p_1998 VALUES LESS THAN(1999),
    PARTITION p_1999 VALUES LESS THAN(2000),
    PARTITION p_2000 VALUES LESS THAN(2001)
);

-- Создать индекс по полю students.email
CREATE INDEX e_mail ON students(email);

-- Создать уникальный индекс по полю teachers.phone_no
CREATE UNIQUE INDEX phone ON teachers(phone_no);


-- 2!!!.На свое усмотрение добавить тестовые данные (7-10 строк) в наши три таблицы.
INSERT INTO students (teacher_no, course_no, student_name, email, birth_date) VALUES
	(1, 1, 'Alex', 'alex@alex.com', '1980-12-23'),
    (2, 1, 'Fedr', 'Fedr@fedr.com', '1985-11-13'),
    (3, 5, 'Angela', 'angela@topgirl.com', '1990-01-16'),
    (2, 2, 'Suzana', 'suzana@bestgirl.com.ua', '1993-06-20'),
    (1, 3, 'Liza', 'liza@liza.com', '1981-11-23'),
    (1, 1, 'Miha', 'miha@miha.com', '1980-03-14'),
    (5, 2, 'Jorik', 'jorik@jorik.com', '1985-12-23'),
    (3, 6, 'Durik', 'durik@durik.com', '1996-12-23'),
    (2, 2, 'Zubr', 'zubr@zubr.com', '1983-10-01'),
    (4, 7, 'Teodor', 'tod@tod.com', '1989-03-23'),
    (1, 7, 'Jorg', 'go@jorg.com', '1981-11-01');
    
SELECT *
FROM students;

INSERT INTO teachers VALUES
	(1, 'Zarina', '+380967874563'),
    (2, 'Jizel', '+380967874532'),
    (3, 'Sandra', '+380967874533'),
    (4, 'Kasandra', '+380967874534'),
    (5, 'Karina', '+380967874535'),
    (6, 'Umas', '+380967874536'),
    (7, 'Petr', '+380967874537'),
    (8, 'Petr', '+380967874538');

SELECT *
FROM teachers;

INSERT INTO courses VALUES
	(1, 'English', '2022-06-01', '2022-12-01'),
    (2, 'English IELTS', '2022-07-01', '2023-02-01'),
    (3, 'English UPPER', '2022-04-01', '2022-08-01'),
    (4, 'Spanish bigginer', '2022-05-01', '2022-08-01'),
    (5, 'Spanish', '2022-05-01', '2022-12-01'),
    (6, 'Japanese', '2022-08-01', '2022-10-01'),
    (7, 'English TOEFL', '2022-07-01', '2022-10-01');
    
SELECT *
FROM courses;

/* 3!!!.Отобразить данные за любой год из таблицы students и зафиксировать в виде 
комментария план выполнения запроса, где будет видно что запрос будет выполняться по конкретной секции. */
EXPLAIN SELECT *
FROM students
WHERE birth_date < '1981-12-31' AND birth_date > '1981-01-01';


/* 4!!!.Отобразить данные учителя, по любому одному номеру телефона и зафиксировать план выполнения запроса, 
где будет видно, что запрос будет выполняться по индексу, а не методом ALL. 
Далее индекс из поля teachers.phone_no сделать невидимым и зафиксировать план выполнения запроса, где ожидаемый результат -метод ALL.
В итоге индекс оставить в статусе -видимый. */
EXPLAIN SELECT *
FROM teachers
WHERE phone_no = '+380967874532';
# id, select_type, table, partitions, type, possible_keys, key, key_len, ref, rows, filtered, Extra
# '1', 'SIMPLE', 'teachers', NULL,   'const', 'phone',   'phone', '53', 'const', '1', '100.00', NULL

ALTER TABLE teachers ALTER INDEX phone INVISIBLE;

EXPLAIN SELECT *
FROM teachers
WHERE phone_no = '+380967874532';
# id, select_type, table, partitions, type, possible_keys, key, key_len, ref, rows, filtered, Extra
# '1', 'SIMPLE', 'teachers', NULL,   'ALL',       NULL,    NULL, NULL,  NULL, '8',  '12.50', 'Using where'

ALTER TABLE teachers ALTER INDEX phone VISIBLE;


-- 5.Специально сделаем 3 дубляжа в таблице students (добавим еще 3 одинаковые строки).
INSERT INTO students (teacher_no, course_no, student_name, email, birth_date) VALUES
	(1, 1, 'Egor', 'egor@egor.com', '1983-10-08'); -- три рази запускаємо
    
    
SELECT * 
FROM students;

-- 6!!!.Написать запрос, который выводит строки с дубляжами.
SELECT *
FROM students AS s
WHERE EXISTS (
	SELECT 1
    FROM students AS s1
    WHERE
		s.teacher_no = s1.teacher_no AND
        s.course_no = s1.course_no AND
		s.student_name = s1.student_name AND 
		s.email = s1.email AND
        s.birth_date = s1.birth_date
    LIMIT 1, 1
    );



	




    
    
    

    



    


