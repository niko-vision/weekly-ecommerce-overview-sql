
WITH 
-- Weekly sessions by channel & device
cte_session_w AS (
 SELECT 
   DATE_TRUNC(s.date, WEEK(MONDAY)) AS week_start,
              sp.device, 
              sp.channel,
              COUNT(DISTINCT s.ga_session_id) AS sessions_cnt
   FROM `DA.session_params` sp
   JOIN `DA.session` s
       ON sp.ga_session_id = s.ga_session_id
   GROUP BY week_start,sp.device,sp.channel
  ),

-- Weekly orders (unique purchasing sessions) and revenue (sum of item prices)
cte_order_w AS (
  SELECT DATE_TRUNC(s.date, WEEK(MONDAY)) AS week_start,
         sp.device, 
         sp.channel,
         COUNT(DISTINCT o.ga_session_id) AS orders_cnt,
         SUM(p.price) AS revenue
   FROM `DA.order` o
   JOIN `DA.product` p 
       ON o.item_id = p.item_id
   JOIN `DA.session_params` sp
       ON o.ga_session_id = sp.ga_session_id
   JOIN `DA.session` s
       ON o.ga_session_id = s.ga_session_id
   GROUP BY week_start,sp.device,sp.channel
 ),

-- Join sessions/orders
base AS (
   SELECT csw.week_start,
          csw.channel,
          csw.device,
          csw.sessions_cnt,
          IFNULL(cow.orders_cnt, 0) AS orders_cnt,
          IFNULL(cow.revenue, 0) AS revenue
     FROM cte_session_w csw
     LEFT JOIN cte_order_w cow
         ON csw.week_start = cow.week_start
         AND csw.device = cow.device
         AND csw.channel = cow.channel
     )

SELECT  week_start,
        channel,
        device,
        sessions_cnt,
        orders_cnt,
        ROUND(revenue,2) AS revenue
   FROM base
   ORDER BY week_start, channel, device;
