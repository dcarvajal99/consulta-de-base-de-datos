/* ==== S6 - Caso 1: Reportería de Asesorías Banca y Retail ==== 
        POR FAVOR EJECUTAR PASO POR PASO PARA MOSTRAR BIEN TODOS LOS RESULTADOS */



-- 1) Configurar separadores numéricos
ALTER SESSION SET NLS_NUMERIC_CHARACTERS=',.';
------------------------------------------------

-- 2) CONSULTA SQL
SELECT
    u.id_profesional                                           AS "ID",
    u.profesional                                              AS "PROFESIONAL",
    u.nro_ases_banca                                           AS "NRO_ASESORIA_BANCA",
    TO_CHAR(u.monto_total_banca,  'FM$999G999G999G999')        AS "MONTO_TOTAL_BANCA",
    u.nro_ases_retail                                          AS "NRO_ASESORIA_RETAIL",
    TO_CHAR(u.monto_total_retail, 'FM$999G999G999G999')        AS "MONTO_TOTAL_RETAIL",
    (u.nro_ases_banca + u.nro_ases_retail)                     AS "TOTAL_ASESORIAS",
    TO_CHAR(u.monto_total_banca + u.monto_total_retail,
            'FM$999G999G999G999')                              AS "TOTAL_HONORARIOS"
FROM (
    SELECT
        t.id_profesional,
        t.profesional,
        SUM(t.nro_ases_banca)        AS nro_ases_banca,
        SUM(t.monto_total_banca)     AS monto_total_banca,
        SUM(t.nro_ases_retail)       AS nro_ases_retail,
        SUM(t.monto_total_retail)    AS monto_total_retail
    FROM (
        SELECT
            p.id_profesional,
            INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS profesional,
            COUNT(*)                       AS nro_ases_banca,
            SUM(a.honorario)               AS monto_total_banca,
            0                              AS nro_ases_retail,
            0                              AS monto_total_retail
        FROM asesoria      a
        JOIN empresa       e ON e.cod_empresa   = a.cod_empresa
        JOIN profesional   p ON p.id_profesional = a.id_profesional
        WHERE e.cod_sector = 3
        AND a.fin_asesoria IS NOT NULL
        GROUP BY p.id_profesional,
            INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre)

        UNION ALL
        SELECT
            p.id_profesional,
            INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS profesional,
            0                              AS nro_ases_banca,
            0                              AS monto_total_banca,
            COUNT(*)                       AS nro_ases_retail,
            SUM(a.honorario)               AS monto_total_retail
        FROM asesoria      a
        JOIN empresa       e ON e.cod_empresa   = a.cod_empresa
        JOIN profesional   p ON p.id_profesional = a.id_profesional
        WHERE e.cod_sector = 4
          AND a.fin_asesoria IS NOT NULL
        GROUP BY p.id_profesional,
                 INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre)
    ) t
    GROUP BY
        t.id_profesional,
        t.profesional
    HAVING
        SUM(t.nro_ases_banca)  > 0
    AND SUM(t.nro_ases_retail) > 0
) u
ORDER BY u.id_profesional;
------------------------------------------------







/* ====== CASO 2 - RESUMEN DE HONORARIOS ====== */

/* 1) Borrar la tabla sólo si existe (sin mostrar error) */
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE REPORTE_MES PURGE';
EXCEPTION
  WHEN OTHERS THEN
    -- ORA-00942 = table or view does not exist
    IF SQLCODE <> -942 THEN
      RAISE;
    END IF;
END;
/
------------------------------------------------

/* 2) Crear tabla REPORTE_MES (valores NUMÉRICOS) */
CREATE TABLE REPORTE_MES (
  ID_PROF                 NUMBER(10),
  NOMBRE_COMPLETO         VARCHAR2(80),
  NOMBRE_PROFESION        VARCHAR2(50),
  NOM_COMUNA              VARCHAR2(50),
  NRO_ASESORIAS           NUMBER(4),
  MONTO_TOTAL_HONORARIOS  NUMBER(12),
  PROMEDIO_HONORARIO      NUMBER(12),
  HONORARIO_MINIMO        NUMBER(12),
  HONORARIO_MAXIMO        NUMBER(12)
);
------------------------------------------------

