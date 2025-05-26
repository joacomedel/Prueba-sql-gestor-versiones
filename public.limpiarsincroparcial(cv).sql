CREATE OR REPLACE FUNCTION public.limpiarsincroparcial(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       csql refcursor;
       rsql record;
       
BEGIN
     OPEN csql FOR  select concat('DELETE FROM ',$1,'.',tablename,';') as elsql
            from pg_tables 
            where schemaname=$1 and
            tablename NOT IN (
                        'cliente',
                        'direccion',
                        'facturaorden',
                        'facturaventa',
                        'itemfacturaventa',
                        'facturaventacupon',
                        'far_afiliado',
                        'far_ordenventa',
                        'far_ordenventaestado',
                        'far_ordenventaitem',
                        'far_ordenventaitemimportes',
                        'far_ordenventaitemitemfacturaventa',
                        'far_validacion',
                        'far_validacionitems',
                        'far_validacionxml',
                        'ingresosusuarios',
                        'facturaventausuario');
     FETCH csql INTO rsql;
           WHILE FOUND LOOP
                 execute rsql.elsql;
                 FETCH csql INTO rsql;
           END LOOP;

     CLOSE csql;


return 	true;
END;
$function$
