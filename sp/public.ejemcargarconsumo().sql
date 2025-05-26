CREATE OR REPLACE FUNCTION public.ejemcargarconsumo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Proceso que migra las ordenes ingresadas en tempconsumo  */
DECLARE
       alta CURSOR FOR SELECT * FROM tempconsumo;
	   elem RECORD;
       resultado boolean;
BEGIN

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
resultado = 'true';
/*Inserto la Orden y afiliado */
        INSERT INTO consumo (nroorden,centro,nrodoc,tipodoc)
          VALUES (elem.nroorden,elem.centro,elem.nrodoc,elem.tipodoc);

fetch alta into elem;
END LOOP;
   CLOSE alta;
return resultado;
END;
$function$