/* 3) Poblar REPORTE_MES con asesorías de ABRIL del año pasado */
INSERT INTO REPORTE_MES (
    ID_PROF,
    NOMBRE_COMPLETO,
    NOMBRE_PROFESION,
    NOM_COMUNA,
    NRO_ASESORIAS,
    MONTO_TOTAL_HONORARIOS,
    PROMEDIO_HONORARIO,
    HONORARIO_MINIMO,
    HONORARIO_MAXIMO
)
SELECT
    p.id_profesional                                              AS ID_PROF,
    INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS NOMBRE_COMPLETO,
    pr.nombre_profesion                                           AS NOMBRE_PROFESION,
    NVL(c.nom_comuna,'Sin comuna')                                AS NOM_COMUNA,
    COUNT(*)                                                      AS NRO_ASESORIAS,
    ROUND(SUM(NVL(a.honorario,0)))                                AS MONTO_TOTAL_HONORARIOS,
    ROUND(AVG(NVL(a.honorario,0)))                                AS PROMEDIO_HONORARIO,
    ROUND(MIN(NVL(a.honorario,0)))                                AS HONORARIO_MINIMO,
    ROUND(MAX(NVL(a.honorario,0)))                                AS HONORARIO_MAXIMO
FROM asesoria a
JOIN profesional p ON p.id_profesional = a.id_profesional
JOIN profesion  pr ON pr.cod_profesion = p.cod_profesion
JOIN comuna     c  ON c.cod_comuna    = p.cod_comuna
WHERE a.fin_asesoria IS NOT NULL
  AND EXTRACT(MONTH FROM a.fin_asesoria) = 4
  AND EXTRACT(YEAR  FROM a.fin_asesoria) =
        EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))
GROUP BY
    p.id_profesional,
    INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre),
    pr.nombre_profesion,
    NVL(c.nom_comuna,'Sin comuna')
ORDER BY
    p.id_profesional;

COMMIT;
------------------------------------------------

/* 4) Mostrar el reporte con formato similar a la figura */
SELECT
  ID_PROF,
  NOMBRE_COMPLETO,
  NOMBRE_PROFESION,
  NOM_COMUNA,
  NRO_ASESORIAS,
  MONTO_TOTAL_HONORARIOS,
  PROMEDIO_HONORARIO,
  HONORARIO_MINIMO,
  HONORARIO_MAXIMO
FROM REPORTE_MES
ORDER BY ID_PROF;
------------------------------------------------





/* ====== CASO 3 - REPORTE ANTES DE MODIFICAR SUELDOS ====== */


-- 1) consulta SQL antes de actualizar sueldos
SELECT
    h.honorario_total            AS HONORARIO,
    p.id_profesional             AS ID_PROFESIONAL,
    p.numrun_prof                AS NUMRUM_PROF,
    p.sueldo                     AS SUELDO
FROM profesional p
JOIN (
        SELECT
            a.id_profesional,
            ROUND(SUM(NVL(a.honorario,0))) AS honorario_total
        FROM asesoria a
        WHERE a.fin_asesoria IS NOT NULL
          AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
          AND EXTRACT(YEAR  FROM a.fin_asesoria) =
                EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE,-12))
        GROUP BY a.id_profesional
     ) h
  ON h.id_profesional = p.id_profesional
ORDER BY p.id_profesional;
------------------------------------------------


-- 2) Actualizar sueldos según honorarios de marzo del año pasado
UPDATE (
    SELECT
        p.sueldo,
        h.honorario_total
    FROM profesional p
    JOIN (
            SELECT
                a.id_profesional,
                ROUND(SUM(NVL(a.honorario,0))) AS honorario_total
            FROM asesoria a
            WHERE a.fin_asesoria IS NOT NULL
              AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
              AND EXTRACT(YEAR  FROM a.fin_asesoria) =
                    EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE,-12))
            GROUP BY a.id_profesional
         ) h
      ON h.id_profesional = p.id_profesional
) x
SET x.sueldo =
    ROUND(
        x.sueldo *
        CASE
          WHEN x.honorario_total < 1000000 THEN 1.10
          ELSE 1.15
        END
    );

COMMIT;
------------------------------------------------

-- 3) consulta SQL después de actualizar sueldos
SELECT
    h.honorario_total            AS HONORARIO,
    p.id_profesional             AS ID_PROFESIONAL,
    p.numrun_prof                AS NUMRUM_PROF,
    p.sueldo                     AS SUELDO
FROM profesional p
JOIN (
        SELECT
            a.id_profesional,
            ROUND(SUM(NVL(a.honorario,0))) AS honorario_total
        FROM asesoria a
        WHERE a.fin_asesoria IS NOT NULL
          AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
          AND EXTRACT(YEAR  FROM a.fin_asesoria) =
                EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE,-12))
        GROUP BY a.id_profesional
     ) h
  ON h.id_profesional = p.id_profesional
ORDER BY p.id_profesional;
------------------------------------------------