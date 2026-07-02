### 데이터 검증 방법
### 내가 추출한 값 = 비교할 값이 있으면 비교하면 된다. (정답이 잇으면 좋음)
### 여러 테이블을 join하면서 값이 틀어질 수 있으니, 이 부분이 걱정이다.
### 우리가 요약한 테이블에서 => 하나의 기준을 잡아서 실제 원천 데이터(단일 테이블 또는 여러 테이블로 간단한 join)로 비교하면 된다.
### 비교할 기준, 지표는 무엇일까? => 가장 대표적으로 검증하는 기준 중에 하나는 카운팅, sum 등의 통계값들
### 로우단으로 풀어 헤치면서 더 들어가서 검증할 수 있다. => 고객 1명을 잡고, 검증해볼 수 있다.

WITH total AS (
  SELECT  
    c.customerNumber,
    c.customerName,
    COUNT(DISTINCT o.orderNumber) AS total_orders,
    COALESCE(SUM(od.quantityOrdered * od.priceEach), 0) AS total_revenue,
    COALESCE(ROUND(SUM(od.quantityOrdered * od.priceEach) / NULLIF(COUNT(DISTINCT o.orderNumber), 0), 2), 0) AS avg_order_value,
    MAX(o.orderDate) AS last_order_date,
    DATEDIFF(CURDATE(), MAX(o.orderDate)) AS day_since_last_order,
    CASE
      WHEN COUNT(DISTINCT o.orderNumber) > 20 AND SUM(od.quantityOrdered * od.priceEach) > 50000 THEN 'VIP고객'
      WHEN COUNT(DISTINCT o.orderNumber) BETWEEN 5 AND 20 THEN '일반 고객'
      WHEN DATEDIFF(CURDATE(), MAX(o.orderDate)) > 365 THEN '휴면 고객'
    END AS customer_seg
  FROM customers AS c
  LEFT JOIN orders AS o ON o.customerNumber = c.customerNumber
  LEFT JOIN orderdetails AS od ON od.orderNumber = o.orderNumber
  GROUP BY c.customerNumber
)
SELECT customerNumber,
	total_orders
from total;

# 98 +24 =122

select count(*)
from customers
where customerNumber not in(
	select distinct customerNumber
    from orders
);

select count(customerNumber),
	count(distinct customerNumber)
from orders;

select count(customerNumber),
	count(distinct orderNumber)
from orders
group by customerNumber;

-- select count(customerNumber),
-- 	count(distinct customerNumber),
--     total_orders
-- from orders;

select count(customerNumber),
	count(distinct customerNumber)
from customers;

-- 1단계 step 전체 카운팅 기준으로 비교 
-- 한 뎁스를 더 들어가볼까?

-- select * from customers;

with total_vs as(
select 
	customerNumber,
    count(distinct orderNumber)
from orders
group by customerNumber
)
select * from total_vs;

select * from products;

### 지표설계 
### 고객 지표 상세 설계
### 고객별 주문에 대한 내용도 필요하다.
### 고객 입장에서 총 주문, 총 구매 금액, 평균 주문금액, 구매 빈도 - 큰 지표들 
### 좀 더 세분화해서 바라볼 수 있는 지표들은?
### 고객 충성도나 고객 CLV(생애 가치)
### 고객의 여러 세그먼트 재구매 여부 
### 활성화 고객 여부 
### 이탈 여부 
### 재구매율 
### 평균 장바구니 크기
### 신규구매 여부(기준을 만들면 만들 순 있다.)

### CTE1. 고객별의 첫 구매와 마지막 구매 날짜 등을 메타로 만든 테이블 
### CTE2. 고객별 주문 요약한 테이블 
### CTE3. CLV, 고객 충성도, 세그먼트 관련해서 필요
### CTE4. 재구매율, 장바구니, 신규고객  등등

With first_last_orders As(
	select 
		customerNumber,
        min(orderDate) as first_order_date,
        max(orderDate) as last_order_date
	from orders
    group by 
		customerNumber
),
purchase_summary as (
	select 
		o.customerNumber,
        count(o.orderNumber) as total_orders,
        sum(od.priceEach * od.quantityOrdered) as total_sales,
        avg(od.priceEach * od.quantityOrdered) as AOV,
        count(o.orderNumber) / nullif(timestampdiff(Month, Min(o.orderDate), curdate()),0) as purcahse_frequency 
	from orders as o
    join orderdetails as od on o.orderNumber = od.orderNumber
    group by o.customerNumber
),




### 고객 충성도나 고객 CLV(생애 가치)
### 고객의 여러 세그먼트 재구매 여부 
### orderNumber 카운트가 >2 재구매한 사람
### 활성화 고객 여부 
### 월단위, 기업에 가시면 단위의 기준은 다 다를 것이다. (산업의 도메인에 따라)
### 6개월의 기준으로 구매 여부에따라 활성화 고객, 아닌 고객 
### 이탈 여부 
### last 주문한 후에 -> 경과를 지켜보는 것 가장 마지막 주문한 기준과 현재날짜랑 비교해서 이게 6개월 넘어간다. 이탈고객으로 간주한다.
### CLV - CLV를 계산하는 방법이 다양하다. -> 다음시간에 짧게 이야기 하면서 쿼리로 진행하고 


### 평균 장바구니 크기
### 재구매율 =  재구매한 수 / 1
### 한 주문에서 얼마나 많은 quantity 담았느냐~?
### 신규구매 여부(기준을 만들면 만들 순 있다.) 6개월 기준으로 같은 기간에 따른 간주로 최초 주문 간주로 해야할 것 같다.




-- 	select 
-- 		o.customerNumber,
--         count(o.orderNumber) as total_orders,
--         sum(od.priceEach * od.quantityOrdered) as total_sales,
--         avg(od.priceEach * od.quantityOrdered) as AOV,
--         count(o.orderNumber) / nullif(timestampdiff(Month, Min(o.orderDate), curdate()),0) as purcahse_frequency 
-- 	from orders as o
--     join orderdetails as od on o.orderNumber = od.orderNumber
--     group by o.customerNumber;


select * from customers;
select * from orders;
select * from orderdetails;