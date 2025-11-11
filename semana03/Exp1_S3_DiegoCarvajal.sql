/* Caso 1: Listado de Clientes con Rango de Renta */

ALTER SESSION SET NLS_NUMERIC_CHARACTERS=',.';

SELECT
  TO_CHAR(c.numrut_cli,
          'FM999G999G999G999',
          'NLS_NUMERIC_CHARACTERS='',.''')
  || '-' || c.dvrut_cli                                  AS "RUT Cliente",
  INITCAP(
    TRIM(c.nombre_cli || ' ' || c.appaterno_cli || ' ' || c.apmaterno_cli)
  )                                                      AS "Nombre Completo Cliente",
  NVL(INITCAP(LOWER(c.direccion_cli)), 'Sin dirección')  AS "Dirección Cliente",
  TO_CHAR(ROUND(c.renta_cli), 'FM$999G999G999') AS "Renta Cliente",
  SUBSTR(LPAD(TO_CHAR(c.celular_cli), 9, '0'), 1, 2) || '-' ||
  SUBSTR(LPAD(TO_CHAR(c.celular_cli), 9, '0'), 3, 3) || '-' ||
  SUBSTR(LPAD(TO_CHAR(c.celular_cli), 9, '0'), 6, 4) AS "Celular Cliente",
  CASE
    WHEN c.renta_cli > 500000                     THEN 'TRAMO 1'
    WHEN c.renta_cli BETWEEN 400000 AND 500000    THEN 'TRAMO 2'
    WHEN c.renta_cli BETWEEN 200000 AND 399999    THEN 'TRAMO 3'
    ELSE                                               'TRAMO 4'
  END                                                    AS "Tramo Renta Cliente"

FROM cliente c
WHERE c.celular_cli IS NOT NULL
  AND c.renta_cli BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
ORDER BY
  INITCAP(TRIM(c.nombre_cli || ' ' || c.appaterno_cli || ' ' || c.apmaterno_cli)) ASC;


/* Caso 2: Sueldo Promedio por Categoría de Empleado */
SELECT
  e.id_categoria_emp                                    AS "CODIGO_CATEGORIA",
  ce.desc_categoria_emp                                  AS "DESCRIPCION_CATEGORIA",
  COUNT(*)                                               AS "CANTIDAD_EMPLEADOS",
  CASE s.id_sucursal
    WHEN 10 THEN 'Sucursal Las Condes'
    WHEN 20 THEN 'Sucursal Santiago Centro'
    WHEN 30 THEN 'Sucursal Providencia'
    WHEN 40 THEN 'Sucursal Vitacura'
    ELSE              INITCAP(s.desc_sucursal)
  END                                                    AS "SUCURSAL",
  TO_CHAR(ROUND(AVG(e.sueldo_emp)),
          'FM$999G999G999')                              AS "SUELDO_PROMEDIO"
FROM empleado e
JOIN categoria_empleado ce
  ON ce.id_categoria_emp = e.id_categoria_emp
JOIN sucursal s
  ON s.id_sucursal = e.id_sucursal
GROUP BY
  e.id_categoria_emp,
  ce.desc_categoria_emp,
  s.id_sucursal,
  s.desc_sucursal
HAVING AVG(e.sueldo_emp) >= &SUELDO_PROMEDIO_MINIMO
ORDER BY AVG(e.sueldo_emp) DESC;


/* Caso 3: Arriendo Promedio por Tipo de Propiedad */

SELECT
  tp.id_tipo_propiedad                                 AS "CODIGO_TIPO",
  tp.desc_tipo_propiedad                               AS "DESCRIPCION_TIPO",
  COUNT(*)                                             AS "TOTAL_PROPIEDADES",
  TO_CHAR(ROUND(AVG(p.valor_arriendo)),
          'FM$999G999G999')                            AS "PROMEDIO_ARRIENDO",
  TO_CHAR(AVG(p.superficie), 'FM999999D00') AS "PROMEDIO_SUPERFICIE",
  TO_CHAR(ROUND(AVG(p.valor_arriendo / NULLIF(p.superficie,0))),
          'FM$999G999')                                AS "VALOR_ARRIENDO_M2",
  CASE
    WHEN AVG(p.valor_arriendo / NULLIF(p.superficie,0)) < 5000
         THEN 'Económico'
    WHEN AVG(p.valor_arriendo / NULLIF(p.superficie,0)) BETWEEN 5000 AND 10000
         THEN 'Medio'
    ELSE 'Alto'
  END                                                  AS "CLASIFICACION"
FROM propiedad p
JOIN tipo_propiedad tp
  ON tp.id_tipo_propiedad = p.id_tipo_propiedad
GROUP BY
  tp.id_tipo_propiedad,
  tp.desc_tipo_propiedad
HAVING
  AVG(p.valor_arriendo / NULLIF(p.superficie,0)) > 1000
ORDER BY
  AVG(p.valor_arriendo / NULLIF(p.superficie,0)) DESC;