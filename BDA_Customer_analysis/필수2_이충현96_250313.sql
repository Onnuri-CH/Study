#### 필수과제 2
#### 고객의 세그먼트를 새롭게 나눠 주세요.
#### 5등급으로 나눠서 (직접 여러분들이 데이터를 보고 설계하시면 됩니다.) 5개의 등급의 고객 세그먼트가 나올 수 있게 만들어 주시면 됩니다.
#### 수업 때는 3개 했지만 실제 5개까지 진행하고 모두 로직상 겹치지 않게 최대한 다 세그먼트로 나뉠 수 있도록 지정해 주세요!

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
select 	
	o.orderDate,
    sum(od.quantityOrdered * od.priceEach) as total_revenue,## 총 매출 
    count(distinct o.orderNumber) as total_orders, 
    sum(od.quantityOrdered) as totl_quantity_sold,
    count(distinct o.customerNumber) as ditinct_customers,
    round(sum(od.quantityOrdered * od.priceEach) / count(distinct o.orderNumber), 2) as avg_order_value,
    round(sum(od.quantityOrdered) / count(distinct o.orderNumber), 2) as avg_quantity_per_order
from 
	orders as o
join orderdetails od on o.orderNumber = od.orderNumber
group by o.orderDate
order by 1;

#### 고객 테이블 - 마스터 테이블
#### 고객ID, 고객명, 고객의 총 주문 횟수, 고객의 주문금액, 고객의 평균 주문금액, 마지막 주문 날짜, 마지막 주문 이후 경과된 일수 , 고객 등급 (우리가 정한 고객의 등급)
#### 고객 등급 기준이 없다
#### 저는 임의로 그냥 진행할 것 
select 
	c.customerNumber,
    c.customerName,
    count(distinct o.orderNumber) as total_orders, 
    coalesce(sum(od.quantityOrdered * od.priceEach),0) as total_revenue, 
    coalesce(round(sum(od.quantityOrdered * od.priceEach) / nullif(count(distinct o.orderNumber), 0),2),0) as avg_order_value,
    max(o.orderDate) as last_order_date,
    datediff(curdate(), max(o.orderDate)) as day_since_last_order,
    case
	  WHEN COUNT(DISTINCT o.orderNumber) > 20 AND SUM(od.quantityOrdered * od.priceEach) > 50000 THEN 'VIP 고객'
	  WHEN COUNT(DISTINCT o.orderNumber) BETWEEN 5 AND 20 AND SUM(od.quantityOrdered * od.priceEach) >= 100 THEN '일반 고객'
	  WHEN COUNT(DISTINCT o.orderNumber) < 5 AND DATEDIFF('2005-05-31', MAX(o.orderDate)) BETWEEN 180 AND 365 THEN '이탈 고객'
	  WHEN DATEDIFF('2005-05-31', MAX(o.orderDate)) > 365 THEN '휴면 고객'
	  WHEN DATEDIFF('2005-05-31', MIN(o.orderDate)) < 30 THEN '신규 고객'
	  ELSE '기타'
	end as customer_seg
from 
    customers as c
left join orders as o on o.customerNumber = c.customerNumber
left join orderdetails as od on od.orderNumber = o.orderNumber    
group by c.customerNumber;