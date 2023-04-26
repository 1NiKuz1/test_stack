-- Задание 1 
-- Примечание: В задание было сказано что вторым аргументом применяется дата, но в примере вывода данных
-- идет поиск по месяцу, поэтому я сделал реализацию функции по этому атрибуту, для схожего результата в примере
CREATE OR REPLACE FUNCTION stack.select_count_pok_by_service(
    input_service character varying,
    input_month character varying
)
RETURNS TABLE(acc int, serv int, count bigint) AS
$$
BEGIN
    RETURN QUERY
	SELECT ac.number AS acc, ct.service AS serv, COUNT(ct.service) AS count
    FROM stack.meter_pok as mt
	INNER JOIN stack.counters as ct
	ON mt.counter_id = ct.row_id
	INNER JOIN stack.accounts as ac
	ON ct.acc_id = ac.row_id
	WHERE ct.service = input_service::int and mt.month = input_month::date
	GROUP BY ac.number, ct.service;
END;
$$
LANGUAGE plpgsql;

select * from stack.select_count_pok_by_service('300','20230201')

-----------------------------------------------------------------------------

-- Задание 2
CREATE OR REPLACE FUNCTION stack.select_last_pok_by_service(
    house_number int,
	input_month character varying
)
RETURNS TABLE(acc int, name text, value bigint) AS $$
DECLARE
    house_id int;
    acc_ids int[];
    acc_id int;
    counter_ids int[];
BEGIN
    -- Находим id дома
    SELECT ac.row_id INTO house_id
	FROM stack.Accounts AS ac
	WHERE number = house_number AND type = 1;
	
	-- Находим все квартиры, связанные с данным домом
    SELECT ARRAY(SELECT ac.row_id
				 FROM stack.Accounts AS ac
				 WHERE parent_id = house_id AND type = 2)
				 INTO acc_ids;
				 
	 -- Находим все лицевые счета, связанные с найденными квартирами
    SELECT ARRAY(SELECT ac.row_id
				 FROM stack.Accounts AS ac
				 WHERE parent_id IN (SELECT unnest(acc_ids)) AND type = 3)
				 INTO counter_ids;
				 
	RETURN QUERY SELECT ac.number, ct.name, SUM(mt.value)
	FROM stack.meter_pok as mt
	INNER JOIN stack.counters as ct
	ON mt.counter_id = ct.row_id
	INNER JOIN stack.accounts as ac
	ON ct.acc_id = ac.row_id
	WHERE mt.month = input_month::date AND
	ac.row_id IN (SELECT unnest(counter_ids))
	GROUP BY ac.number, ct.name;
END;
$$
LANGUAGE plpgsql;

select * from stack.select_last_pok_by_service(1,'20230201')

-----------------------------------------------------------------------------

-- Задание 3
CREATE OR REPLACE FUNCTION stack.select_last_pok_by_acc(
    acc_number int
)
RETURNS TABLE(acc int, serve int, date date, tarif int, value int) AS $$
BEGIN
	RETURN QUERY SELECT ac.number as acc, ct.service as serve, mt.date, mt.tarif, mt.value
	FROM stack.meter_pok AS mt
	JOIN stack.counters AS ct
	ON mt.counter_id = ct.row_id
	JOIN stack.accounts AS ac
	ON ct.acc_id = ac.row_id 
	WHERE ac.number = acc_number AND mt.date IN 
		(select MAX(mt1.date)
		FROM stack.meter_pok AS mt1
		JOIN stack.counters AS ct1
		ON mt1.counter_id = ct1.row_id
		JOIN stack.accounts AS ac1
		ON ct1.acc_id = ac1.row_id 
		WHERE ac1.number = acc_number
		GROUP BY ct1.service)
	ORDER BY serve;
END;
$$
LANGUAGE plpgsql;

select * from stack.select_last_pok_by_acc(266)

