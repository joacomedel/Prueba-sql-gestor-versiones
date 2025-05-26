CREATE OR REPLACE FUNCTION public.sys_verificarfechas()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       rtempo record;
       fechaanterior DATE;
       respuesta varchar;  
      
BEGIN 
     respuesta = '';
     fechaanterior = '2015-01-01';
     WHILE fechaanterior < current_date LOOP
    fechaanterior = fechaanterior +'1 day'::interval;
     --RAISE NOTICE 'verifico la fecha (%)', fechaanterior;

                  IF to_char(fechaanterior, 'd') <> '1' AND to_char(fechaanterior, 'd') <> '7' THEN 
			SELECT INTO rtempo ikfechainformacion from informacionkairos  where ikfechainformacion = fechaanterior	GROUP BY ikfechainformacion; 
			IF FOUND THEN 
				SELECT INTO rtempo ikfechainformacion from medicamentosys  where ikfechainformacion = fechaanterior	GROUP BY ikfechainformacion; 
				IF NOT FOUND THEN 
					--respuesta = concat(respuesta,',',fechaanterior::text);
					INSERT INTO temporal_fecha VALUES(fechaanterior);
					RAISE NOTICE 'Esta falta (%)', fechaanterior;
				END IF;
			END IF;
			
                  END IF;
    END LOOP;
 	

    
     return respuesta;
END;
$function$
