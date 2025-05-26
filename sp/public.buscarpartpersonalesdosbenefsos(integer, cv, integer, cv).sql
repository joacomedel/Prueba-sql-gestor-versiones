CREATE OR REPLACE FUNCTION public.buscarpartpersonalesdosbenefsos(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	pers RECORD;
	resultado boolean;
	usuario alias for $4;
BEGIN
select INTO pers persona.fechainios,persona.fechafinos,
       osexterna.descrip as obrasocial,
       testado.descestado as estado,
       tiposdoc.descrip as tipodoc,
       benefsosunc.barramutu,benefsosunc.nromututitu,benefsosunc.mutual,benefsosunc.nroosexterna,
       tvinculo.descvinculo as vinculo
from persona
NATURAL JOIN  benefsosunc
NATURAL JOIN (SELECT estados.descrip as descestado,estados.idestado FROM estados) as testado
NATURAL JOIN tiposdoc
NATURAL JOIN (SELECT vinculos.descrip as descvinculo,vinculos.idvin FROM vinculos) as tvinculo
Left OUTER JOIN osexterna USING (idosexterna)
where persona.tipodoc = $1 and persona.nrodoc =$2 and persona.barra= $3;

if FOUND
  then--existe el beneficiario de sosunc como tal 
     INSERT INTO rpersonalesdos VALUES ($2,'',pers.fechainios,pers.fechafinos,'9999-12-31',pers.obrasocial,pers.nroosexterna,pers.mutual,pers.nromututitu,pers.estado,pers.barramutu,'',pers.vinculo,pers.tipodoc,usuario);
     resultado ='true';	 
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;

return resultado;
END;
$function$
