CREATE OR REPLACE FUNCTION public.farm_arreglafk()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/****/
DECLARE
       rsql RECORD;
       csql refcursor;
       updatesincro varchar;

BEGIN

     OPEN csql FOR SELECT * FROM clavesforaneas WHERE not seejecuto limit 100 ; 
     FETCH  csql INTO rsql;
     WHILE FOUND LOOP
             BEGIN
		EXECUTE concat(rsql.sql);
		UPDATE clavesforaneas SET seejecuto = true WHERE sql = rsql.sql;
		FETCH  csql INTO rsql;   
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'entre (%)',rsql.sql;
			UPDATE clavesforaneas SET seejecuto = false WHERE sql = rsql.sql;
			FETCH  csql INTO rsql;   
		END;
            
     END LOOP;
     CLOSE csql;

	--- Ahora cargo los disparadores

     OPEN csql FOR SELECT * FROM tabladisparadores WHERE not seejecuto limit 100 ; 
     FETCH  csql INTO rsql;
     WHILE FOUND LOOP
             BEGIN
		EXECUTE concat(rsql.sql);
		UPDATE tabladisparadores SET seejecuto = true WHERE sql = rsql.sql;
		FETCH  csql INTO rsql;   
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'entre (%)',rsql.sql;
			UPDATE tabladisparadores SET seejecuto = false WHERE sql = rsql.sql;
			FETCH  csql INTO rsql;   
		END;
            
     END LOOP;
     CLOSE csql;

      --- Genero los movimientos en el sincro 
	
	OPEN csql FOR SELECT * FROM tablasasincronizar_dos WHERE not seejecuto ORDER BY orden LIMIT 50; 
	FETCH  csql INTO rsql;
	WHILE FOUND LOOP
             BEGIN
                updatesincro = concat('UPDATE ',rsql.nombre, ' SET ',rsql.nombre,'cc = ',rsql.nombre,'cc WHERE ',rsql.nombre,'cc >= ''2018-06-09''');
		--RAISE NOTICE '(%)',updatesincro;	
		EXECUTE updatesincro;
		UPDATE tablasasincronizar_dos SET seejecuto = true WHERE nombre = rsql.nombre;
		FETCH  csql INTO rsql;   
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'error con (%)',updatesincro;
			UPDATE tablasasincronizar_dos SET seejecuto = false WHERE nombre = rsql.nombre;
			FETCH  csql INTO rsql;   
		END;
            
     END LOOP;
     CLOSE csql;

return true;
END;
$function$
