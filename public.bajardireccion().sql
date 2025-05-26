CREATE OR REPLACE FUNCTION public.bajardireccion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursordire CURSOR FOR SELECT * FROM tempdireccion;
	dire RECORD;
BEGIN

    OPEN cursordire;
    FETCH cursordire into dire;
    WHILE  found LOOP

        INSERT INTO direccion(iddireccion,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
                               VALUES(dire.iddireccion,dire.barrio, dire.calle, dire.nro, dire.tira, dire.piso, dire.dpto, CAST(dire.idprovincia as bigint), cast(dire.idlocalidad as bigint));

    fetch cursordire into dire;
    END LOOP;
    close cursordire;

return 'true';
END;
$function$
