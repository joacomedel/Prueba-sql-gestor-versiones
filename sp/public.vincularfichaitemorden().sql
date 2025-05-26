CREATE OR REPLACE FUNCTION public.vincularfichaitemorden()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
--cursores
cursorvalorizada CURSOR FOR
              SELECT *
              FROM ttfichamedicaemisionpendiente;
cursorficha refcursor;

--registros
dato RECORD;
regficha RECORD;

--variables
respuesta boolean;
cantidadpractica INTEGER;

BEGIN

respuesta = true;
   open cursorvalorizada;
   FETCH cursorvalorizada into dato;
   WHILE found LOOP
         cantidadpractica = dato.fmepcantidad;

         --busco dada una ficha medica sus items con la practica q se expendio
         OPEN cursorficha FOR SELECT fichamedicaemision.*
                              FROM fichamedicaitem NATURAL JOIN fichamedicaemision
         WHERE fichamedicaitem.idfichamedica =dato.idfichamedica AND fichamedicaitem.idcentrofichamedica = dato.idcentrofichamedica
         AND fichamedicaemision.idnomenclador=dato.idnomenclador AND fichamedicaemision.idcapitulo = dato.idcapitulo
         AND fichamedicaemision.idsubcapitulo=dato.idsubcapitulo  AND fichamedicaemision.idpractica= dato.idpractica;

         FETCH cursorficha INTO regficha;
         WHILE  found  LOOP
                INSERT INTO fichamedicaitememisiones(idfichamedicaitem,
                                              idcentrofichamedicaitem,
                                              nroorden,
                                              centro)
                VALUES(regficha.idfichamedicaitem,regficha.idcentrofichamedicaitem, dato.nroorden, dato.centro);
                FETCH cursorficha INTO regficha;
         END LOOP;
	     close cursorficha;
   FETCH cursorvalorizada into dato;
	END LOOP;
    close cursorvalorizada;

    return respuesta;	
END;
$function$
