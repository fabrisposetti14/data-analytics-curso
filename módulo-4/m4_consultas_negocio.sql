-- Pre-entrega 4: Consultas SQL de negocio
-- Proyecto: RetailPro | Base: Ventas_Tech_DB


-- Consulta 1: Resumen ejecutivo mensual

SELECT
    MONTH(fecha_venta)                      AS mes,
    SUM(cantidad * precio_unitario)         AS total_facturado,
    COUNT(*)                                AS cantidad_pedidos,
    AVG(cantidad * precio_unitario)         AS ticket_promedio
FROM ventas
GROUP BY MONTH(fecha_venta)
ORDER BY mes;


-- Consulta 2: Ranking de productos (Top 5 por facturación)

SELECT TOP 5
    id_producto,
    SUM(cantidad)                           AS unidades_vendidas,
    SUM(cantidad * precio_unitario)         AS total_generado
FROM ventas
GROUP BY id_producto
ORDER BY total_generado DESC;


-- Consulta 3: Clientes recurrentes (más de un pedido)
-- -----------------------------------------------------
SELECT
    id_cliente,
    COUNT(*)                                AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)         AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;


-- Consulta 4: Meses por encima / por debajo del promedio

WITH facturacion_mensual AS (
    SELECT
        MONTH(fecha_venta)                  AS mes,
        SUM(cantidad * precio_unitario)     AS total_facturado
    FROM ventas
    GROUP BY MONTH(fecha_venta)
)
SELECT
    mes,
    total_facturado,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM facturacion_mensual)
            THEN 'Por encima'
        ELSE 'Por debajo'
    END                                     AS comparacion_promedio
FROM facturacion_mensual
ORDER BY mes;

-- Hallazgos
-- -----------------------------------------------------
-- 1. El producto 1 concentra cerca del 56% de la facturación (3600 de 6444)
--    con solo 3 unidades vendidas. Junto con el producto 3 suman ~77% del total.
-- 2. El producto 2 es el que más unidades vende (13) pero es el último del
--    Top 5 en facturación (364, ~6% del total): mucho volumen, ticket unitario bajo.
-- 3. Los 5 clientes hicieron exactamente 2 pedidos (todos son recurrentes).
--    El cliente 1 gastó 2640 (~41% del total) y, junto con el cliente 5,
--    concentran ~74% de la facturación.
--
-- Nota: la tabla ventas contiene un único mes (marzo) con 10 pedidos, por lo
-- que en la Consulta 4 el promedio mensual coincide con ese mes y la etiqueta
-- resulta "Por debajo". Con más meses cargados la comparación sería informativa.
