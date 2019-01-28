/***** Aaron Gravelle *****/

/*****************************************************************
*
* 2.0 SQL Queries
*
******************************************************************/

/* 2.1 SELECT */
select * from employee;
select * from employee where lastname = 'King';
select * from employee where firstname = 'Andrew' and reportsto is null;

/* 2.2 ORDER BY */
select * from album order by title desc;
select firstname from customer order by city asc;

/* 2.3 INSERT INTO */
insert into genre values (26, 'Aaron Music');
insert into genre values (27, 'Gravelle Music');

insert into employee (employeeid, lastname, firstname) values (9, 'Gravelle', 'Aaron');
insert into employee (employeeid, lastname, firstname) values (10, 'Snow', 'Ben');

insert into customer (customerid, lastname, firstname, email) values (60, 'Gravelle', 'Aaron', 'ag@gmail.com');
insert into customer (customerid, lastname, firstname, email) values (61, 'Snow', 'Ben', 'bs@gmail.com');

/* 2.4 UPDATE */
update customer set lastname = 'Walter', firstname = 'Robert' where lastname = 'Mitchell' and firstname = 'Aaron';
update artist set "name" = 'CCR' where "name" = 'Creedence Clearwater Revival';

/* 2.5 LIKE */
select * from invoice where billingaddress like 'T%';

/* 2.6 BETWEEN */
select * from invoice where total between 15 and 50;

/* 2.7 DELETE */
alter table invoiceline
drop constraint fk_invoicelineinvoiceid;

alter table invoiceline
add constraint fk_invoicelineinvoiceid FOREIGN KEY (invoiceid) REFERENCES invoice(invoiceid)
on delete cascade
on update cascade;

alter table invoice
drop constraint fk_invoicecustomerid;

alter table invoice
add constraint fk_invoicecustomerid FOREIGN KEY (customerid) REFERENCES customer(customerid)
on delete cascade
on update cascade;

delete from customer where lastname = 'Walter' and firstname = 'Robert'

/*****************************************************************
*
* 3.0 SQL Functions
* 
******************************************************************/

/* 3.1 System Defined Function */
create function get_time() returns time as $$
	select localtime;
$$ language sql;
select get_time();

create function get_mediatype_length(id integer) returns integer as $$
	select length(name) from mediatype where mediatypeid = id;
$$ language sql;
select get_mediatype_length(2);

/* 3.2 System Defined Aggregate Functions */
create function invoice_avg() returns money as $$
	select cast(round(avg(total), 2) as money) from invoice;
$$ language sql;
select invoice_avg();

create or replace function most_expensive_track() returns numeric as $$
	select unitprice from track where unitprice = (
						   select max(unitprice) from track);
$$ language sql;
select most_expensive_track();
select * from track where unitprice = most_expensive_track();

/* 3.3 user defined Scalar functions */
CREATE OR REPLACE FUNCTION avg_invoiceline_total()
RETURNS money as $$
BEGIN 
	RETURN AVG(quantity * unitprice) FROM invoiceline;
END;
$$ LANGUAGE plpgsql;

select avg_invoiceline_total();

/* 3.4 user defined table valued functions */
CREATE OR REPLACE FUNCTION get_young_employees()
RETURNS SETOF employee AS $$
DECLARE
	date_check timestamp := make_timestamp(1969, 1, 1, 0, 0, 0);
BEGIN 
	RETURN QUERY
	SELECT * FROM employee WHERE birthdate >= date_check; 
END;
$$ LANGUAGE plpgsql;

SELECT get_young_employees();

/*************************************************************
 * 
 *  4.0 Stored Procedures
 * 
 * ***********************************************************/

/* 4.1 Basic Stored Procedure */
CREATE OR REPLACE FUNCTION get_employee_names_proc(OUT curs refcursor)
RETURNS refcursor AS $$
BEGIN 
	OPEN curs FOR SELECT lastname, firstname FROM employee;
END; 
$$ LANGUAGE plpgsql;

CREATE TABLE employee_names(empID SERIAL PRIMARY KEY, lastname TEXT, firstname TEXT);

DO $$ 
DECLARE 
	curs REFCURSOR;
	lname TEXT;
	fname TEXT;
BEGIN 
	SELECT get_employee_names_proc() INTO curs;
	LOOP 
		FETCH curs INTO lname, fname;
		EXIT WHEN NOT FOUND;
		INSERT INTO employee_names(lastname, firstname) VALUES (lname, fname);
	END LOOP;		
END; $$ LANGUAGE plpgsql;

SELECT * FROM employee_names;

/* 4.2 STORED PROCEDURE INPUT PARAMETERS */

