CREATE OR REPLACE FUNCTION public.turismo_abmtarifasfacturador()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	resultado RECORD;
	rusuario RECORD;
	
	
	elcursor refcursor;
	elem RECORD;
BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;


OPEN elcursor FOR SELECT *
		from temp_tarifasfacturador;
		
FETCH elcursor into elem;
WHILE  found LOOP


	IF (elem.idfacturaventatarifas is null OR elem.idfacturaventatarifas = 0) THEN
	      --MaLaPi 31-01-2018 Por el momento, no puede haber mas de un valor por tipo de tarifa vigente
              --MaLaPi 31-01-2018 Solo cambio el valor si el monto cambio. 
		UPDATE facturaventatarifas SET fvtfechafin=now() 
		WHERE idfacturaventatarifatipos=elem.idfacturaventatarifatipos 
			AND  nullvalue(fvtfechafin)
                        AND (fvtmontoafil <> elem.fvtmontoafil 
                             OR fvtmontonoafil <> elem.fvtmontonoafil );
                IF FOUND THEN 
			--MaLaPi 31-01-2018 Por el momento, la fecha de inicio siempre es hoy 
			INSERT INTO facturaventatarifas(idfacturaventatarifatipos,fvtseaplicaacentro, fvtmontoafil,fvtmontonoafil, fvtfechainicio, fvtidusuario)
			VALUES (elem.idfacturaventatarifatipos,elem.fvtseaplicaacentro,elem.fvtmontoafil,elem.fvtmontonoafil,now(),rusuario.idusuario);
		END IF;

        ELSE 
		UPDATE facturaventatarifas SET idfacturaventatarifatipos=elem.idfacturaventatarifatipos, 
						fvtseaplicaacentro=elem.fvtseaplicaacentro
                                                , fvtmontoafil=elem.fvtmontoafil
                                                , fvtmontonoafil=elem.fvtmontonoafil
						, fvtfechainicio=elem.fvtfechainicio,
						fvtidusuario=rusuario.idusuario
		WHERE idfacturaventatarifas=elem.idfacturaventatarifas 
			AND  idcentrofacturaventatarifas=elem.idcentrofacturaventatarifas;
        END IF;
 
fetch elcursor into elem;
END LOOP;
close elcursor;		

return 'true';
END;
$function$
