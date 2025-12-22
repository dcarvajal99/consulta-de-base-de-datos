/* ======================================================================
   PRY2205 – EVALUACIÓN FINAL TRANSVERSAL (EFT) – FORMA C
   SCRIPT MAESTRO: SEGURIDAD, REPORTES Y OPTIMIZACIÓN
   
   >>> INSTRUCCIONES DE EJECUCIÓN <<<
   1. Conectar como SYSTEM o SYS.
   2. Ejecutar Paso 1.
   3. Conectar como PRY2205_EFT y poblar tablas.
   4. Volver a SYSTEM y ejecutar Paso 3.
   5. Continuar con los casos restantes.
   ====================================================================== */


/* ======================================================================
   CASO 1: CONFIGURACIÓN DE SEGURIDAD (USUARIOS Y ROLES)
   EJECUTAR COMO: SYSTEM
   ====================================================================== */

SET DEFINE OFF;
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT FAILURE;

-- ======================================================================
-- PASO 1: CONFIGURACIÓN DE SEGURIDAD (EJECUTAR COMO SYSTEM)
-- ======================================================================
ALTER SESSION SET "_ORACLE_SCRIPT" = TRUE;

-- 1.1 LIMPIEZA PREVENTIVA
BEGIN
    FOR r IN (SELECT username FROM dba_users WHERE username IN ('PRY2205_EFT','PRY2205_EFT_DES','PRY2205_EFT_CON')) LOOP
        EXECUTE IMMEDIATE 'DROP USER '||r.username||' CASCADE';
    END LOOP;
    FOR r IN (SELECT role FROM dba_roles WHERE role IN ('PRY2205_ROL_D','PRY2205_ROL_C')) LOOP
        EXECUTE IMMEDIATE 'DROP ROLE '||r.role;
    END LOOP;
END;
/

-- 1.2 CREACIÓN DE USUARIOS
CREATE USER PRY2205_EFT IDENTIFIED BY "EFT.Pry2205.2024" DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
CREATE USER PRY2205_EFT_DES IDENTIFIED BY "EFT.Des.2024" DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
CREATE USER PRY2205_EFT_CON IDENTIFIED BY "EFT.Con.2024" DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;



-- 1.3 CREACIÓN DE ROLES
CREATE ROLE PRY2205_ROL_D; -- Rol de Desarrollo
CREATE ROLE PRY2205_ROL_C; -- Rol de Consulta

-- 1.4 PRIVILEGIOS
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, CREATE SYNONYM TO PRY2205_EFT;
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE TO PRY2205_ROL_D;
GRANT CREATE SESSION TO PRY2205_ROL_C;

GRANT PRY2205_ROL_D TO PRY2205_EFT_DES;
GRANT PRY2205_ROL_C TO PRY2205_EFT_CON;
GRANT CREATE SESSION TO PRY2205_EFT, PRY2205_EFT_DES, PRY2205_EFT_CON;


-- ======================================================================
-- PASO 2: POBLAR TABLAS (EJECUTAR COMO PRY2205_EFT)
-- ======================================================================
-- ¡ATENCIÓN! 
-- 1. Desconéctese de SYSTEM.
-- 2. Conéctese como: PRY2205_EFT  (Pass: EFT.Pry2205.2024)
-- 3. Ejecute el script: "PRY2205_EFT_S9_CreaEsquemaPoblado (forma C).sql"
-- ======================================================================


-- ======================================================================
-- PASO 3: GRANTS Y SINÓNIMOS (EJECUTAR COMO SYSTEM)
-- ======================================================================
-- (Ejecutar SOLO después de que PRY2205_EFT haya creado las tablas)

-- 3.1 Grants de Lectura (INCLUYENDO ISAPRE Y TIPO_CONTRATO)
GRANT SELECT ON PRY2205_EFT.PROFESIONAL   TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.ASESORIA      TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.EMPRESA       TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.PROFESION     TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.ISAPRE        TO PRY2205_ROL_D; -- ¡Nuevo!
GRANT SELECT ON PRY2205_EFT.TIPO_CONTRATO TO PRY2205_ROL_D; -- ¡Nuevo!

