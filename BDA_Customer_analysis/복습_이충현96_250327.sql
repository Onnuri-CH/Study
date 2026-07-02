### 지표설계
### 고객별 주문에 대한 내용도 필요
### 고객 입장에서 총 주문, 총 구매금액, 평균 주문금액, 구매빈도 - 큰 지표
### 좀 더 세분화해서 바라볼 수 있는 지표는 무엇이 있는가??
### 고객 충성도나 고객 CLV(생애가치)
### 고객의 여러 세그먼트 재구매 여부
### 활성화 고객 여부
### 이탈 여부
### 재구매율
### 평균 장바구니 크기
### 신규구매 여부(기준을 만들면 만들 수 있다)

### CTE1. 고객별의 첫 구매와 마지막 구매 날짜 등을 메타로 만든 테이블
WITH first_last_orders AS (
  SELECT 
    customerNumber,
    MIN(orderDate) AS first_order_date,
    MAX(orderDate) AS last_order_date
  FROM orders
  GROUP BY customerNumber
),

-- CTE2. 고객별 주문 요약
purchase_summary AS (
  SELECT 
    o.customerNumber,
    COUNT(o.orderNumber) AS total_orders,
    SUM(od.priceEach * od.quantityOrdered) AS total_sales,
    AVG(od.priceEach * od.quantityOrdered) AS AOV,
    COUNT(o.orderNumber) / NULLIF(TIMESTAMPDIFF(MONTH, MIN(o.orderDate), CURDATE()), 0) AS purchase_frequency
  FROM orders AS o
  JOIN orderdetails AS od ON o.orderNumber = od.orderNumber
  GROUP BY o.customerNumber
),

-- CTE3. 고객 충성도 + CLV 등
customer_loyalty AS (
  SELECT 
    o.customerNumber,
    CASE 
      WHEN COUNT(o.orderNumber) > 1 THEN 1
      ELSE 0
    END AS repeat_customer,
    SUM(od.quantityOrdered * od.priceEach) * COUNT(o.orderNumber) / COUNT(DISTINCT YEAR(o.orderDate)) AS CLV,
    CASE 
      WHEN MAX(o.orderDate) >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) THEN 1
      ELSE 0
    END AS active_last_6months
  FROM orders AS o
  JOIN orderdetails AS od ON o.orderNumber = od.orderNumber
  GROUP BY o.customerNumber
),

-- CTE4. 신규/재구매/장바구니 등
new_customers AS (
  SELECT 
    o.customerNumber,
    CASE 
      WHEN MIN(o.orderDate) >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) THEN 1
      ELSE 0
    END AS new_customer,
    CASE 
      WHEN COUNT(o.orderNumber) > 1 THEN 1
      ELSE 0
    END AS repeat_purchase_rate,
    SUM(od.quantityOrdered) / COUNT(o.orderNumber) AS avg_basket_size
  FROM orders AS o
  JOIN orderdetails AS od ON o.orderNumber = od.orderNumber
  GROUP BY o.customerNumber
)

SELECT 
  c.customerNumber,
  c.customerName,
  c.country,
  flo.first_order_date,
  flo.last_order_date,
  nc.avg_basket_size
FROM customers AS c
LEFT JOIN first_last_orders AS flo ON c.customerNumber = flo.customerNumber
LEFT JOIN purchase_summary AS ps ON c.customerNumber = ps.customerNumber
LEFT JOIN customer_loyalty AS cl ON c.customerNumber = cl.customerNumber
LEFT JOIN new_customers AS nc ON c.customerNumber = nc.customerNumber;


### 고객의 충성도나 고객 CLV(생애가치)
### 고객의 여러 세그먼트 재구매 여부
### orderdate Number 카운트가 > 2 재구매한 사람
### 활성화 고객 여부
### 월단위, 기업 마다 단위의 기준은 다름 (산업 도메인에 따라)
### 이탈여부
### 마지막 주문 후에 -> 경과를 지켜보는 것 가장 마지막 주문한 기준과 현재 날짜랑 비교해서 이게 6개월 넘어간다. 이탈고객으로 간주한다.
### CLV - CLV를 계산하는 방법이 다양함

### 평균 장바구니 크기
### 재구매율 = 재구매한 수 / 1
### 한 주문에서 얼마나 많은 quantity 담았는가
### 신규 구매 여부 (기준을 만들면 만들 수 있다), 6개월 기준으로 같은 기간에 따른 간주로 최초 주문 간주로 해야할 것 같다.

select o.customerNumber,
	count(o.orderNumber) as total_orders,
    sum(od.priceEach * od.quantityOrdered) as total_sales,
    avg(od.priceEach * od.quantityOrdered) as AOV,
    COUNT(o.orderNumber) / NULLIF(TIMESTAMPDIFF(MONTH, MIN(o.orderDate), CURDATE()), 0) AS purchase_frequency 
from orders as o
join orderdetails as od on o.orderNumber = od.orderNumber
group by o.customerNumber;

select o.customerNumber,
	case when count(o.orderNumber) > 1 then 1 else 0 end repeat_customer,
    sum(od.quantityOrdered * od.priceEach) * count(o.orderDate) / count(distinct year(o.orderDate)) as CLV,
    -- ### 실제 구매한 금액 고객 별로 존재. 월 단위 특정 기간 단위 간단하게 나눠서 고객 생애가치avg
    -- ### 활성화 고객 6개월 이내에 구매했는지 (활동구매 1, 아니면 0)
    case when max(o.orderDate) >= date_sub(curdate(), interval 6 month) then 1 else 0 end activate_last_6month
    ### 이탈 여부도 동일하게 할 수 있다.
    from orders as o
    join orderdetails as od on o.orderNumber = od.orderNumber
    group by o.customerNumber;
    
	select 
		o.customerNumber,
		## 최근 6개월 내에 구매했는가?
		case when min(o.orderDate) >= date_sub(curdate(), interval 6 month) then 1 else 0 end new_customer,
		count(o.orderNumber) > 1 as repeat_purchase_rate,
		sum(od.quantityOrdered) / count(o.orderNumber) as avg_basket_size
	from orders as o
	join orderdetails as od
	group by o.customerNumber;
select * from customers;
select * from orders;
select * from orderdetails;