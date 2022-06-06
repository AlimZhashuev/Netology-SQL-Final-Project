 --Task 1. � ����� ������� ������ ������ ���������?
select a.city, count(a.city)    --������� �����, � ���������� ����������, ��������� COUNT,
from airports a					--�� ������� � �����������
group by a.city  				-- ��������� �� �������
having count(a.city)>1 			-- ��� �������, ��� ���������� ���������� � ������ ������ ������.

--Task 2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������? //������������ ���������
select a2.airport_code, a2.airport_name  -- �������� ������ ���������� ������ � ����� ��������� 
from (select  aircraft_code, "range"  	 -- � ���������� �������� ��� �������� � ��� ���������
	 from aircrafts a					 
     order by "range" desc 				 -- ��������������� �� ��������� �� ����������� � ����������
	 limit 1) a_range					 -- ������������ �� ������ ������(����� �������� ������������ ���������)
join flights f on f.aircraft_code = a_range.aircraft_code   --������������ ������� � �������
join airports a2 on a2.airport_code = f.departure_airport or (a2.airport_code = f.arrival_airport)  ----������������ ������� � �����������
group by a2.airport_code -- ���������� �� ������������ ���� ���������

--Task 3. ������� 10 ������ � ������������ �������� �������� ������ // ������������ �������� LIMIT
select (actual_departure - scheduled_departure) delay  -- �������� ������� ����� ����������� �������� ������(scheduled) � ��������(actual) 
from flights f 
where  actual_departure is not null					   -- ��� ���������� ������
order by delay desc 								   -- ��������� �� ������� ������� �� ���������� � ��������� 
limit 10											   -- �������� ������ 10 �����, � ������� ����� ���������� �������� ������


--Task 4. ���� �� �����, �� ������� �� ���� �������� ���������� ������? // ������������ ������ ��� JOIN

select b.book_ref booking_num   -- ������� ������ ������, �� ������� �� �������� ���������� ������ 
from bookings b 
join tickets t on t.book_ref  = b.book_ref 				-- ��������� ������� � �������� � ��������������
join ticket_flights tf on tf.ticket_no = t.ticket_no 	-- ������������ ������� tickets_flights (����� ��� ������ �������, ������� ���� � ��������) 
left join boarding_passes bp on bp.ticket_no = tf.ticket_no --���������� LEFT JOIN, ����� ������������ ������ �� ������� � ����������� �������� 
where bp.ticket_no  is null                                --��������������, ���, ���	��������� NULL - ���������� �� �������, ��� ������ � ������� � SELECT											
group by  b.book_ref 


--Task 5. ������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
--�.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ 
--� ������� ���.  -- // ������������ ������� �������, ���������� ���/� CTE


--������� cte, � ������� �������� ��������� ���������� ���� ��� ������ ������ ��������
--����� � ������� �������� ���������� ������� ���� � �������� �� ������ ���������� ����� (count(bp.seat_no))
-- �������� ���������� ����������� �� ��������������� �������	
-- ��� ���������� ����� � ����������� ������, ���������� ������� ������� � �������� SUM
-- ��� ��� ��� ���������� ��������� �� ���������� � ������� ���, � prtition by ���������� �������� ������ � ���� ������) 
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



	

--Task 6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������. // ����������� ���������/����, �������� ROUND

select a.model,  cnt.acnt/(select count(f2.flight_id)  			-- ���������� ����� ���������� ������ count(f2.flight_id) � ���������� ��� ����� ��� ����������� ����������� ����������� 
				from flights f2)::dec*100 "part of total flights, %"
from(															--� ���������� �������� ���������� ��������� �� �� ����� �� ������� ������
	select f.aircraft_code, count(f.aircraft_code) acnt
	from flights f 
	group by f.aircraft_code) cnt
join aircrafts a on a.aircraft_code =cnt.aircraft_code
order by a.model 

--Task 7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������? // ������������ CTE
 
	with cte_conditions as (			--� cte ���������� ������������ ��������� ������ ��� ������ ������ � ����������� ��� ������ ������
select tf.flight_id, tf.fare_conditions,
	case when tf.fare_conditions = 'Economy' then max(tf.amount) end Eco,
	case when tf.fare_conditions = 'Business' then min (tf.amount)  end Bus 
from ticket_flights tf
	group by tf.flight_id, tf.fare_conditions)
select f.flight_id, a.city					-- � ������ ������� ������� ������ �������, ��� �������, ��� ������������ ��������� �������� ������� ������
from flights f   																-- ����� ������ ����������� ������� ������ (����� ������� ���)
	join cte_conditions cte_c  on cte_c.flight_id = f.flight_id
	join airports a on f.arrival_airport = a.airport_code
	group by f.flight_id, a.city 
	having max(cte_c.Eco) > min(cte_c.Bus)

--Task 8. ����� ������ �������� ��� ������ ������? // ������������  ��������� ������������ � ����������� FROM,
													--�������������� ��������� ������������� (���� �������� �����������, �� ��� �������������)
													--�������� EXCEPT
	
	create view cities as(						-- ������� �������������, ������� ������ � ���� ������ ���� ������� ����������� � ��������
select   a.city departure , a2.city arrival  														   -- ����� �������� ���� ������ �����
from flights f 
	join airports a on f.departure_airport = a.airport_code 
	join airports a2 on f.arrival_airport  = a2.airport_code)

	select a.city departure , a2.city arrival  -- �������� ��� ��������� ���������� ������� ����������� � �������� � ������� ��������� ������������
from airports a, airports a2					
	where a.city > a2.city  				   -- ������ ��������� ���������� ����
	except 									   -- � select ���������� ������ �� ����������� ���, ��� ���� � ������������ cities 
select* from cities							   -- �� ����, �������� ������, ����� �������� ��� ������ ������     


-- Task 9. ��������� ���������� ����� �����������, ���������� ������� �������,
--�������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� ����� // ������������ �������� RADIANS 
																								 --��� ������������� sind/cosd
																								 --������������ �������� CASE 


--�������� ���������� ������ ���������� ����������� � ��������, ����� �������� ���� ������ �����
--�� ������� �������� ���������� ����� �����������
-- ������������ ������� � ����������, � ������������ � ������, ����������  ������������ ��������� ������ ���������� �����
-- � ��������� ������������� �� ��������� ������ �� ���������� ����� �����������
-- � ������� ��������� CASE ������� ��������������� ���������, �������� ���������� ��������
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
	
	
	