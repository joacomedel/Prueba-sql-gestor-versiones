CREATE OR REPLACE FUNCTION public.iftableexistsparasp(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

 BEGIN

     /* check the table exist in database and is visible*/
 perform n.nspname ,c.relname
FROM pg_catalog.pg_class c 
LEFT JOIN pg_catalog.pg_namespace n ON n.oid
= c.relnamespace
where n.nspname like 'pg_temp_%' -- lo descomente el 8/09 x que la func me devolvia un valor erroneo AND pg_catalog.pg_table_is_visible(c.oid)
AND Upper(relname) = Upper($1);

     IF FOUND THEN
        RETURN TRUE;
     ELSE
        RETURN FALSE;
     END IF;

 END;
$function$
