CREATE OR REPLACE FUNCTION public.amdireccion(bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Ingresa o Actualiza una direccion */
/*amdireccion(1)
$1 Id de Direccion*/
DECLARE
	iddire alias for $1;
	elem RECORD;
	loc RECORD;
	prov RECORD;
	anterior RECORD;
	resultado boolean;
BEGIN
SELECT INTO elem * FROM tempdireccion WHERE tempdireccion.iddireccion = iddire;
IF NOT FOUND THEN
resultado = 'false';
ELSE
SELECT INTO loc * FROM localidad WHERE localidad.descrip = elem.idlocalidad;
IF NOT FOUND THEN
   UPDATE tempdireccion SET error = 'NOLOCALIDAD' WHERE tempdireccion.iddireccion = elem.iddireccion;
ELSE /*La Localidad si Existe*/
     SELECT INTO prov * FROM provincia WHERE provincia.descrip = elem.idprovincia;
     IF NOT FOUND THEN
        UPDATE tempdireccion SET error = 'NOPROVINCIA' WHERE tempdireccion.iddireccion = elem.iddireccion;
     ELSE /*La Provincia si existe*/
          SELECT INTO anterior * FROM direccion WHERE direccion.iddireccion = elem.iddireccion;
          IF NOT FOUND THEN
             INSERT INTO direccion (iddireccion,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
                         VALUES (elem.iddireccion,elem.barrio,elem.calle,elem.nro,elem.tira,elem.piso,elem.dpto,prov.idprovincia,loc.idlocalidad);
             ELSE
                 UPDATE direccion SET
                  barrio = elem.barrio,calle = elem.calle,
                  nro = elem.nro,tira =elem.tira ,piso =elem.piso ,dpto = elem.dpto,
                  idprovincia =prov.idprovincia ,idlocalidad =loc.idlocalidad
            WHERE iddireccion = elem.iddireccion;
          END IF;
     DELETE FROM tempdireccion WHERE tempdireccion.iddireccion = elem.iddireccion;
     END IF;
END IF;
resultado = 'true';
END IF;
RETURN resultado;
END;
$function$
