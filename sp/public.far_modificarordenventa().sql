CREATE OR REPLACE FUNCTION public.far_modificarordenventa()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
        rordenventa record;
        cordenventaitem  refcursor;
        rordenventaitem record;
        codordenventa bigint;
        nroinforme bigint;
        rinformeordventa record;
        resp boolean;
      

BEGIN
              SELECT INTO rordenventa *  FROM tfar_ordenventa 
                                          NATURAL JOIN far_ordenventaitemimportes 
                                          NATURAL JOIN far_ordenventa;
	      IF FOUND THEN 
		IF(not nullvalue(rordenventa.aficabeceraidafiliado) AND rordenventa.aficabeceraidafiliado<> '0') THEN
			UPDATE far_ordenventa SET idafiliado = rordenventa.aficabeceraidafiliado
			WHERE idordenventa = rordenventa.idordenventa
			AND idcentroordenventa = rordenventa.idcentroordenventa;
                END IF;

		UPDATE far_ordenventaitemimportes SET oviiidafiliadocobertura = rordenventa.afiimportesidafiliado
                WHERE idordenventaitemimporte = rordenventa.idordenventaitemimporte
                AND idcentroordenventaitemimporte = rordenventa.idcentroordenventaitemimporte;
		
		IF(not nullvalue(rordenventa.nrorecetario) AND rordenventa.nrorecetario <> '0') THEN
			UPDATE far_ordenventareceta SET nrorecetario = rordenventa.nrorecetario,centro = rordenventa.centro
			    WHERE idordenventa = rordenventa.idordenventa
				AND idcentroordenventa = rordenventa.idcentroordenventa;
                END IF;
                
	      END IF;
              
return 'true';
END;
$function$
