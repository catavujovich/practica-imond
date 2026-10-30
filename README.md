# Práctica — Introducción al Marketing Online y los Negocios Digitales

Este repositorio tiene los datos de **EcoBottle AR** para la práctica.

- **Consigna:** [Práctica](https://docs.google.com/document/d/15RNP3FVqLjO4jzh80AAkK6mUR5DOLqPxLjQxqvdzrYg/edit?usp=sharing)
- **Diagrama de las tablas de origen (DER):** [ver más abajo](#diagrama-de-las-tablas-de-origen-der)

## ¿Qué hay en el repositorio?

```
raw/               los datos de origen: un archivo CSV por tabla (en SQL: raw.<tabla>)
sql/               acá escribís tus transformaciones en SQL        ← tu trabajo va acá
run_sql.py         ejecuta tus archivos SQL y arma el data warehouse
requirements.txt   lo que hay que instalar (DuckDB)
dw/                el data warehouse: se crea solo al ejecutar run_sql.py
generator/         el programa que creó los datos de raw/ (no hace falta usarlo)
assets/            el diagrama de tablas de origen (DER)
```

> ⚠️ **No modifiques los archivos de `raw/`.** Son los datos de origen. Tus consultas SQL los leen y el resultado queda en `dw/`.

## Los datos en un minuto

- Son una **foto del sistema de ventas** de EcoBottle, tomada el **30/09/2025 a las 23:59:59**.
- Tienen los pedidos del **01/01/2024 al 30/09/2025**.
- Los montos están en **pesos argentinos**, y los precios de lista **no incluyen IVA**.
- Las fechas y horas están en **hora de Argentina**.
- Una **celda vacía** en un CSV significa que ese dato no existe. En SQL aparece como `NULL`.

## Las tablas

| Archivo | Qué guarda | Filas |
|---|---|---:|
| `channel.csv` | Los 2 canales de venta: `ONLINE` (web) y `OFFLINE` (tiendas) | 2 |
| `province.csv` | Las 4 provincias donde opera la empresa | 4 |
| `product_category.csv` | Categorías de producto: *Bottles* → *Classic* y *Sport* | 3 |
| `product.csv` | Los 2 productos: Classic A y Sport B | 2 |
| `store.csv` | Las 4 tiendas físicas | 4 |
| `customer.csv` | Los clientes | ~3.500 |
| `address.csv` | Las direcciones de clientes y tiendas | ~3.800 |
| `sales_order.csv` | Los pedidos: quién compró, cuándo, por qué canal y cuánto pagó | ~12.000 |
| `sales_order_item.csv` | Los productos de cada pedido (una fila por producto) | ~14.500 |
| `payment.csv` | El pago de cada pedido | ~12.000 |
| `shipment.csv` | Los envíos por correo | ~7.000 |
| `web_session.csv` | Las visitas a la web | ~100.000 |
| `nps_response.csv` | Las respuestas a la encuesta de satisfacción (NPS) | ~3.000 |

En SQL, cada archivo es una tabla del esquema `raw`: `raw/sales_order.csv` se consulta como `raw.sales_order`.

### Diagrama de las tablas de origen (DER)

Cada caja es una tabla (un CSV de `raw/`) y cada línea une una clave foránea (FK) con la clave primaria (PK) a la que apunta.

![Diagrama entidad-relación de las tablas de origen](./assets/DER.png)

## Cómo leer los datos

### Pedidos
- **Pedido online:** `store_id` está vacío.
- **Compra en tienda:** `store_id` indica la tienda, y la "dirección de envío" es la dirección de la tienda (el cliente se lleva el producto en el momento).
- **Las cuentas siempre cierran:**
  - `line_total` = cantidad × precio − descuento
  - `subtotal` = suma de los `line_total` del pedido
  - `tax_amount` = 21 % del subtotal (IVA)
  - `total_amount` = subtotal + IVA + costo de envío

### Estados de un pedido (`sales_order.status`)

| Estado | Qué significa | ¿Cuenta como venta? |
|---|---|:---:|
| `CREATED` | Se hizo el pedido pero todavía no se pagó | No |
| `PAID` | Está pagado pero todavía no se entregó | Sí |
| `FULFILLED` | Ya se entregó (o se compró en la tienda) | Sí |
| `CANCELLED` | Se canceló: el pago fue rechazado, no se pagó a tiempo o el cliente se arrepintió | No |
| `REFUNDED` | Se entregó, pero después se devolvió el dinero | No |

### Pagos y envíos
- Cada pedido tiene **un pago**. Si el pago no se concretó, `paid_at` está vacío.
- **Solo tienen envío** (`shipment`) los pedidos que viajan por correo: los online y algunos que la tienda manda a domicilio. Las compras en tienda no tienen envío.
- **Estados del envío:**
  - `READY`: se está preparando.
  - `SHIPPED`: está viajando.
  - `DELIVERED`: se entregó.
  - `CANCELLED`: no salió.

### Clientes y visitas a la web
- Un cliente con `status = 'I'` dio de baja su cuenta. Sus compras anteriores siguen en los datos.
- En `web_session`, un `customer_id` vacío es un visitante que no inició sesión.
- **Origen de la visita** (`source`):
  - `ads`: publicidad en redes.
  - `direct`: entró directo o desde el newsletter.
  - `referral`: vino de otro sitio o del newsletter.
  - `organic`: buscadores.

### Encuesta NPS
- **Cuándo se manda:**
  - Pedidos entregados por correo: **7 días después de la entrega**.
  - Compras en tienda: **al día siguiente**.
- El puntaje va de 0 a 10. Un `customer_id` vacío es una respuesta anónima.
- La encuesta **no tiene número de pedido**: se relaciona con el cliente (`customer_id`) y con el canal (`channel_id`).

## Para empezar

Vas a escribir las transformaciones en **SQL** usando **DuckDB**, una base de datos que se instala con Python. No necesita servidor ni crear cuentas.

### 1. Preparar tu computadora (una sola vez)

Necesitás tener instalado Python 3.9 o más nuevo y Git. Primero hacé un **fork** de este repositorio en GitHub y después, en la terminal:

```bash
git clone URL-DE-TU-FORK
cd NOMBRE-DE-LA-CARPETA
python -m venv .venv
```

Activá el entorno virtual:

- **Mac / Linux:** `source .venv/bin/activate`
- **Windows:** `.venv\Scripts\activate`

Instalá DuckDB:

```bash
pip install -r requirements.txt
```

> En Mac, si el comando `python` no existe, usá `python3`. Cada vez que abras una terminal nueva, volvé a activar el entorno.

### 2. Explorar las tablas de origen

```bash
python run_sql.py --explorar
```

Abre DuckDB en el navegador con las 13 tablas de origen cargadas. Hacé clic en una tabla para ver sus columnas y datos, y escribí consultas para conocerla:

```sql
SELECT * FROM raw.sales_order LIMIT 10;
DESCRIBE raw.sales_order;
```

- **No ejecuta tus archivos de `sql/`**, así que funciona aunque todavía no hayas escrito nada o tengas errores.
- **Necesita internet.** Sin conexión se abre una consola SQL en la terminal: terminás cada consulta con `;` y salís escribiendo `salir`.
- **Para cerrar,** volvé a la terminal y presioná Enter.

### 3. Escribir tus transformaciones en SQL

| Archivo | Qué va adentro |
|---|---|
| `sql/01_dimensiones.sql` | Las tablas de dimensiones. Tiene un **ejemplo resuelto** (`dim_product`) para que veas cómo se hace. |
| `sql/02_hechos.sql` | Las tablas de hechos, con sus `FOREIGN KEY` hacia las dimensiones. |
| `sql/03_consultas.sql` | Consultas para revisar el modelo y calcular los KPIs. |

Cuando una consulta te funciona mientras explorás, pasala al archivo que corresponde. Podés agregar más archivos: se ejecutan en orden alfabético (`01_...`, `02_...`, `03_...`).

### 4. Armar el data warehouse

```bash
python run_sql.py
```

Esto hace cuatro cosas:

1. Crea la base de datos `warehouse.duckdb` desde cero.
2. Ejecuta tus archivos de `sql/` en orden y muestra en la terminal el resultado de cada `SELECT`.
3. Guarda cada tabla que creaste como CSV en `dw/`. **Esos CSV son los que después abrís en Power BI.**
4. Dibuja tu modelo estrella en `dw/modelo_estrella.md`.

Si hay un error, te dice en qué archivo y en qué sentencia está y por qué falló. Lo corregís y volvés a ejecutar. Como todo se arma desde cero cada vez, no hace falta borrar tablas a mano.

> La base `warehouse.duckdb` no se sube a GitHub (está en `.gitignore`): cualquiera la vuelve a crear con `python run_sql.py`.

### 5. Ver tu modelo

- **El diagrama:** abrí `dw/modelo_estrella.md` en GitHub y vas a ver el modelo dibujado, con las claves y las relaciones. Podés copiarlo en tu README. En VS Code se ve con la extensión *Markdown Preview Mermaid Support*.
- **Tus tablas en el navegador:** `python run_sql.py --ui` arma el data warehouse y después abre DuckDB con tus tablas y las de origen, para revisar resultados y armar gráficos rápidos.

### Mini guía de SQL en DuckDB

```sql
-- Ver las primeras filas de una tabla de origen
SELECT * FROM raw.sales_order LIMIT 10;

-- Ver sus columnas y tipos
DESCRIBE raw.sales_order;

-- Agrupar por mes
SELECT DATE_TRUNC('month', order_date) AS mes, COUNT(*) AS pedidos
FROM raw.sales_order
GROUP BY mes
ORDER BY mes;
```

- **Datos vacíos:** se buscan con `IS NULL`, y `COALESCE(columna, valor)` reemplaza un vacío por un valor.
- **Más ayuda:** [documentación de SQL de DuckDB](https://duckdb.org/docs/current/sql/introduction.html).

## ¿Y la carpeta `generator/`?

Es el programa que **inventó estos datos** simulando el negocio: clientes que se registran, compran, pagan, reciben el envío y responden la encuesta. **No lo necesitás para la práctica.** Si te interesa ver cómo se arma un conjunto de datos de prueba, podés leerlo; el detalle está en [`generator/README.md`](./generator/README.md).

Si alguna vez querés volver a generar los datos o comprobar que están bien:

```bash
python generator/generate_raw.py     # vuelve a crear los CSV de raw/ (salen idénticos)
python generator/validate_raw.py     # revisa que los datos cumplan todas las reglas
```

## Desarrollo del Data Warehouse

Para el análisis comercial de EcoBottle AR se implementó un Data Warehouse utilizando DuckDB y siguiendo el enfoque de modelado dimensional de Kimball.

### Modelo estrella

Se crearon seis tablas de dimensiones:

- `dim_date`: información de fechas, meses y años.
- `dim_customer`: información de los clientes.
- `dim_product`: información de los productos.
- `dim_channel`: canales de venta.
- `dim_province`: provincias.
- `dim_store`: tiendas físicas.

También se crearon seis tablas de hechos:

- `fact_sales_order`: pedidos de venta.
- `fact_sales_order_item`: productos incluidos en cada pedido.
- `fact_payment`: pagos.
- `fact_shipment`: envíos.
- `fact_web_session`: sesiones web.
- `fact_nps`: respuestas de satisfacción.

Las transformaciones se encuentran en `sql/01_dimensiones.sql` y `sql/02_hechos.sql`. El diagrama generado del modelo está disponible en `dw/modelo_estrella.md`.

### Consultas SQL y KPIs

Las consultas comerciales se encuentran en `sql/03_consultas.sql`.

Además, se desarrolló el script `calcular_kpis.py`, que calcula y exporta indicadores comerciales utilizando SQL en DuckDB.

Los indicadores incluyen ventas totales, usuarios activos, ticket promedio, NPS, ventas por provincia, ranking de productos y evolución mensual.

Para generar los archivos de indicadores:

```bash
python calcular_kpis.py
```

Los resultados se guardan como archivos CSV en la carpeta `dw/`.

### Data Marts

Se crearon tres Data Marts para organizar la información comercial:

| Data Mart | Descripción |
|---|---|
| `dm_ventas` | Ventas totales, cantidad de pedidos y ticket promedio |
| `dm_usuarios` | Usuarios activos registrados por fecha |
| `dm_nps` | Respuestas de satisfacción, promotores, detractores y NPS |

El código SQL se encuentra en `sql/04_data_marts.sql` y los resultados exportados están disponibles en la carpeta `dw/`.

Estos conjuntos de datos permiten preparar la información para su análisis y visualización en Power BI.

## Diccionario de datos del Data Warehouse

El Data Warehouse está compuesto por seis tablas de dimensiones y seis tablas de hechos. Las dimensiones contienen información descriptiva, mientras que las tablas de hechos registran las operaciones del negocio.

### Tablas de dimensiones

| Tabla | Clave primaria | Descripción |
|---|---|---|
| `dim_channel` | `channel_key` | Canales de venta, identificados por código y nombre. |
| `dim_customer` | `customer_key` | Clientes, con datos personales, estado y fecha de registro. |
| `dim_date` | `date_key` | Calendario con fecha, año, mes, día y nombres correspondientes. |
| `dim_product` | `product_key` | Productos, SKU, categoría, familia y precio de lista. |
| `dim_province` | `province_key` | Provincias, con nombre y código. |
| `dim_store` | `store_key` | Tiendas físicas y sus identificadores de dirección. |

### Tablas de hechos

| Tabla | Clave primaria | Principales atributos |
|---|---|---|
| `fact_sales_order` | `order_id` | Fecha, cliente, canal, tienda, provincia, subtotal, impuestos, envío, importe total y estado. |
| `fact_sales_order_item` | `order_item_id` | Pedido, producto, cantidad, precio unitario, descuento e importe de la línea. |
| `fact_payment` | `payment_id` | Pedido, método de pago, estado, importe, fecha y referencia de transacción. |
| `fact_shipment` | `shipment_id` | Pedido, transportista, seguimiento, estado y fechas de envío y entrega. |
| `fact_web_session` | `session_id` | Fecha, cliente, origen de la visita, dispositivo e inicio y fin de sesión. |
| `fact_nps` | `nps_id` | Fecha, cliente, canal, puntuación, comentario y fecha de respuesta. |

### Principales claves y relaciones

- `date_key`: relaciona las operaciones con `dim_date`.
- `customer_key`: relaciona las operaciones con `dim_customer`.
- `channel_key`: relaciona las operaciones con `dim_channel`.
- `product_key`: relaciona los productos vendidos con `dim_product`.
- `province_key`: relaciona los pedidos con `dim_province`.
- `store_key`: relaciona las ventas con `dim_store`.
- `order_id`: permite vincular pedidos con sus productos, pagos y envíos.

Las claves terminadas en `_key` se utilizan para conectar las tablas de hechos con las dimensiones correspondientes, cuando están presentes.

### Tipos de datos

Se utilizan principalmente los siguientes tipos:

- `INTEGER` y `BIGINT`: identificadores y cantidades.
- `VARCHAR`: nombres, códigos, estados y descripciones.
- `DATE`: fechas del calendario.
- `TIMESTAMP`: fechas y horas de operaciones.
- `DECIMAL(12,2)`: importes monetarios con dos decimales.

## Supuestos y criterios del análisis

Para construir el Data Warehouse y calcular los indicadores comerciales de EcoBottle AR, se establecieron los siguientes criterios:

1. **Período de análisis:** se consideran los datos disponibles desde el 1 de enero de 2024 hasta el 30 de septiembre de 2025.

2. **Moneda:** todos los importes monetarios se expresan en pesos argentinos (ARS).

3. **Ventas válidas:** se consideran ventas los pedidos con estado `PAID` o `FULFILLED`. Los pedidos cancelados, reembolsados o pendientes de pago no se incluyen en las ventas totales.

4. **Ventas totales:** se calculan sumando el campo `total_amount` de los pedidos válidos, incluyendo impuestos y costos de envío.

5. **Ticket promedio:** se obtiene dividiendo el importe total de las ventas válidas por la cantidad de pedidos válidos.

6. **Usuarios activos:** se consideran los clientes identificados que registraron al menos una sesión web durante el período analizado. Se utiliza `COUNT(DISTINCT customer_key)` para evitar contar varias veces al mismo cliente dentro del período.

7. **NPS:** se consideran promotores las respuestas de 9 o 10 puntos, detractores las de 0 a 6 y pasivos las de 7 u 8. El NPS se calcula como el porcentaje de promotores menos el porcentaje de detractores.

8. **Datos faltantes:** los valores `NULL` se mantienen cuando representan información no disponible o que no corresponde a una operación, como las sesiones anónimas o las compras sin envío.

9. **Modelo dimensional:** se utiliza un modelo estrella basado en Kimball, con dimensiones descriptivas y tablas de hechos para las operaciones comerciales.

10. **Herramientas:** las transformaciones y los indicadores se calculan mediante SQL en DuckDB, mientras que Power BI se utiliza para la visualización de los resultados.