-- 3.2 Sinónimos Públicos Completos
CREATE OR REPLACE PUBLIC SYNONYM SYN_PROFESIONAL   FOR PRY2205_EFT.PROFESIONAL;
CREATE OR REPLACE PUBLIC SYNONYM SYN_ASESORIA      FOR PRY2205_EFT.ASESORIA;
CREATE OR REPLACE PUBLIC SYNONYM SYN_EMPRESA       FOR PRY2205_EFT.EMPRESA;
CREATE OR REPLACE PUBLIC SYNONYM SYN_PROFESION     FOR PRY2205_EFT.PROFESION; -- ¡Nuevo!
CREATE OR REPLACE PUBLIC SYNONYM SYN_ISAPRE        FOR PRY2205_EFT.ISAPRE;    -- ¡Nuevo!
CREATE OR REPLACE PUBLIC SYNONYM SYN_TIPO_CONTRATO FOR PRY2205_EFT.TIPO_CONTRATO; -- ¡Nuevo!



/* ======================================================================
   CASO 2: INFORME DE REMUNERACIONES (FINAL)
   EJECUTAR COMO: PRY2205_EFT_DES
   ====================================================================== */

-- 1. Limpieza de tabla anterior
BEGIN 
    EXECUTE IMMEDIATE 'DROP TABLE CARTOLA_PROFESIONALES PURGE'; 
EXCEPTION 
    WHEN OTHERS THEN NULL; 
END;
/

-- 2. Creación del informe
CREATE TABLE CARTOLA_PROFESIONALES AS
SELECT
    -- 1. RUT
    P.RUTPROF AS RUT_PROFESIONAL,
    
    -- 2. NOMBRE (Initcap para mayúscula/minúscula)
    INITCAP(P.NOMPRO || ' ' || P.APPPRO || ' ' || P.APMPRO) AS NOMBRE_PROFESIONAL,
    
    -- 3. PROFESION (Orden Alfabético: Contador saldrá antes que Ingeniero)
    PR.NOMPROFESION AS PROFESION,
    
    -- 4. ISAPRE
    I.NOMISAPRE AS ISAPRE,
    
    -- 5. SUELDO BASE
    P.SUELDO AS SUELDO_BASE,
    
    -- 6. % COMISION (Formato 0,XX)
    REPLACE(TO_CHAR(NVL(P.COMISION, 0), 'FM0D00'), '.', ',') AS PORC_COMISION_PROFESIONAL,
    
    -- 7. VALOR COMISION
    ROUND(NVL(P.SUELDO * P.COMISION, 0)) AS VALOR_TOTAL_COMISION,
    
    -- 8. VALOR HONORARIOS (Calculado según Tabla 4 de la pauta)
    -- Alias "PORCENTAJE_HONORARIO" aunque guarda el monto, como pide la imagen.
    ROUND(
        CASE 
            WHEN P.SUELDO BETWEEN 150000  AND 300000  THEN P.SUELDO * 0.40
            WHEN P.SUELDO BETWEEN 300001  AND 500000  THEN P.SUELDO * 0.38
            WHEN P.SUELDO BETWEEN 500001  AND 800000  THEN P.SUELDO * 0.36
            WHEN P.SUELDO BETWEEN 800001  AND 1200000 THEN P.SUELDO * 0.34
            WHEN P.SUELDO BETWEEN 1200001 AND 1500000 THEN P.SUELDO * 0.30
            WHEN P.SUELDO BETWEEN 1500001 AND 2000000 THEN P.SUELDO * 0.28
            WHEN P.SUELDO BETWEEN 2000001 AND 3000000 THEN P.SUELDO * 0.26
            WHEN P.SUELDO > 3000000                   THEN P.SUELDO * 0.24
            ELSE 0
        END
    ) AS PORCENTAJE_HONORARIO,
    
    -- 9. BONO MOVILIZACION
    CASE TC.NOMTCONTRATO 
        WHEN 'Indefinido Jornada Completa' THEN 150000
        WHEN 'Indefinido Jornada Parcial'  THEN 120000
        WHEN 'Plazo fijo'                  THEN 60000
        WHEN 'Honorarios'                  THEN 50000
        ELSE 0
    END AS BONO_MOVILIZACION,
    
    -- 10. TOTAL A PAGAR (Suma de los montos anteriores)
    (
        P.SUELDO + 
        ROUND(NVL(P.SUELDO * P.COMISION, 0)) +
        ROUND(
            CASE 
                WHEN P.SUELDO BETWEEN 150000  AND 300000  THEN P.SUELDO * 0.40
                WHEN P.SUELDO BETWEEN 300001  AND 500000  THEN P.SUELDO * 0.38
                WHEN P.SUELDO BETWEEN 500001  AND 800000  THEN P.SUELDO * 0.36
                WHEN P.SUELDO BETWEEN 800001  AND 1200000 THEN P.SUELDO * 0.34
                WHEN P.SUELDO BETWEEN 1200001 AND 1500000 THEN P.SUELDO * 0.30
                WHEN P.SUELDO BETWEEN 1500001 AND 2000000 THEN P.SUELDO * 0.28
                WHEN P.SUELDO BETWEEN 2000001 AND 3000000 THEN P.SUELDO * 0.26
                WHEN P.SUELDO > 3000000                   THEN P.SUELDO * 0.24
                ELSE 0
            END
        ) +
        (CASE TC.NOMTCONTRATO 
            WHEN 'Indefinido Jornada Completa' THEN 150000
            WHEN 'Indefinido Jornada Parcial'  THEN 120000
            WHEN 'Plazo fijo'                  THEN 60000
            WHEN 'Honorarios'                  THEN 50000
            ELSE 0
        END)
    ) AS TOTAL_PAGAR

