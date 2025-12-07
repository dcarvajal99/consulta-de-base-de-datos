//CASO 1//

SELECT * FROM TRABAJADOR;
SELECT * FROM ISAPRE;
SELECT * FROM TICKETS_CONCIERTO;
SELECT * FROM BONO_ANTIGUEDAD;


//GENERAR INFORME//

SELECT 
    ROW_NUMBER() OVER (ORDER BY NVL(SUM(tc.monto_ticket), 0) DESC, t.nombre ASC) AS "Num",
    t.numrut || '-' || t.dvrut || ' ' || t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno AS "RUT_NOMBRE_TRABAJADOR",
    '$' || TO_CHAR(t.sueldo_base, 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''') AS "SUELDO_BASE",
    CASE 
        WHEN COUNT(tc.nro_ticket) = 0 THEN 'No hay info'
        ELSE t.direccion 
    END AS "DIRECCION_O_INFO",
    i.nombre_isapre || 
    CASE 
        WHEN SUM(tc.monto_ticket) IS NOT NULL AND SUM(tc.monto_ticket) > 0 THEN 
            ' $' || TO_CHAR(SUM(tc.monto_ticket), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
        ELSE ''
    END AS "SISTEMA_SALUD_MONTO",
    CASE 
        WHEN SUM(tc.monto_ticket) IS NULL THEN '$0'
        WHEN SUM(tc.monto_ticket) <= 50000 THEN '$0'
        WHEN SUM(tc.monto_ticket) <= 100000 THEN 
            '$' || TO_CHAR(ROUND(SUM(tc.monto_ticket) * 0.05), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
        ELSE '$' || TO_CHAR(ROUND(SUM(tc.monto_ticket) * 0.07), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
    END AS "BONIF_X_TICKET",
    CASE 
        WHEN SUM(tc.monto_ticket) IS NULL THEN '$' || TO_CHAR(t.sueldo_base, 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
        WHEN SUM(tc.monto_ticket) <= 50000 THEN '$' || TO_CHAR(t.sueldo_base, 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
        WHEN SUM(tc.monto_ticket) <= 100000 THEN 
            '$' || TO_CHAR(ROUND(t.sueldo_base + (SUM(tc.monto_ticket) * 0.05)), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
        ELSE '$' || TO_CHAR(ROUND(t.sueldo_base + (SUM(tc.monto_ticket) * 0.07)), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
    END AS "SIMULACION_X_TICKET",
    '$' || TO_CHAR(ROUND(t.sueldo_base * (1 + ba.porcentaje)), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''') AS "SIMULACION_ANTIGUEDAD"
FROM TRABAJADOR t
INNER JOIN ISAPRE i ON t.cod_isapre = i.cod_isapre
LEFT JOIN TICKETS_CONCIERTO tc ON t.numrut = tc.numrut_t
INNER JOIN BONO_ANTIGUEDAD ba ON 
    TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12) 
    BETWEEN ba.limite_inferior AND ba.limite_superior
WHERE 
    i.porc_descto_isapre > 4
    AND TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecnac) / 12) < 50
GROUP BY 
    t.numrut, t.dvrut, t.nombre, t.appaterno, t.apmaterno, 
    t.sueldo_base, t.direccion, i.nombre_isapre, ba.porcentaje
ORDER BY 
    NVL(SUM(tc.monto_ticket), 0) DESC, 
    t.nombre ASC;
    
//INSERTANDO DETALLES//

INSERT INTO DETALLE_BONIFICACIONES_TRABAJADOR (
    num, rut, nombre_trabajador, sueldo_base, num_ticket, 
    direccion, sistema_salud, monto, bonif_x_ticket, 
    simulacion_x_ticket, simulacion_antiguedad
)
SELECT 
    SEQ_DET_BONIF.NEXTVAL,
    datos.rut,
    datos.nombre_trabajador,
    datos.sueldo_base,
    datos.num_ticket,
    datos.direccion,
    datos.sistema_salud,
    datos.monto,
    datos.bonif_x_ticket,
    datos.simulacion_x_ticket,
    datos.simulacion_antiguedad
