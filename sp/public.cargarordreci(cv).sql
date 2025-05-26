CREATE OR REPLACE FUNCTION public.cargarordreci(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	ord CURSOR FOR SELECT * FROM orden;
	reci RECORD;
BEGIN

    OPEN ord;
    FETCH ord INTO reci;
    WHILE  found LOOP
		INSERT INTO ordreci VALUES(reci.nrodoc,reci.barra,reci.fecha,reci.idosreci,reci.idreci,reci.vto,reci.nroorden);
		IF $1 <> '' THEN
			/*	INSERT INTO verificacion (codigo,nrodoc,rango,barra,fecha) VALUES ($1,reci.nrodoc,2,reci.barra,current_date);*/
		END IF;
	fetch ord into reci;
    END LOOP;
    CLOSE ord;
return 'true';
END;
$function$
