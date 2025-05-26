CREATE OR REPLACE FUNCTION public.buscarpartpersonalesdostitusos(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	pers RECORD;
	mutu RECORD;
	resultado boolean;
	usuario alias for $4;
	cuil varchar;
BEGIN
select into pers
      persona.nrodoc,persona.fechainios,persona.fechafinos,
      afilsosunc.nrocuilini,afilsosunc.nrocuilfin,afilsosunc.fechainiunc,afilsosunc.nroosexterna,
      osexterna.descrip,
      testado.descestado as estado,
      tiposdoc.descrip as tipodoc
from persona
NATURAL JOIN afilsosunc
NATURAL JOIN (SELECT estados.descrip as descestado,estados.idestado FROM estados) as testado
NATURAL JOIN tiposdoc
Left OUTER JOIN osexterna USING (idosexterna)
where persona.tipodoc = $1 and persona.nrodoc =$2 and persona.barra= $3;

if FOUND
  then--existe el titular de sosunc como tal ahora hay que buscar su mutual
	select into mutu afilidoc.mutu as mutu1, afilidoc.nromutu as nromutu1 from afilidoc where (afilidoc.tipodoc = $1 and afilidoc.nrodoc =$2 and afilidoc.mutu = 'true' )
	union
	select afilinodoc.mutu as mutu2,afilinodoc.nromutu as nromutu2 from afilinodoc where  (afilinodoc.tipodoc = $1 and afilinodoc.nrodoc =$2 and afilinodoc.mutu = 'true' )
	union
	select afiliauto.mutu as mutu3,afiliauto.nromutu as nromutu3 from afiliauto where (afiliauto.tipodoc = $1 and afiliauto.nrodoc =$2 and afiliauto.mutu = 'true' )
	union
	select afilisos.mutu as mutu4,afilisos.nromutu as nromutu4 from afilisos where (afilisos.tipodoc = $1 and afilisos.nrodoc =$2 and afilisos.mutu = 'true' )
	union
	select afilirecurprop.mutu as mutu5, afilirecurprop.nromutu as nromutu5 from afilirecurprop where (afilirecurprop.tipodoc = $1 and afilirecurprop.nrodoc =$2 and afilirecurprop.mutu = 'true');
	if FOUND
		then --el titular de sosunc tiene mutual
		   DELETE FROM rpersonalesdos WHERE idusuario = usuario;
		   cuil = concat(pers.nrocuilini ,'-',$2,'-',pers.nrocuilfin);
		   INSERT INTO rpersonalesdos VALUES ($2,cuil,pers.fechainios,pers.fechafinos,pers.fechainiunc,pers.descrip,pers.nroosexterna,'true',mutu.nromutu1,pers.estado,0,'','',pers.tipodoc,usuario);
		   resultado ='true';	
		else --el titular de sosunc no tiene mutual
		   DELETE FROM rpersonalesdos WHERE idusuario = usuario;
		   cuil = concat(pers.nrocuilini ,'-',$2,'-',pers.nrocuilfin);
		   INSERT INTO rpersonalesdos VALUES ($2,cuil,pers.fechainios,pers.fechafinos,pers.fechainiunc,pers.descrip,pers.nroosexterna,'false',0,pers.estado,0,'','',pers.tipodoc,usuario);
		   resultado ='true';	
	end if;
  else --no hay una persona con los datos especificados como parÃÂ¡metros
  	resultado = 'false';
end if;
return resultado;
END;
$function$