FROM SYN_PROFESIONAL P
JOIN SYN_PROFESION PR ON P.IDPROFESION = PR.IDPROFESION
JOIN SYN_ISAPRE I     ON P.IDISAPRE = I.IDISAPRE
JOIN SYN_TIPO_CONTRATO TC ON P.IDTCONTRATO = TC.IDTCONTRATO
-- ORDEN: Profesión (A-Z), Sueldo (Desc), Comisión, Rut.
ORDER BY PR.NOMPROFESION, P.SUELDO DESC, P.COMISION, P.RUTPROF;

-- 3. Permiso para usuario Consulta
GRANT SELECT ON CARTOLA_PROFESIONALES TO PRY2205_ROL_C;

-- 4. Verificación
SELECT * FROM CARTOLA_PROFESIONALES;

/* ======================================================================
   CASO 3: VISTA VW_EMPRESAS_ASESORADAS (RUT CON PUNTOS)
   EJECUTAR COMO: PRY2205_EFT
   ====================================================================== */

-- 1. Limpieza
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW VW_EMPRESAS_ASESORADAS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- 2. Creación de la Vista
CREATE OR REPLACE VIEW VW_EMPRESAS_ASESORADAS AS
SELECT
    -- CORRECCIÓN RUT: Usamos ',.' para que el separador de miles (G) sea un punto.
    TRIM(TO_CHAR(E.RUT_EMPRESA, '99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')) || '-' || E.DV_EMPRESA AS RUT_EMPRESA,
    
    -- NOMBRE EMPRESA
    UPPER(E.NOMEMPRESA) AS NOMBRE_EMPRESA,
    
    E.IVA_DECLARADO AS IVA,
    
    -- AÑOS DE EXISTENCIA
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM E.FECHA_INICIACION_ACTIVIDADES) AS ANIOS_EXISTENCIA,
    
    -- TOTAL PROMEDIO
    ROUND(COUNT(A.IDEMPRESA) / 12) AS TOTAL_ASESORIAS_ANUALES,
    
    -- DEVOLUCIÓN IVA
    ROUND(E.IVA_DECLARADO * (ROUND(COUNT(A.IDEMPRESA) / 12) / 100)) AS DEVOLUCION_IVA,
    
    -- TIPO CLIENTE
    CASE
        WHEN ROUND(COUNT(A.IDEMPRESA) / 12) > 5 THEN 'CLIENTE PREMIUM'
        WHEN ROUND(COUNT(A.IDEMPRESA) / 12) BETWEEN 3 AND 5 THEN 'CLIENTE'
        ELSE 'CLIENTE POCO CONCURRIDO'
    END AS TIPO_CLIENTE,
    
    -- CORRESPONDE (Según Instrucciones Escritas)
    CASE
        -- CLIENTE PREMIUM
        WHEN ROUND(COUNT(A.IDEMPRESA) / 12) > 5 THEN
            CASE 
                WHEN ROUND(COUNT(A.IDEMPRESA) / 12) >= 7 THEN '1 ASESORIA GRATIS'
                ELSE '1 ASESORIA 40% DE DESCUENTO' 
            END
            
        -- CLIENTE
        WHEN ROUND(COUNT(A.IDEMPRESA) / 12) BETWEEN 3 AND 5 THEN
            CASE 
                WHEN ROUND(COUNT(A.IDEMPRESA) / 12) = 5 THEN '1 ASESORIA 30% DE DESCUENTO'
                ELSE '1 ASESORIA 20% DE DESCUENTO' 
            END
            
        -- POCO CONCURRIDO
        ELSE 'CAPTAR CLIENTE'
    END AS CORRESPONDE

