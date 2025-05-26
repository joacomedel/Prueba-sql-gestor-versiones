CREATE OR REPLACE FUNCTION public.buscarpartpersonalesdostitureci(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	pers RECORD;
	resultado boolean;
	usuario alias for $4;
        op boolean;

BEGIN
op=$7;
 
select into pers persona.fechainios,persona.fechafinos,reciprocidades.descrip as tiporeci,
            estados.descrip as estado, tiposdoc.descrip as tipodoc,
			persona.fechafinos, osreci.descrip as obrasocial
from persona,reciprocidades,estados,tiposdoc,afilreci,osreci
where persona.tipodoc = $1 and persona.nrodoc =$2 and persona.barra= $3 
     and afilreci.nrodoc = persona.nrodoc and afilreci.tipodoc = persona.tipodoc
     and afilreci.idreci = reciprocidades.idreci and afilreci.idosreci = osreci.idosreci and persona.barra=osreci.barra     
     and estados.idestado = afilreci.idestado and persona.tipodoc = tiposdoc.tipodoc;
if FOUND
  then--existe el beneficiario de sosunc como tal 
     DELETE FROM rpersonalesdos WHERE idusuario = usuario;
     INSERT INTO rpersonalesdos VALUES ($2,'',pers.fechainios,pers.fechafinos,'9999-12-31',pers.obrasocial,0,'false',0,pers.estado,0 ,pers.tiporeci,'',pers.tipodoc,usuario);
     resultado ='true';	 
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;

return resultado;

END;
$function$
