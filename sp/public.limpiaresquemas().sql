CREATE OR REPLACE FUNCTION public.limpiaresquemas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	esquemas cursor for select * from esquemasasincronizar WHERE nombre <> 'sincro';
	esquema record;
	tablas cursor for select * from tablasasincronizar  order by orden;
	tabla record;
        rexiste record; 
        v_result varchar;
begin
	open esquemas;
	fetch esquemas into esquema;
	while FOUND loop
               -- RAISE NOTICE ' esquema (%)',esquema.nombre;
		--execute concat('DROP SCHEMA  IF EXISTS  ',esquema.nombre,' CASCADE ',';');
                
                open tablas;
		fetch tablas into tabla;
                while FOUND loop
                RAISE NOTICE ' tabla (%)',tabla.nombre;
                SELECT INTO rexiste * FROM information_schema.columns  WHERE table_name=tabla.nombre  AND table_schema = esquema.nombre  LIMIT 1;
                IF FOUND  THEN 
                        
			    execute concat('DELETE FROM ',esquema.nombre,'.',tabla.nombre,';');
                          -- MaLaPi 24-12-2020 Modifico para que elimine la tabla de los esquemas de las delegaciones en lugar de solo limpiarlas
                          --RAISE NOTICE ' SQL (%)',concat('DROP TABLE ',esquema.nombre,'.',tabla.nombre,';');
                          --execute concat('DROP TABLE ',esquema.nombre,'.',tabla.nombre,';');
                ELSE
                    RAISE NOTICE ' No existe la tabla (%) ',concat(esquema.nombre,'.',tabla.nombre);
                END IF;
		fetch tablas into tabla;
		end loop;
		close tablas;

		fetch esquemas into esquema;
	end loop;
	close esquemas;



return 'true';
end;
$function$
