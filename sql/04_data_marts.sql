-- DATA MART 1: VENTAS
CREATE OR REPLACE TABLE dm_ventas AS
SELECT
    d.year,
    d.month,
    f.date_key,
    f.channel_key,
    f.province_key,
    SUM(f.total_amount) AS ventas_totales,
    COUNT(DISTINCT f.order_id) AS cantidad_pedidos,
    SUM(f.total_amount) / NULLIF(COUNT(DISTINCT f.order_id), 0)
        AS ticket_promedio
FROM fact_sales_order f
JOIN dim_date d
    ON d.date_key = f.date_key
WHERE f.status IN ('PAID', 'FULFILLED')
GROUP BY
    d.year, d.month, f.date_key,
    f.channel_key, f.province_key;


-- DATA MART 2: USUARIOS ACTIVOS
CREATE OR REPLACE TABLE dm_usuarios AS
SELECT
    d.year,
    d.month,
    f.date_key,
    COUNT(DISTINCT f.customer_key) AS usuarios_activos
FROM fact_web_session f
JOIN dim_date d
    ON d.date_key = f.date_key
WHERE f.customer_key IS NOT NULL
GROUP BY d.year, d.month, f.date_key;


-- DATA MART 3: NPS
CREATE OR REPLACE TABLE dm_nps AS
SELECT
    d.year,
    d.month,
    f.date_key,
    f.channel_key,
    COUNT(*) AS total_respuestas,
    COUNT(*) FILTER (WHERE f.score >= 9) AS promotores,
    COUNT(*) FILTER (WHERE f.score <= 6) AS detractores,
    100.0 * (
        COUNT(*) FILTER (WHERE f.score >= 9)
        - COUNT(*) FILTER (WHERE f.score <= 6)
    ) / NULLIF(COUNT(*), 0) AS nps
FROM fact_nps f
JOIN dim_date d
    ON d.date_key = f.date_key
GROUP BY d.year, d.month, f.date_key, f.channel_key;