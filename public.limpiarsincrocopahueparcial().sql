CREATE OR REPLACE FUNCTION public.limpiarsincrocopahueparcial()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       csql refcursor;
       rsql record;
       
BEGIN
    --Elimino las tablas que no deben ser traidas de copahue, para evitar errores en otros modulos
     OPEN csql FOR  select concat('DELETE FROM copahue.',tablename,';') as elsql
            from pg_tables 
            where schemaname='copahue' and
            tablename IN (
                        'acciofar',
                        'tamanos',
                        'formas',
                        'unidadpotencia',
                        'tipounidad',
                        'vias',
                        'monodroga',
                        'multidroga',
                        'nuevadroga',
                        'manextra',
                        'medicamento',
                        'valormedicamento');
     FETCH csql INTO rsql;
           WHILE FOUND LOOP
                 execute rsql.elsql;
                 FETCH csql INTO rsql;
           END LOOP;

     CLOSE csql;


return 	true;
END;
$function$
