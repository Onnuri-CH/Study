select * from customers;
select * from orders;
select * from products;
select * from orderdetails;

### 지표를 설계해야 한다.
### 매출
### 크게 전자의 차원에서 지표를 본다.
### 총 매출, 총 주문 수, 총 판매된 수량, 주문당 평균 매출, 주문당 평균 수량, 해당 날짜의 주문한 고객 수
### 항상 필요한 일자 기준yyyymmdd 날짜는 꼭 필요하다, ord_ymd, ord_ym 두 개의 컬럼을 만든다.

### 총 매출을 주문 수량으로 나누어 본다.
### 전체 주문 (매출) 테이블
select 
	o.orderDate,
    sum(od.quantityOrdered * od.priceEach) as total_revenue, # 총 매출
    count(distinct o.orderNumber) as total_orders,
    sum(od.quantityOrdered) as total_quantity_sold,
    count(distinct o.customerNumber) as distinct_customers,
    round(sum(od.quantityOrdered * od.priceEach) / count(distinct o.orderNumber), 2) as avg_quantity_per_order
    from orders as o
    join orderdetails as od on o.orderNumber = od.orderNumber
    group by o.orderDate
    order by 1;
    
### 고객 테이블 - 마스터 테이블
### 고객ID, 고객명, 고객의 총 주문횟수, 고객의 주문금액, 고객의 평균 주문금액, 마지막 주문날짜, 마지막 주문 이후 경과된 일수, 고객 등급(우리가 지정한 등급)
###  고객 등급 기준이 없다.
select 
	c.customerNumber,
	c.customerName,
    count(distinct o.orderNumber) as total_orders,
    coalesce(round(sum(od.quantityOrdered * od.priceEach) / nullif(count(distinct o.orderNumber),0),2),0) as avg_order_value,
    max(o.orderDate) as last_order_date,
    datediff(curdate(), max(o.orderDate)) as day_since_last_order,
    case
		when count(distinct o.orderNumber) > 20 and sum(od.quantityOrdered * od.priceEach) > 50000 then "VIP고객" 
        when count(distinct o.orderNumber) between 5 and 20 then "일반고객"
        when datediff(curdate(), max(o.orderDate)) > 365 then "휴먼고객"
	end as customer_seg
from customers as c
left join orders as o on o.customerNumber = c.customerNumber
left join orderdetails as od on od.orderNumber = o.orderNumber
group by c.customerNumber;

### 고객 50,000 VIP고객, 주문수는 10개 이상
### 주문 5~20개 정도는 일반고객
### 최근 주문한 날짜와 차이를 365일 이상이면 "휴먼 고객"으로 정의