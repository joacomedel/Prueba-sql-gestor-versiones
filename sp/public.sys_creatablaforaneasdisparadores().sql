CREATE OR REPLACE FUNCTION public.sys_creatablaforaneasdisparadores()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE 
       
BEGIN


CREATE TABLE  clavesforaneas AS (
SELECT 'ALTER TABLE '||nspname||'.'||relname||' ADD CONSTRAINT '||conname||' '||  pg_get_constraintdef(pg_constraint.oid)||';',false as seejecuto
FROM pg_constraint
INNER JOIN pg_class ON conrelid=pg_class.oid
INNER JOIN pg_namespace ON pg_namespace.oid=pg_class.relnamespace
WHERE relname not ilike 'pg%' AND pg_get_constraintdef(pg_constraint.oid) ilike '%FOREIGN%'
ORDER BY CASE WHEN contype='f' THEN 0 ELSE 1 END DESC,contype DESC,nspname DESC,relname DESC,conname DESC
);

DROP TABLE tabladisparadores;
CREATE TABLE tabladisparadores AS (

SELECT replace(sql,'OR ON',' ON ') as sql,false seejecuto FROM (
SELECT
 'CREATE TRIGGER ' || trigger_name || ' ' || ' ' || action_timing || ' ' || text_concatenar(event_manipulation|| ' OR ') || 'ON ' || trigger_schema ||'.'|| event_object_table || ' FOR EACH ROW ' || action_statement as sql

FROM information_schema.triggers
GROUP BY  trigger_schema,trigger_name,action_timing,event_object_table,action_statement
ORDER BY event_object_table
) as t
);

DROP tABLE tablasasincronizar_dos;
create table tablasasincronizar_dos AS (
SELECT *,false as seejecuto  FROM tablasasincronizar
);

-- USAR SELECT farm_arreglafk(); para restaurar las funciones


RETURN 'true';
END;$function$
