-- =====================================================================
-- 03_consultas.sql — Consultas para revisar el modelo y calcular KPIs
-- =====================================================================
-- Cada SELECT de este archivo se muestra en la terminal al ejecutar
-- run_sql.py. Usalo para:
--   * comprobar que las tablas se cargaron bien (cantidad de filas, nulos...)
--   * escribir las consultas clave de los KPIs que pide la consigna
--     (ventas, usuarios activos, ticket promedio, NPS, ventas por provincia,
--     ranking mensual por producto) usando las tablas del modelo estrella.
-- =====================================================================


-- Ejemplo: revisar la dimensión producto
SELECT product_key, name, category, family, list_price
FROM dim_product
ORDER BY product_key;


-- TU TURNO: agregá acá tus consultas.
-- ---------------------------------------------------------------------
-- KPI 1: VENTAS TOTALES
-- ---------------------------------------------------------------------

SELECT
    SUM(total_amount) AS ventas_totales
FROM fact_sales_order
WHERE status IN ('PAID', 'FULFILLED');
-- ---------------------------------------------------------------------
-- KPI 2: USUARIOS ACTIVOS
-- ---------------------------------------------------------------------

SELECT
    COUNT(DISTINCT customer_key) AS usuarios_activos
FROM fact_web_session
WHERE customer_key IS NOT NULL;


-- ---------------------------------------------------------------------
-- KPI 3: TICKET PROMEDIO
-- ---------------------------------------------------------------------

SELECT
    SUM(total_amount) / COUNT(*) AS ticket_promedio
FROM fact_sales_order
WHERE status IN ('PAID', 'FULFILLED');


-- ---------------------------------------------------------------------
-- KPI 4: NPS
-- ---------------------------------------------------------------------

SELECT
    (
        SUM(CASE WHEN score >= 9 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        -
        SUM(CASE WHEN score <= 6 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
    ) AS nps
FROM fact_nps;


-- ---------------------------------------------------------------------
-- KPI 5: VENTAS POR PROVINCIA
-- ---------------------------------------------------------------------

SELECT
    p.name AS provincia,
    SUM(f.total_amount) AS ventas
FROM fact_sales_order AS f
JOIN dim_province AS p
    ON p.province_key = f.province_key
WHERE f.status IN ('PAID', 'FULFILLED')
GROUP BY p.name
ORDER BY ventas DESC;


-- ---------------------------------------------------------------------
-- KPI 6: RANKING MENSUAL POR PRODUCTO
-- ---------------------------------------------------------------------

SELECT
    d.year,
    d.month,
    p.name AS producto,
    SUM(f.line_total) AS ventas
FROM fact_sales_order_item AS f
JOIN dim_date AS d
    ON d.date_key = f.date_key
JOIN dim_product AS p
    ON p.product_key = f.product_key
JOIN fact_sales_order AS o
    ON o.order_id = f.order_id
WHERE o.status IN ('PAID', 'FULFILLED')
GROUP BY
    d.year,
    d.month,
    p.name
ORDER BY
    d.year,
    d.month,
    ventas DESC;
-- ---------------------------------------------------------------------
-- RANKING MENSUAL POR PRODUCTO CON POSICIÓN
-- ---------------------------------------------------------------------

SELECT
    year,
    month,
    producto,
    ventas,
    RANK() OVER (
        PARTITION BY year, month
        ORDER BY ventas DESC
    ) AS ranking
FROM (
    SELECT
        d.year,
        d.month,
        p.name AS producto,
        SUM(f.line_total) AS ventas
    FROM fact_sales_order_item AS f
    JOIN dim_date AS d
        ON d.date_key = f.date_key
    JOIN dim_product AS p
        ON p.product_key = f.product_key
    JOIN fact_sales_order AS o
        ON o.order_id = f.order_id
    WHERE o.status IN ('PAID', 'FULFILLED')
    GROUP BY
        d.year,
        d.month,
        p.name
)
ORDER BY
    year,
    month,
    ranking;