FROM (
    SELECT 
        t.numrut || '-' || t.dvrut as rut,
        t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno as nombre_trabajador,
        '$' || TO_CHAR(t.sueldo_base, 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''') as sueldo_base,
        CASE 
            WHEN COUNT(tc.nro_ticket) = 0 THEN 'No hay info'
            ELSE TO_CHAR(COUNT(tc.nro_ticket)) || ' tickets'
        END as num_ticket,
        t.direccion as direccion,
        i.nombre_isapre as sistema_salud,
        CASE 
            WHEN SUM(tc.monto_ticket) IS NULL THEN '$0'
            ELSE '$' || TO_CHAR(SUM(tc.monto_ticket), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
        END as monto,
        CASE 
            WHEN SUM(tc.monto_ticket) IS NULL THEN '$0'
            WHEN SUM(tc.monto_ticket) <= 50000 THEN '$0'
            WHEN SUM(tc.monto_ticket) <= 100000 THEN 
                '$' || TO_CHAR(ROUND(SUM(tc.monto_ticket) * 0.05), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
            ELSE '$' || TO_CHAR(ROUND(SUM(tc.monto_ticket) * 0.07), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
        END as bonif_x_ticket,
        CASE 
            WHEN SUM(tc.monto_ticket) IS NULL THEN '$' || TO_CHAR(t.sueldo_base, 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
            WHEN SUM(tc.monto_ticket) <= 50000 THEN '$' || TO_CHAR(t.sueldo_base, 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
            WHEN SUM(tc.monto_ticket) <= 100000 THEN 
                '$' || TO_CHAR(ROUND(t.sueldo_base + (SUM(tc.monto_ticket) * 0.05)), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
            ELSE '$' || TO_CHAR(ROUND(t.sueldo_base + (SUM(tc.monto_ticket) * 0.07)), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''')
        END as simulacion_x_ticket,
        '$' || TO_CHAR(ROUND(t.sueldo_base * (1 + ba.porcentaje)), 'FM9G999G999D0', 'NLS_NUMERIC_CHARACTERS='',.''') as simulacion_antiguedad
    FROM TRABAJADOR t
    INNER JOIN ISAPRE i ON t.cod_isapre = i.cod_isapre
    LEFT JOIN TICKETS_CONCIERTO tc ON t.numrut = tc.numrut_t
    INNER JOIN BONO_ANTIGUEDAD ba ON 
        TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12) 
        BETWEEN ba.limite_inferior AND ba.limite_superior
    WHERE 
        i.porc_descto_isapre > 4
        AND TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecnac) / 12) < 50
    GROUP BY 
        t.numrut, t.dvrut, t.nombre, t.appaterno, t.apmaterno, 
        t.sueldo_base, t.direccion, i.nombre_isapre, ba.porcentaje
) datos;


SELECT * FROM DETALLE_BONIFICACIONES_TRABAJADOR;

SELECT *
FROM detalle_bonificaciones_trabajador
ORDER BY monto DESC, nombre_trabajador


//CASO 2//
SELECT * FROM BONO_ESCOLAR

DESCRIBE TRABAJADOR;


CREATE OR REPLACE VIEW V_AUMENTOS_ESTUDIOS AS
SELECT 
    REPLACE(TO_CHAR(t.NUMRUT, '99G999G999'), ',', '.') || '-' || t.DVRUT AS "RUT_TRABAJADOR",
    TRIM(t.NOMBRE || ' ' || t.APPATERNO || ' ' || COALESCE(t.APMATERNO, '')) AS "TRABAJADOR",
    b.DESCRIP AS "DESCRIP",
    LPAD(b.PORC_BONO, 7, '0') AS "PORC_ESTUDIOS",
    t.SUELDO_BASE AS "SUELDO_ACTUAL",
    ROUND(t.SUELDO_BASE * b.PORC_BONO / 100) AS "AUMENTO",
    '$' || REPLACE(TO_CHAR(t.SUELDO_BASE + ROUND(t.SUELDO_BASE * b.PORC_BONO / 100), '9G999G999'), ',', '.') AS "SUELDO_AUMENTADO"
FROM 
    TRABAJADOR t
JOIN 
    BONO_ESCOLAR b ON t.ID_ESCOLARIDAD_T = b.ID_ESCOLAR
WHERE 
    t.SUELDO_BASE IS NOT NULL
    AND b.PORC_BONO IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM TRABAJADOR t2 
        WHERE t2.NUMRUT = t.NUMRUT
    )
GROUP BY 
    t.NUMRUT, t.DVRUT, t.NOMBRE, t.APPATERNO, t.APMATERNO, 
    b.DESCRIP, b.PORC_BONO, t.SUELDO_BASE, t.ID_ESCOLARIDAD_T, b.ID_ESCOLAR
HAVING 
    t.SUELDO_BASE > 0
ORDER BY 
    b.PORC_BONO ASC,
    TRIM(t.NOMBRE || ' ' || t.APPATERNO || ' ' || COALESCE(t.APMATERNO, '')) ASC;


SELECT * FROM V_AUMENTOS_ESTUDIOS;




//etapa 2//
//Function-Based Index para consultas con UPPER()//

CREATE INDEX idx_trabajador_upper_apmaterno ON trabajador(UPPER(apmaterno));
    
//Tree Index para consultas normales//

CREATE INDEX idx_trabajador_bt_apmaterno ON trabajador(apmaterno);

SELECT numrut, nombre, appaterno, apmaterno
FROM trabajador
WHERE UPPER(apmaterno) = 'CASTILLO';
    
    