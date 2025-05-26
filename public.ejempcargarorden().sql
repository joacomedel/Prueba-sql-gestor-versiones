CREATE OR REPLACE FUNCTION public.ejempcargarorden()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Proceso que migra las ordenes ingresadas en temporden  */
DECLARE
       alta CURSOR FOR SELECT * FROM temporden;
	   elem RECORD;
       resultado boolean;
BEGIN

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
resultado = 'true';
/*Inserto la Orden de pago */
        INSERT INTO orden (nroorden,centro,fechaemision,tipo,asi)
          VALUES (elem.nroorden,elem.centro,elem.fechaemision,elem.tipo,elem.asi);

fetch alta into elem;
END LOOP;
   CLOSE alta;
return resultado;
END;
$function$
