CREATE OR REPLACE FUNCTION public.temporalhayqueborrarlo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Para arreglar los estados de las personas de sosunc, luego de que se cargaron los aportes */
DECLARE
	alta CURSOR FOR SELECT * FROM persona
                           WHERE barra = 36;

    elem RECORD;
   
    resultado boolean;
  
    fechafinultimoaporte date;
	
BEGIN

resultado = true;
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
     SELECT INTO fechafinultimoaporte * FROM ultimoaporterecibido(elem.nrodoc,elem.tipodoc);
IF (not nullvalue(fechafinultimoaporte)) THEN
  IF (elem.barra = 36) THEN
     UPDATE persona SET fechafinos=fechafinultimoaporte + 30 WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
  END IF;
END IF;

fetch alta into elem;
END LOOP;
CLOSE alta;
return resultado;
END;
$function$