FROM SYN_EMPRESA E
JOIN SYN_ASESORIA A ON E.IDEMPRESA = A.IDEMPRESA
WHERE EXTRACT(YEAR FROM A.FIN) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY E.RUT_EMPRESA, E.DV_EMPRESA, E.NOMEMPRESA, E.IVA_DECLARADO, E.FECHA_INICIACION_ACTIVIDADES
ORDER BY NOMBRE_EMPRESA ASC;

-- 3. Permisos
GRANT SELECT ON VW_EMPRESAS_ASESORADAS TO PRY2205_ROL_C;

-- 4. Verificación
SELECT * FROM VW_EMPRESAS_ASESORADAS;

/* ======================================================================
   DEMOSTRACIÓN CASO 3.2: OPTIMIZACIÓN
   ====================================================================== */

-- PASO 0: Conectar y validar usuario
-- (Asegúrate de estar conectado como PRY2205_EFT antes de ejecutar)
SHOW USER;

-- PASO 1: PREPARACIÓN (Borrar índice si ya existe para mostrar el caso base)
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX IDX_ASESORIA_FIN_EMP';
EXCEPTION 
    WHEN OTHERS THEN NULL; 
END;
/

-- PASO 2: MOSTRAR PLAN "ANTES" (Sin Índice)
-- Ejecuta estas dos líneas juntas para ver el costo actual
EXPLAIN PLAN FOR SELECT * FROM VW_EMPRESAS_ASESORADAS;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);
-- >> Fíjate que en la columna "Options" diga "FULL" en la tabla ASESORIA.

-- PASO 3: CREACIÓN DEL ÍNDICE (La Solución)
CREATE INDEX IDX_ASESORIA_FIN_EMP ON ASESORIA (FIN, IDEMPRESA);

-- PASO 4: MOSTRAR PLAN "DESPUÉS" (Optimizado)
-- Ejecuta estas dos líneas juntas para ver la mejora
EXPLAIN PLAN FOR SELECT * FROM VW_EMPRESAS_ASESORADAS;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);
-- >> Ahora en la columna "Options" debe decir "RANGE SCAN" usando tu índice.

-- ======================================================================
-- FIN DEL SCRIPT 
-- ======================================================================