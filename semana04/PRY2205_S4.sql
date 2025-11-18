//CASO 1//

SELECT 
    ROW_NUMBER() OVER (ORDER BY cc.nombre_ciudad DESC, t.sueldo_base) AS "#",
    UPPER(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS "Nombre Completo Trabajador",
    REGEXP_REPLACE(TO_CHAR(t.numrut), '(\d{2})(\d{3})(\d{3})', '\1.\2.\3') || '-' || t.dvrut AS "RUT Trabajador",
    UPPER(tt.desc_categoria) AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador",
    '$' || REGEXP_REPLACE(TO_CHAR(t.sueldo_base), '(\d)(?=(\d{3})+$)', '\1.') AS "Sueldo Base"
FROM trabajador t
JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY cc.nombre_ciudad DESC, t.sueldo_base ASC;


//CASO 2//

SELECT 
    REGEXP_REPLACE(TO_CHAR(t.numrut), '(\d{2})(\d{3})(\d{3})', '\1.\2.\3') || '-' || t.dvrut AS "RUT Trabajador",
    INITCAP(t.nombre) || ' ' || UPPER(t.appaterno) AS "Nombre Trabajador",
    COUNT(tc.nro_ticket) AS "Total Tickets",
    '$' || TO_CHAR(SUM(tc.monto_ticket), 'FM999G999G999') AS "Total Vendido",
    '$' || TO_CHAR(SUM(ct.valor_comision), 'FM999G999G999') AS "Comisión Total",
    UPPER(tt.desc_categoria) AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
JOIN tickets_concierto tc ON t.numrut = tc.numrut_t
JOIN comisiones_ticket ct ON tc.nro_ticket = ct.nro_ticket
WHERE UPPER(tt.desc_categoria) LIKE '%CAJERO%'
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno, tt.desc_categoria, cc.nombre_ciudad
HAVING SUM(tc.monto_ticket) > 50000
ORDER BY SUM(tc.monto_ticket) DESC;



//CASO 3//

SELECT 
    REGEXP_REPLACE(TO_CHAR(t.numrut), '(\d{2})(\d{3})(\d{3})', '\1.\2.\3') AS "RUT Trabajador",
    INITCAP(t.nombre) || ' ' || UPPER(t.appaterno) AS "Trabajador Nombre",
    EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing) AS "Años Antigüedad",
    NVL(COUNT(af.numrut_carga), 0) AS "Num. Cargas Familiar",
    i.nombre_isapre AS "Nombre Isapre",
    '$' || TO_CHAR(t.sueldo_base, 'FM999G999G999') AS "Sueldo Base",
    CASE 
        WHEN UPPER(i.nombre_isapre) = 'FONASA' THEN '$' || TO_CHAR(ROUND(t.sueldo_base * 0.01), 'FM999G999G999')
        ELSE '0'
    END AS "Bono Fonasa",
    CASE 
        WHEN (EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing)) <= 10 THEN '$' || TO_CHAR(ROUND(t.sueldo_base * 0.10), 'FM999G999G999')
        ELSE '$' || TO_CHAR(ROUND(t.sueldo_base * 0.15), 'FM999G999G999')
    END AS "Bono Antigüedad",
    a.nombre_afp AS "Nombre AFP",
    ec.desc_estcivil AS "Estado Civil"
FROM trabajador t
JOIN isapre i ON t.cod_isapre = i.cod_isapre
JOIN afp a ON t.cod_afp = a.cod_afp
JOIN est_civil e ON t.numrut = e.numrut_t
JOIN estado_civil ec ON e.id_estcivil_est = ec.id_estcivil
LEFT JOIN asignacion_familiar af ON t.numrut = af.numrut_t
WHERE e.fecter_estcivil IS NULL 
   OR e.fecter_estcivil > SYSDATE
GROUP BY t.numrut, t.nombre, t.appaterno, t.fecing, t.sueldo_base, 
         i.nombre_isapre, a.nombre_afp, ec.desc_estcivil
ORDER BY t.numrut ASC;