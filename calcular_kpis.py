
from pathlib import Path
import duckdb

# Rutas del proyecto
BASE_DIR = Path(__file__).resolve().parent
DW_DIR = BASE_DIR / "dw"
DB_PATH = BASE_DIR / "warehouse.duckdb"

DW_DIR.mkdir(exist_ok=True)

# Consultas para calcular los KPI
consultas = {
    "kpi_ventas_totales": """
        SELECT SUM(total_amount) AS ventas_totales
        FROM fact_sales_order
        WHERE status IN ('PAID', 'FULFILLED')
    """,

    "kpi_usuarios_activos": """
        SELECT COUNT(DISTINCT customer_key) AS usuarios_activos
        FROM fact_web_session
        WHERE customer_key IS NOT NULL
    """,

    "kpi_ticket_promedio": """
        SELECT AVG(total_amount) AS ticket_promedio
        FROM fact_sales_order
        WHERE status IN ('PAID', 'FULFILLED')
    """,

    "kpi_nps": """
        SELECT
            100.0 * (
                COUNT(*) FILTER (WHERE score >= 9)
                - COUNT(*) FILTER (WHERE score <= 6)
            ) / COUNT(*) AS nps
        FROM fact_nps
    """,

    "kpi_ventas_provincia": """
        SELECT
            p.name AS provincia,
            SUM(f.total_amount) AS ventas
        FROM fact_sales_order AS f
        JOIN dim_province AS p
            ON p.province_key = f.province_key
        WHERE f.status IN ('PAID', 'FULFILLED')
        GROUP BY p.name
        ORDER BY ventas DESC
    """,

    "kpi_ranking_productos": """
        WITH ventas AS (
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
            GROUP BY d.year, d.month, p.name
        ),
        ranking AS (
            SELECT *,
                RANK() OVER (
                    PARTITION BY year, month
                    ORDER BY ventas DESC
                ) AS ranking
            FROM ventas
        )
        SELECT *
        FROM ranking
        WHERE ranking <= 5
        ORDER BY year, month, ranking
    """
        ,

    "kpi_ventas_mensuales": """
        SELECT
            d.year,
            d.month,
            SUM(f.total_amount) AS ventas
        FROM fact_sales_order AS f
        JOIN dim_date AS d
            ON d.date_key = f.date_key
        WHERE f.status IN ('PAID', 'FULFILLED')
        GROUP BY d.year, d.month
        ORDER BY d.year, d.month
    """,

    "kpi_usuarios_activos_mensuales": """
        SELECT
            d.year,
            d.month,
            COUNT(DISTINCT f.customer_key) AS usuarios_activos
        FROM fact_web_session AS f
        JOIN dim_date AS d
            ON d.date_key = f.date_key
        WHERE f.customer_key IS NOT NULL
        GROUP BY d.year, d.month
        ORDER BY d.year, d.month
    """,

    "kpi_nps_mensual": """
        SELECT
            d.year,
            d.month,
            100.0 * (
                COUNT(*) FILTER (WHERE f.score >= 9)
                - COUNT(*) FILTER (WHERE f.score <= 6)
            ) / COUNT(*) AS nps
        FROM fact_nps AS f
        JOIN dim_date AS d
            ON d.date_key = f.date_key
        GROUP BY d.year, d.month
        ORDER BY d.year, d.month
    """
}

# Ejecutar consultas y guardar resultados
with duckdb.connect(str(DB_PATH), read_only=True) as con:
    for nombre, consulta in consultas.items():
        destino = (DW_DIR / f"{nombre}.csv").as_posix()

        con.execute(
            f"COPY ({consulta}) TO '{destino}' "
            "(HEADER, DELIMITER ',')"
        )

        print(f"Generado: dw/{nombre}.csv")

print("Todos los KPI fueron calculados.")
