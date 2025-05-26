CREATE OR REPLACE FUNCTION public.ejemcargarordenconsulta()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Proceso que migra los recetarios ingresados en temprecetario  */
DECLARE
       alta CURSOR FOR SELECT * FROM tempordenconsulta;
	   elem RECORD;
       resultado boolean;
BEGIN

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
resultado = 'true';

        INSERT INTO ordconsulta (centro,nroorden,idplancovertura)
          VALUES (elem.centro,elem.nroorden,elem.idplancobertura);

fetch alta into elem;
END LOOP;
   CLOSE alta;
return resultado;
END;
$function$
