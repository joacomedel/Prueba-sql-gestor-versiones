CREATE OR REPLACE FUNCTION public.buscarpersonalesclientes(nrocliente character varying, barra integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	clien RECORD;
	resultado boolean;
	usuario alias for $3;

BEGIN
select into clien * from
       ((SELECT cliente.nrocliente, cliente.barra, cliente.cuitini,cliente.
       cuitmedio,cliente.cuitfin,descripcioncliente,
       descripcioniva,denominacion,cliente.telefono,
       cliente.email,nombres, apellido,descrip FROM persona JOIN cliente
       ON(persona.nrodoc=cliente.nrocliente AND persona.barra=cliente.barra)
       LEFT JOIN osreci ON(osreci.idosreci=cliente.nrocliente AND osreci.barra=
       cliente.barra)
       NATURAL JOIN tipocliente NATURAL JOIN  condicioniva
       LEFT JOIN personajuridicabis ON (cliente.nrocliente=personajuridicabis.
       nrocliente AND cliente.barra=personajuridicabis.barra)
       WHERE
       cliente.nrocliente=nrocliente AND cliente.barra=barra)
       UNION
       (SELECT cliente.nrocliente, cliente.barra, cliente.cuitini,cliente.
       cuitmedio,cliente.cuitfin,descripcioncliente,
       descripcioniva,denominacion,cliente.telefono,
       cliente.email,nombres, apellido,descrip FROM osreci JOIN
       cliente ON(osreci.idosreci=cliente.nrocliente AND osreci.barra=
       cliente.barra)
       LEFT JOIN persona ON(persona.nrodoc=cliente.nrocliente AND persona.barra=cliente.barra)
       NATURAL JOIN tipocliente NATURAL JOIN
       condicioniva LEFT JOIN personajuridicabis ON (cliente.nrocliente=
       personajuridicabis.nrocliente AND cliente.barra=personajuridicabis.
       barra) WHERE  cliente.nrocliente=nrocliente AND cliente.barra=barra)
       UNION
       (SELECT cliente.nrocliente, cliente.barra, cliente.cuitini,cliente.
       cuitmedio,cliente.cuitfin,descripcioncliente,
       descripcioniva,denominacion,cliente.telefono,
       cliente.email,nombres, apellido,descrip  FROM personajuridicabis
       JOIN
       cliente ON(cliente.nrocliente=
       personajuridicabis.nrocliente AND cliente.barra=personajuridicabis.barra)
       LEFT JOIN persona ON(persona.nrodoc=cliente.nrocliente
       AND persona.barra=cliente.barra)
       LEFT JOIN osreci ON(osreci.idosreci=cliente.nrocliente AND osreci.barra=
       cliente.barra)
       NATURAL JOIN tipocliente NATURAL JOIN
       condicioniva WHERE cliente.nrocliente=nrocliente AND cliente.barra=barra))
        AS datoscliente;

if FOUND
  then--existe el cliente de sosunc como tal
		   DELETE FROM tdatoscliente WHERE idusuario = usuario;
		   INSERT INTO tdatoscliente VALUES (nrocliente,barra,clien.cuitini,clien.cuitmedio,clien.cuitfin,clien.email,
           clien.descripcioncliente,clien.descripcioniva,clien.denominacion,clien.telefono,usuario,
           clien.nombres,clien.apellido,clien.descrip);
		   resultado ='true';	
else --no hay un cliente con los datos especificados como parametros
  	resultado = 'false';
end if;
return resultado;
END;
$function$