CREATE OR REPLACE FUNCTION update_emp_proc(
	p_id INT4,  
	p_address VARCHAR(70), 
	p_city VARCHAR(40),
	p_state VARCHAR(40),
	p_country VARCHAR(40), 
	p_postalcode VARCHAR(10), 
	p_phone VARCHAR(24), 
	p_fax VARCHAR(24), 
	p_email VARCHAR(60)
)
RETURNS VOID AS $$
BEGIN 
	UPDATE employee 
		SET address = p_address, 
		city = p_city,
		state = p_state,
		country = p_country,
		postalcode = p_postalcode, 
		phone = p_phone
		WHERE employeeid = p_id;
END; $$ LANGUAGE plpgsql;

SELECT update_emp_proc(8, '123 Sesame St.', 'New York', 'NY','USA','12345', '123-456-7890', '098-765-4321', 'ag@gmail.com');

CREATE OR REPLACE FUNCTION get_empl_manager_proc(IN emplID INT, OUT managerID INT)
RETURNS INTEGER AS $$
BEGIN
	SELECT reportsto FROM employee WHERE employeeid = emplID INTO managerID;
END; $$ LANGUAGE plpgsql;

SELECT get_empl_manager_proc(2);

/* 4.3 STORED PROCEDURE OUTPUT PARAMETERS */

CREATE OR REPLACE FUNCTION get_name_and_company_proc(IN id INT, OUT out_param TEXT)
RETURNS TEXT AS $$
BEGIN 
	SELECT 'Name: ' || firstname || ' ' || lastname || ', Company: ' || company 
	FROM customer WHERE customerid = id INTO out_param;
END; $$ LANGUAGE plpgsql;

SELECT get_name_and_company_proc(11);

/*************************************************************
 * 
 *  5.0 TRANSACTIONS
 * 
 * ***********************************************************/

BEGIN;
	DELETE FROM invoice WHERE invoiceid = 10;
COMMIT;

CREATE OR REPLACE FUNCTION new_customer_proc()
RETURNS VOID AS $$
BEGIN
	INSERT INTO customer VALUES (62, 'Bill', 'Nye', 'PBS', 'addr', 'NY', 'NY', 'US','44444','2222222222',
						  '33333333333', 'bn@gmail.com', 4);
END; $$ LANGUAGE plpgsql;

SELECT new_customer_proc();
SELECT * FROM customer;

/*************************************************************
 *   
 *  6.0 TRIGGERS
 * 
 * ***********************************************************/

/* 6.1 AFTER/FOR */
CREATE OR REPLACE FUNCTION on_add_employee() 
RETURNS TRIGGER AS $$
BEGIN 
	IF(TG_OP = 'INSERT') THEN 
		RAISE 'Employee Inserted';
	END IF; 
	RETURN NEW; 
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER on_add_employee
	AFTER INSERT ON employee
	FOR EACH ROW 
	EXECUTE PROCEDURE on_add_employee();

INSERT INTO employee (employeeid, firstname, lastname)VALUES (93, 'Big', 'Bird');
SELECT * FROM employee;

CREATE OR REPLACE FUNCTION on_update_employee() 
RETURNS TRIGGER AS $$
BEGIN 
	IF(TG_OP = 'UPDATE') THEN 
		RAISE 'Employee Updated';
	END IF; 
	RETURN NEW; 
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER on_update_employee
	AFTER UPDATE ON employee
	FOR EACH ROW 
	EXECUTE PROCEDURE on_update_employee();

UPDATE employee SET city = 'Tampa' WHERE firstname = 'Aaron';

CREATE OR REPLACE FUNCTION on_delete_employee() 
RETURNS TRIGGER AS $$
BEGIN 
	IF(TG_OP = 'DELETE') THEN 
		RAISE 'Employee Deleted';
	END IF; 
	RETURN NEW; 
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER on_delete_employee
	AFTER DELETE ON employee
	FOR EACH ROW 
	EXECUTE PROCEDURE on_delete_employee();

/*************************************************************
 *   
 *  7.0 Joins
 * 
 * ***********************************************************/

/* 7.1 Inner */
 SELECT customer.firstname, customer.lastname, invoice.invoiceid
 FROM customer INNER JOIN invoice ON customer.customerid = invoice.customerid;

/* 7.2 OUTER */
SELECT customer.customerid, customer.firstname, customer.lastname,
	   invoice.invoiceid, invoice.total
FROM customer FULL OUTER JOIN invoice ON customer.customerid = invoice.customerid;

/* 7.3 RIGHT JOIN */
SELECT artist.name, album.title FROM artist RIGHT JOIN album ON artist.artistid = album.artistid;

/* 7.4 CROSS JOIN */
SELECT * FROM album CROSS JOIN artist ORDER BY artist.name ASC;

/* 7.5 SELF JOIN */
SELECT e1.employeeid, e2.employeeid, e1.reportsto 
FROM employee e1 INNER JOIN employee e2 
ON e1.reportsto = e2.reportsto AND e1.employeeid <> e2.employeeid;