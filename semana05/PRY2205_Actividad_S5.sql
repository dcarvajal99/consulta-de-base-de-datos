//CASO 1//

SELECT 
    c.numrun || '-' || c.dvrun AS "RUT Cliente",
    INITCAP(c.pnombre || ' ' || c.appaterno) AS "Nombre Cliente",
    INITCAP(po.nombre_prof_ofic) AS "Profesión Cliente",
    TO_CHAR(c.fecha_inscripcion, 'DD-MM-YYYY') AS "Fecha de inscripción",
    INITCAP(c.direccion) AS "Dirección Cliente"
FROM CLIENTE c
JOIN PROFESION_OFICIO po ON c.cod_prof_ofic = po.cod_prof_ofic
WHERE UPPER(po.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
AND EXTRACT(YEAR FROM c.fecha_inscripcion) > (
    SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion)))
    FROM CLIENTE
)
ORDER BY c.numrun ASC;


SELECT * FROM cliente;
SELECT * FROM tipo_cliente;
SELECT * FROM tarjeta_cliente;

//CASO 2//

CREATE TABLE CLIENTES_CUPOS_COMPRA AS
SELECT 
    c.numrun || '-' || c.dvrun AS RUT_CLIENTE,
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM c.fecha_nacimiento) AS EDAD,
    '$' || TO_CHAR(tc.cupo_disp_compra, 'FM999,999,999') AS CUPO_DISPONIBLE_COMPRA,
    INITCAP(tc2.nombre_tipo_cliente) AS TIPO_CLIENTE
FROM CLIENTE c
JOIN TARJETA_CLIENTE tc ON c.numrun = tc.numrun
JOIN TIPO_CLIENTE tc2 ON c.cod_tipo_cliente = tc2.cod_tipo_cliente
WHERE tc.cupo_disp_compra >= (
    SELECT MAX(tc2.cupo_disp_compra)
    FROM TARJETA_CLIENTE tc2
    JOIN CLIENTE c2 ON tc2.numrun = c2.numrun
    WHERE EXTRACT(YEAR FROM c2.fecha_inscripcion) = EXTRACT(YEAR FROM SYSDATE) - 1
)
ORDER BY EDAD ASC;

SELECT * FROM CLIENTES_CUPOS_COMPRA;

DROP TABLE CLIENTES_CUPOS_COMPRA;

CREATE TABLE CLIENTES_CUPOS_COMPRA AS
SELECT 
    c.numrun || '-' || c.dvrun AS RUT_CLIENTE,
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM c.fecha_nacimiento) AS EDAD,
    '$' || TO_CHAR(tc.cupo_disp_compra, 'FM999,999,999') AS CUPO_DISPONIBLE_COMPRA,
    INITCAP(tcl.nombre_tipo_cliente) AS TIPO_CLIENTE
FROM CLIENTE c
JOIN TARJETA_CLIENTE tc ON c.numrun = tc.numrun
JOIN TIPO_CLIENTE tcl ON c.cod_tipo_cliente = tcl.cod_tipo_cliente
WHERE tc.cupo_disp_compra >= (
    SELECT NVL(MAX(tc2.cupo_disp_compra), 0)
    FROM TARJETA_CLIENTE tc2
    WHERE EXTRACT(YEAR FROM tc2.fecha_solic_tarjeta) = EXTRACT(YEAR FROM SYSDATE) - 1
)
ORDER BY EDAD ASC;

SELECT * FROM CLIENTES_CUPOS_COMPRA;



