CREATE OR REPLACE FUNCTION public.cargarpersonaplan()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Proceso inserta persona a un plan de cobertura  */
DECLARE
       alta CURSOR FOR SELECT * FROM tempcargapersona;
	   elem RECORD;
       resultado boolean;
BEGIN

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
resultado = 'true';
/*Inserto  persona a un plan  */
        INSERT INTO plancobpersona (idplancobertura, nrodoc, tipodoc, idplancoberturas, pcpfechaingreso)
          VALUES (elem.idplancobertura,elem.nrodoc,elem.tipodoc,elem.idplancoberturas,elem.pcpfechaingreso);

fetch alta into elem;
END LOOP;
   CLOSE alta;
return resultado;
END;
$function$
