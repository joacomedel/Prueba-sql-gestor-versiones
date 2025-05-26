CREATE OR REPLACE FUNCTION public.prueba(date, date)
 RETURNS SETOF elempadron
 LANGUAGE plpgsql
AS $function$
DECLARE
   nacimiento alias for $1;
   fechamax alias for $2;
   resultado setof elempadron;
 
BEGIN

SELECT  INTO resultado
        persona.nrodoc as nrodoc, persona.fechanac as fechanac,persona.tipodoc as tipodoc,nombres, apellido, fechainios, descrip, barra 
	FROM estados , afilsosunc , persona , barras 
	where afilsosunc.nrodoc = persona.nrodoc 
	AND afilsosunc.tipodoc = persona.tipodoc 
	and afilsosunc.idestado = 2 	
	and afilsosunc.idestado = estados.idestado 
	and persona.nrodoc = barras.nrodoc 
	aND fechainios <= fechamax
	and persona.fechanac >=nacimiento
	and prioridad =  (SELECT min(prioridad) 
		FROM barras where 
		persona.nrodoc = barras.nrodoc );
return resultado;

END;
$function$
