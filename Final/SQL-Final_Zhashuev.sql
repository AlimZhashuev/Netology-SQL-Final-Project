 --Task 1. В каких городах больше одного аэропорта?
select a.city, count(a.city)    --Выводим город, и количество аэропортов, используя COUNT,
from airports a					--из таблицы с аэропортами
group by a.city  				-- группируя по городам
having count(a.city)>1 			-- при условии, что количество аэропортов в городе больше одного.

--Task 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета? //использовать подзапрос
select a2.airport_code, a2.airport_name  -- получаем список аэропортов вместе с кодом аэропорта 
from (select  aircraft_code, "range"  	 -- в подзапросе получаем код самолета и его дальность
	 from aircrafts a					 
     order by "range" desc 				 -- отсортированные по дальности от наибоольшей к наименьшей
	 limit 1) a_range					 -- ограничиваем по первой строке(чтобы получить максимальную дальность)
join flights f on f.aircraft_code = a_range.aircraft_code   --присоединяем таблицу с рейсами
join airports a2 on a2.airport_code = f.departure_airport or (a2.airport_code = f.arrival_airport)  ----присоединяем таблицу с аэропортами
group by a2.airport_code -- группируем по трехзначному коду аэропорта

--Task 3. Вывести 10 рейсов с максимальным временем задержки вылета // Использовать оперетор LIMIT
select (actual_departure - scheduled_departure) delay  -- получаем разницу между планируемым временем вылета(scheduled) и реальным(actual) 
from flights f 
where  actual_departure is not null					   -- для вылетевших рейсов
order by delay desc 								   -- сортиовка по разнице времени от наибольшей к наимеьшей 
limit 10											   -- получаем первые 10 строк, в которых имеем наибольшую задержку вылета


--Task 4. Были ли брони, по которым не были получены посадочные талоны? // Использовать верный тип JOIN

select b.book_ref booking_num   -- выводим список броней, по которым не получены посадочные талоны 
from bookings b 
join tickets t on t.book_ref  = b.book_ref 				-- соединяем таблицы с билетами и бронированиями
join ticket_flights tf on tf.ticket_no = t.ticket_no 	-- присоединяем таблицу tickets_flights (имеем все номера билетов, которые есть в принципе) 
left join boarding_passes bp on bp.ticket_no = tf.ticket_no --используем LEFT JOIN, чтобы присоединить данные из таблицы с посадочными талонами 
where bp.ticket_no  is null                                --соответственно, там, где	получится NULL - посадочный не получен, эти данные и выводим в SELECT											
group by  b.book_ref 


--Task 5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
--Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах 
--в течении дня.  -- // Использовать Оконную функцию, Подзапросы или/и CTE


--создаем cte, В котором получаем возможное количество мест для каждой модели самолета
--далее в запросе получаем количество занятых мест в самолете на каждом вылетевшем рейсе (count(bp.seat_no))
-- получаем процентное соотношение по соответствующей формуле	
-- для получается суммы с нарастающим итогом, используем оконную функцию с опрацией SUM
-- так как нас интересует результат по аэропортам в течении дня, в prtition by используем аэропорт вылета и дату вылета) 
with cte_seats as(							
select s.aircraft_code, count(s.seat_no) seats_c
from seats s 
	group by s.aircraft_code)
select f.flight_id, f.departure_airport,  cte.seats_c total_cnt_of_seats,  count(bp.seat_no) cnt_of_occuated_seats,  
	   round((cte.seats_c - count(bp.seat_no))/cte.seats_c:: dec,2)*100 "free_seats, %", f.actual_departure,
	   sum(count(bp.seat_no)) over (partition by (f.departure_airport, f.actual_departure::date) order by f.actual_departure) count_of_passengers
from flights f 
		join boarding_passes bp on bp.flight_id = f.flight_id 
		join cte_seats cte on cte.aircraft_code = f.aircraft_code 
		where f.actual_departure is not null
		group by f.flight_id, cte.seats_c, cte.aircraft_code
		order by f.actual_departure 



	

--Task 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества. // Использоать подзапрос/окно, оператор ROUND

select a.model,  cnt.acnt/(select count(f2.flight_id)  			-- определяем общее количество рейсов count(f2.flight_id) и используем это число для определения процентного соотношения 
				from flights f2)::dec*100 "part of total flights, %"
from(															--в подзапросе получаем количество самолетов по их типам из таблицы рейсов
	select f.aircraft_code, count(f.aircraft_code) acnt
	from flights f 
	group by f.aircraft_code) cnt
join aircrafts a on a.aircraft_code =cnt.aircraft_code
order by a.model 

--Task 7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета? // Использовать CTE
 
	with cte_conditions as (			--в cte определяем максимальную стоимость билета для класса Эконом и минимальную для класса Бизнес
select tf.flight_id, tf.fare_conditions,
	case when tf.fare_conditions = 'Economy' then max(tf.amount) end Eco,
	case when tf.fare_conditions = 'Business' then min (tf.amount)  end Bus 
from ticket_flights tf
	group by tf.flight_id, tf.fare_conditions)
select f.flight_id, a.city					-- в оснвом запросе выводим список городов, при условии, что максимальная стоимость перелета классом Эконом
from flights f   																-- будет больше минимальной классом Бизнес (таких городов нет)
	join cte_conditions cte_c  on cte_c.flight_id = f.flight_id
	join airports a on f.arrival_airport = a.airport_code
	group by f.flight_id, a.city 
	having max(cte_c.Eco) > min(cte_c.Bus)

--Task 8. Между какими городами нет прямых рейсов? // Использовать  Декартово произведение в предложении FROM,
													--Самостоятельно созданные представления (если облачное подключение, то без представления)
													--Оператор EXCEPT
	
	create view cities as(						-- создаем представление, которое хранит в себе список всех городов отправления и прибытия
select   a.city departure , a2.city arrival  														   -- между которыми есть прямые рейсы
from flights f 
	join airports a on f.departure_airport = a.airport_code 
	join airports a2 on f.arrival_airport  = a2.airport_code)

	select a.city departure , a2.city arrival  -- получаем все возможные комбинации городов отправление и прибытия с помощью декартова произведения
from airports a, airports a2					
	where a.city > a2.city  				   -- причем исключаем зеркальные пары
	except 									   -- в select отправляем данные за исключением тех, что есть в педставлении cities 
select* from cities							   -- то есть, остаются города, между которыми нет прямых рейсов     


-- Task 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами,
--сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы // Использовать Оператор RADIANS 
																								 --или использование sind/cosd
																								 --Использовать оператор CASE 


--получаем уникальный список аэропортов отправления и прибытия, между которыми есть прямые рейсы
--по формуле получаем расстояние между аэропортами
-- присоединяем таблицы с самолетами, в соответствии с рейсом, определяем  максимальную дальность полета воздушного судна
-- с проверяем соответствует ли дальность полета ВС расстоянию между аэропортами
-- с помощью оператора CASE выводим соответствующее сообщение, согласно резултатам проверки
select distinct  a.airport_name  departure , a2.airport_name  arrival, a3."range",
	round(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371)  distance,
case when 
	(round(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude))*6371)) < a3."range"
	then 'arrived' 
	else 'crushed'end _status
from flights f
	join airports a  on a.airport_code = f.departure_airport 
	join airports a2  on a2.airport_code = f.arrival_airport 
	join aircrafts a3 on a3.aircraft_code = f.aircraft_code 
	order by a.airport_name , a2.airport_name  
	
	
	