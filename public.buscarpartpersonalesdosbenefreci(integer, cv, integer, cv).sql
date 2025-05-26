CREATE OR REPLACE FUNCTION public.buscarpartpersonalesdosbenefreci(integer, character varying, integer, character varying)
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
            estados.descrip as estado, tiposdoc.descrip as tipodoc, vinculos.descrip as vinculo,
			benefreci.fechavtoreci, osreci.descrip as obrasocial
from persona, benefreci,reciprocidades,estados, tiposdoc,vinculos,afilreci,osreci
where persona.tipodoc = $1 and persona.nrodoc =$2 and persona.barra= $3 
      and benefreci.nrodoc = persona.nrodoc and benefreci.tipodoc = persona.tipodoc
     and benefreci.idreci = reciprocidades.idreci
     and estados.idestado = benefreci.idestado and persona.tipodoc = tiposdoc.tipodoc
     and benefreci.nrodoctitu = afilreci.nrodoc and benefreci.tipodoctitu = afilreci.tipodoc
     and afilreci.idosreci = osreci.idosreci and persona.barra=osreci.barra;     
if FOUND
  then--existe el beneficiario de sosunc como tal 
     DELETE FROM rpersonalesdos WHERE idusuario = usuario;
     INSERT INTO rpersonalesdos VALUES ($2,'',pers.fechainios,pers.fechavtoreci,'9999-12-31',pers.obrasocial,0,'false',0,pers.estado,0 ,pers.tiporeci,pers.vinculo,pers.tipodoc,usuario);
     resultado ='true';	 
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;

return resultado;
END;
$function$
