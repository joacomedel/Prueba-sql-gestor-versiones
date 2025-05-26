CREATE OR REPLACE FUNCTION public.prueba(boolean)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	pers RECORD;
	resultado boolean;
	
BEGIN

SELECT INTO pers persona.nrodoc,persona.apellido,persona.nombres,persona.fechanac,persona.sexo,persona.estcivil,persona.email,persona.carct,persona.telefono,tiposdoc.descrip as tipodoc, persona.barra 
	FROM persona, tiposdoc WHERE $1;
if FOUND
  then--existe una persona y sera cargada en la tabla para reportes rpersonalesuno
	INSERT INTO rpersonalesuno VALUES(pers.nrodoc,pers.apellido,pers.nombres,pers.fechanac,pers.sexo,pers.estcivil,pers.email,pers.carct,pers.telefono,'true',pers.tipodoc,pers.barra,'lala');
  	resultado ='true';
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;
return resultado;
END;
$function$
