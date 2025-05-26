CREATE OR REPLACE FUNCTION public.buscardireccion(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	pers RECORD;
	resultado boolean;
	usuario alias for $4;
	tipodisc varchar;
BEGIN
select into pers direccion.barrio,direccion.calle,direccion.nro,direccion.tira,direccion.piso,direccion.dpto,
           provincia.descrip as provincia,localidad.descrip as localidad,tiposdoc.descrip as tipodoc
from persona, direccion, localidad, provincia,tiposdoc 
where persona.tipodoc = $1 and persona.nrodoc =$2 and persona.barra= $3 
      and persona.iddireccion = direccion.iddireccion and persona.tipodoc = tiposdoc.tipodoc
      and direccion.idlocalidad = localidad.idlocalidad and direccion.idprovincia = provincia.idprovincia;
if FOUND
  then--existe el titular con direccion
    DELETE FROM rdireccion WHERE idusuario = usuario;
    INSERT INTO rdireccion  VALUES ($2,pers.barrio,pers.calle,pers.nro,pers.tira,pers.piso,pers.dpto,pers.provincia,pers.localidad,usuario,pers.tipodoc);
    resultado ='true';	 
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;

return resultado;
END;
$function$
