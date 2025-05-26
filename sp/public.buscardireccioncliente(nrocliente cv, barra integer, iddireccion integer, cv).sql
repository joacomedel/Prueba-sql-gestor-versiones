CREATE OR REPLACE FUNCTION public.buscardireccioncliente(nrocliente character varying, barra integer, iddireccion integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	clien RECORD;
	resultado boolean;
	usuario alias for $4;

BEGIN
select into clien direccion.barrio,direccion.calle,direccion.nro,direccion.tira,
direccion.piso,direccion.dpto,provincia.descrip as provincia,localidad.descrip
as localidad
from cliente, direccion, localidad, provincia
     where cliente.nrocliente=nrocliente AND cliente.barra = barra
     and cliente.iddireccion = direccion.iddireccion
     and direccion.idlocalidad = localidad.idlocalidad and direccion.idprovincia = provincia.idprovincia;
if FOUND
  then--existe el cliente con direccion
    DELETE FROM tdireccion WHERE idusuario = usuario;
    INSERT INTO tdireccion  VALUES (nrocliente,barra,clien.barrio,clien.calle,clien.nro,clien.tira,clien.piso,clien.dpto,
    clien.provincia,clien.localidad,usuario);
    resultado ='true';	
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;

return resultado;
END;
$function$
