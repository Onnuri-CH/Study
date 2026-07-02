
#### 필수과제 1
#### 위의 2개의 마트 쿼리를 검증해 주세요.
#### 명확한 검증 로직을 작성하고 -> 해당 값을 검증할 수 있는 코드와 함께 정리해서 주세요.
#### 둘 다 모두 검증해야 하고 예시는 최소 2개 이상씩 해야 합니다. - 총 최소 4개 이상 진행
select * from customers;
select * from orders;
select * from products;
select * from orderdetails;
#### 지표를 설계해야 한다. 
#### 매출
#### 크게 전사의 차원에서 지표를 본다. 
#### 총 매출 , 총 주문 수, 총 판매된 수량, 주문당 평균 매출, 주문당 평균 수량, 해당 날짜의 주문한 고객 수 
#### 항상 필요한 일자 기준 yyyyMMdd 날짜는 꼭 필요하다. ord_ymd, ord_ym 두 개의 컬럼을 만든다.

# 총매출을 주문 수량으로 나눠보자!
# 전체 주문(매출) 테이블
# 1. 전사 차원에서의 지표
select 	
	o.orderDate,
    sum(od.quantityOrdered * od.priceEach) as total_revenue,## 총 매출 
    count(distinct o.orderNumber) as total_orders, # 총 주문수
    sum(od.quantityOrdered) as totl_quantity_sold, # 총 판매된 수량
    count(distinct o.customerNumber) as ditinct_customers, # 해당 날짜에 주문한 고객 수 
    ## 주문당 평균 매출 = 총매출을 주문 수량으로 나누기
    round(sum(od.quantityOrdered * od.priceEach) / count(distinct o.orderNumber), 2) as avg_order_value,
    ## 주문당 평균 판매 수량
    round(sum(od.quantityOrdered) / count(distinct o.orderNumber), 2) as avg_quantity_per_order
from 
	orders as o
join orderdetails od on o.orderNumber = od.orderNumber
group by o.orderDate
order by 1;

# 검증 1) 특정 날짜 2023-11-11, 2023-11-14에 대한 검증
select
	o.orderDate,
    sum(od.quantityOrdered * od.PriceEach) as total_revenue_111114,	#총 매출
    count(distinct o.orderNumber) as total_orders_111114, #총 주문수
    sum(od.quantityOrdered) as total_quantity_sold_111114, #총 판매된 수량
    round(sum(od.quantityOrdered * od.PriceEach) / count(distinct o.orderNumber), 2) as avg_order_value_111114, #주문당 평균 매출
    round(sum(od.quantityOrdered) / count(distinct o.orderNumber), 2) as avg_quantity_per_order_111114, #주문당 평균 수량
    count(distinct o.customerNumber) as distinct_customers_111114
    from orders as o
    join orderdetails as od on o.orderNumber = od.orderNumber
	where o.orderDate between '2003-11-11' and '2003-11-14'
	group by o.orderDate;

#### 2. 고객 테이블 - 마스터 테이블
#### 고객 ID, 고객명, 고객의 총 주문 횟수, 고객의 주문금액, 고객 평균 주문금액, 마지막 주문 날짜, 마지막 주문 이후 경과한 일수, 고객 등급
#### VIP 고객 : 총 주문 금액 50,000, 주문수 20개 이상
#### 일반 고객 : 주문수 5-20개

select 
	c.customerNumber,
    c.customerName,
    count(distinct o.orderNumber) as total_orders, 
    coalesce(sum(od.quantityOrdered * od.priceEach),0) as total_revenue, 
    coalesce(round(sum(od.quantityOrdered * od.priceEach) / nullif(count(distinct o.orderNumber), 0),2),0) as avg_order_value,
    max(o.orderDate) as last_order_date,
    datediff(curdate(), max(o.orderDate)) as day_since_last_order,
    case
		when count(distinct o.orderNumber) > 20 and sum(od.quantityOrdered * od.priceEach) > 50000 then 'VIP 고객'
        when count(distinct o.orderNumber) between 5 and 20 then '일반 고객'
		when datediff(curdate(), max(o.orderDate)) > 365 then '휴면 고객'
	end as customer_seg
from 
    customers as c
left join orders as o on o.customerNumber = c.customerNumber
left join orderdetails as od on od.orderNumber = o.orderNumber    
group by c.customerNumber;

# 2.1 검증) VIP고객 141에 대한 검증
select 
	c.customerNumber,
    c.customerName,
    count(distinct o.orderNumber) as total_orders_141,
    sum(od.quantityOrdered * od.priceEach) as total_revenue_141,
    round(sum(od.quantityOrdered * od.priceEach)/count(distinct o.orderNumber), 2) as avg_order_value_141,
    max(o.orderDate) as last_order_Date_141,
    datediff(curdate(), max(o.orderDate)) as ay_since_last_order_141,
    case
		when count(distinct o.orderNumber) > 20 and sum(od.quantityOrdered * od.priceEach) > 50000 then 'VIP 고객'
        when count(distinct o.orderNumber) between 5 and 20 then '일반 고객'
        when datediff(curdate(), max(o.orderDate))>365 then '휴먼 고객'
	end as customer_seg 
from
	customers as c
left join orders as o on c.customerNumber = o.customerNumber
left join orderdetails as od on o.orderNumber = od.orderNumber
where c.customerNumber = 141
group by c.customerNumber;

# 2.1 검증) 휴먼고객 141에 대한 검증
select 
	c.customerNumber,
    c.customerName,
    count(distinct o.orderNumber) as total_orders_119,
    sum(od.quantityOrdered * od.priceEach) as total_revenue_119,
    round(sum(od.quantityOrdered * od.priceEach)/count(distinct o.orderNumber), 2) as avg_order_value_119,
    max(o.orderDate) as last_order_Date_119,
    datediff(curdate(), max(o.orderDate)) as ay_since_last_order_119,
    case
		when count(distinct o.orderNumber) > 20 and sum(od.quantityOrdered * od.priceEach) > 50000 then 'VIP 고객'
        when count(distinct o.orderNumber) between 5 and 20 then '일반 고객'
        when datediff(curdate(), max(o.orderDate))>365 then '휴먼 고객'
	end as customer_seg 
from
	customers as c
left join orders as o on c.customerNumber = o.customerNumber
left join orderdetails as od on o.orderNumber = od.orderNumber
where c.customerNumber = 119
group by c.customerNumber;