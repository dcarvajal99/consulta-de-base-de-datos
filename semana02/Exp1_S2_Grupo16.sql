/* CASO 1 — Análisis de Facturas (Año anterior) */

SELECT
  f.numfactura                                                   AS "N° Factura",

  INITCAP(
    TO_CHAR(f.fecha, 'DD "de" Month YYYY', 'NLS_DATE_LANGUAGE=SPANISH')
  )                                                              AS "Fecha Emisión",

  LPAD(f.rutcliente, 10, '0')                                    AS "RUT Cliente",

  TO_CHAR(ROUND(NVL(f.neto,0)),
          'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')     AS "Monto Neto",

  TO_CHAR(ROUND(NVL(f.iva,0)),
          'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')     AS "Monto Iva",

  TO_CHAR(ROUND(NVL(f.total,0)),
          'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')     AS "Total Factura",

  CASE
    WHEN f.total BETWEEN 0 AND 50000       THEN 'Bajo'
    WHEN f.total BETWEEN 50001 AND 100000  THEN 'Medio'
    ELSE                                        'Alto'
  END                                                            AS "Categoría Monto",

  CASE f.codpago
    WHEN 1 THEN 'EFECTIVO'
    WHEN 2 THEN 'TARJETA DEBITO'
    WHEN 3 THEN 'TARJETA CREDITO'
    ELSE      'CHEQUE'
  END                                                            AS "Forma de pago"

FROM factura f
WHERE EXTRACT(YEAR FROM f.fecha) =
      EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))   -- Año anterior dinámico

ORDER BY f.fecha DESC, f.neto DESC;

/* ====== CASO 2 — Clasificación de Clientes ====== */

SELECT
  LPAD(c.rutcliente, 12, '*')                                         AS "RUT",
  INITCAP(c.nombre)                                                             AS "Cliente",
  NVL(TO_CHAR(c.telefono), 'Sin teléfono')                             AS "TELÉFONO",
  NVL(TO_CHAR(c.codcomuna), 'Sin comuna')                              AS "COMUNA",
  c.estado                                                             AS "ESTADO",
  CASE
    WHEN c.credito > 0 AND (NVL(c.saldo,0)/c.credito) < 0.5 THEN
      'Bueno ( ' ||
      TO_CHAR(ROUND(c.credito - NVL(c.saldo,0)),
              'FM$999G999G999','NLS_NUMERIC_CHARACTERS='',.''') || ' )'
    WHEN c.credito > 0 AND (NVL(c.saldo,0)/c.credito) <= 0.8 THEN
      'Regular ( ' ||
      TO_CHAR(ROUND(NVL(c.saldo,0)),
              'FM$999G999G999','NLS_NUMERIC_CHARACTERS='',.''') || ' )'
    ELSE 'Crítico'
  END                                                                  AS "Estado Crédito",
  CASE
    WHEN c.mail IS NULL THEN 'Correo no registrado'
    WHEN INSTR(c.mail, '@') = 0 THEN 'Correo no registrado'
    ELSE UPPER(SUBSTR(c.mail, INSTR(c.mail,'@')+1))
  END                                                                  AS "Dominio Correo"

FROM cliente c
WHERE c.estado = 'A'
  AND NVL(c.credito,0) > 0
ORDER BY c.nombre ASC;



/* ====== CASO 3 — Stock de productos (paramétrico) ======
   Variables: &TIPOCAMBIO_DOLAR, &UMBRAL_BAJO, &UMBRAL_ALTO
*/

SELECT
  p.codproducto                                                        AS "ID",
  INITCAP(LOWER(p.descripcion))                                        AS "Descripción de Producto",
  CASE
    WHEN p.valorcompradolar IS NULL THEN 'Sin registro'
    ELSE TO_CHAR(
           ROUND(p.valorcompradolar, 2),
           'FM999G999G990D99',
           'NLS_NUMERIC_CHARACTERS='',.'''
         ) || ' USD'
  END                                                                  AS "Compra en USD",
  CASE
    WHEN p.valorcompradolar IS NULL THEN 'Sin registro'
    ELSE TO_CHAR(
           ROUND(p.valorcompradolar * &TIPOCAMBIO_DOLAR),
           'FM$999G999G999',
           'NLS_NUMERIC_CHARACTERS='',.'''
         ) || ' PESOS'
  END                                                                  AS "USD convertido",
  NVL(p.totalstock, 0)                                                 AS "Stock",
  CASE
    WHEN p.totalstock IS NULL                     THEN 'Sin datos'
    WHEN p.totalstock <  &UMBRAL_BAJO            THEN '¡ALERTA stock muy bajo!'
    WHEN p.totalstock <= &UMBRAL_ALTO            THEN '¡Reabastecer pronto!'
    ELSE                                              'OK'
  END                                                                  AS "Alerta Stock",
  CASE
    WHEN p.totalstock > 80 THEN
      TO_CHAR(
        ROUND( NVL(p.vunitario,0) * 0.90 ),
        'FM$999G999G999',
        'NLS_NUMERIC_CHARACTERS='',.'''
      )
    ELSE 'N/A'
  END                                                                  AS "Precio Oferta"

FROM producto p
WHERE UPPER(p.descripcion) LIKE '%ZAPATO%'
  AND UPPER(p.procedencia) = 'I'
ORDER BY p.codproducto DESC;
