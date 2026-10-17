-- =====================================================
-- Pre-entrega 5: Consultas con JOINs
-- Proyecto: RetailPro | Base: Ventas_Tech_DB
-- =====================================================

USE Ventas_Tech_DB;
GO

-- -----------------------------------------------------
-- Datos de ejemplo adicionales
-- Se agregan 2 clientes y 2 productos SIN ventas para que las
-- consultas 2 y 3 (LEFT JOIN ... IS NULL) tengan casos que aislar.
-- Los IF NOT EXISTS permiten correr el script varias veces.
-- -----------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = 6)
    INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro)
    VALUES (6, 'Sofía Díaz', 'sofia@mail.com', 'La Plata', '2024-03-10');

IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = 7)
    INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro)
    VALUES (7, 'Diego Pérez', 'diego@mail.com', 'Salta', '2024-03-18');

IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = 7)
    INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo)
    VALUES (7, 'Webcam HD 1080p', 2, 60.00, 25, 1);

IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = 8)
    INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo)
    VALUES (8, 'SSD Interno 500GB', 4, 75.00, 30, 1);
GO

-- -----------------------------------------------------
-- Consulta 1: Vista base del proyecto (INNER JOIN)
-- Propósito: una sola fila por venta con cliente, ciudad, producto y
-- categoría. Es la fuente de datos principal para Power BI.
-- -----------------------------------------------------
SELECT
    v.fecha_venta,
    c.id_cliente,
    c.nombre                         AS cliente,
    c.ciudad,
    p.nombre_producto                AS producto,
    cat.nombre_categoria             AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario   AS total_venta
FROM ventas v
INNER JOIN clientes   c   ON v.id_cliente   = c.id_cliente
INNER JOIN productos  p   ON v.id_producto  = p.id_producto
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta;
-- Hallazgo: 
-- la vista devuelve las 10 ventas con cliente, ciudad, producto y categoría,
-- sin perder ninguna fila. Computación concentra ~77% de la facturación (4950 de 6444).

-- -----------------------------------------------------
-- Consulta 2: Clientes sin ventas (LEFT JOIN)
-- Propósito: detectar clientes registrados que nunca compraron,
-- para que CRM los contacte.
-- -----------------------------------------------------
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL;
-- Hallazgo: 
-- 2 de los 7 clientes registrados nunca compraron (Sofía Díaz y Diego Pérez);
-- ambos se registraron en marzo 2024, por lo que CRM puede contactarlos para promover una compra.

-- -----------------------------------------------------
-- Consulta 3: Productos sin ventas (LEFT JOIN)
-- Propósito: identificar artículos del catálogo sin movimiento,
-- para que el área de producto revise su stock o su precio.
-- -----------------------------------------------------
SELECT
    p.nombre_producto,
    cat.nombre_categoria  AS categoria,
    p.precio
FROM productos p
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas v        ON p.id_producto  = v.id_producto
WHERE v.id_venta IS NULL;
-- Hallazgo: 
-- 2 de los 8 productos del catálogo no tienen ventas (Webcam HD 1080p y SSD Interno 500GB),
-- ambos de bajo precio (60 y 75); el area de producto puede revisar si les falta visibilidad o promoción,
-- o si conviene reducir su stock.
-- -----------------------------------------------------
-- Consulta 4: Consolidado por canal (UNION ALL)
-- Propósito: comparar la facturación de dos períodos de marzo 2024.
-- La columna canal no existe en las tablas: se crea como valor fijo
-- en cada SELECT. Se usa UNION ALL para no eliminar ventas repetidas.
-- -----------------------------------------------------
SELECT canal, SUM(total) AS total_canal
FROM (
    SELECT fecha_venta, cantidad * precio_unitario AS total,
           'Período 1 (05-10 mar)' AS canal
    FROM ventas
    WHERE fecha_venta BETWEEN '2024-03-05' AND '2024-03-10'
    UNION ALL
    SELECT fecha_venta, cantidad * precio_unitario AS total,
           'Período 2 (11-15 mar)' AS canal
    FROM ventas
    WHERE fecha_venta BETWEEN '2024-03-11' AND '2024-03-15'
) AS consolidado
GROUP BY canal;
-- Hallazgo: 
-- el primer período (05-10 mar) facturó 3620 (56% del total) y el segundo (11-15 mar) 2824 (44%);
-- la facturación se concentró en la primera mitad del período, algo a vigilar si la caída de facturacion
-- continúa.
