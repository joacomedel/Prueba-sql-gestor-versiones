CREATE OR REPLACE FUNCTION public.amdireccionconvenio()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/*Ingresa o actualiza la direccion de un convenio */
DECLARE
	
	elem RECORD;
	loc RECORD;
	prov RECORD;
	anterior RECORD;
	resultado boolean;
        iddir integer;
BEGIN

SELECT INTO elem * FROM tempdireccion;
IF (nullvalue(elem.iddireccion)) THEN
             INSERT INTO direccion (barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
                         VALUES (elem.barrio,elem.calle,elem.nro,elem.tira,elem.piso,elem.dpto,elem.idprovincia,elem.idlocalidad);
             SELECT currval('direccion_iddireccion_seq') INTO iddir;
    ELSE
                 UPDATE direccion SET
                  barrio = elem.barrio,calle = elem.calle,
                  nro = elem.nro,tira =elem.tira ,piso =elem.piso ,dpto = elem.dpto,
                  idprovincia =elem.idprovincia ,idlocalidad =elem.idlocalidad
            WHERE iddireccion = elem.iddireccion AND idcentrodireccion= elem.idcentrodireccion;
            iddir= elem.iddireccion;
END IF;
RETURN iddir;
END;

$function$
