CREATE OR REPLACE FUNCTION public.actualizardatosfichamedicapendiente()
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
         WHILE  found  AND (cantidadpractica > 0 ) LOOP

                IF (regficha.fmepcantidad >  cantidadpractica) THEN
                    UPDATE fichamedicaemision set  fmepcantidad= (regficha.fmepcantidad - cantidadpractica)
	                WHERE fichamedicaemision.idfichamedicaitem= regficha.idfichamedicaitem AND fichamedicaemision.idcentrofichamedicaitem= regficha.idcentrofichamedicaitem;
                  --  AND (fichamedicaemision.idauditoriatipo=2 or fichamedicaemision.idauditoriatipo=4);
                ELSE
                    BEGIN
                      UPDATE fichamedicaemision set  fmepcantidad= 0
                      WHERE fichamedicaemision.idfichamedicaitem= regficha.idfichamedicaitem AND fichamedicaemision.idcentrofichamedicaitem= regficha.idcentrofichamedicaitem;
                     -- AND (fichamedicaemision.idauditoriatipo=2 or fichamedicaemision.idauditoriatipo=4);
                     SELECT INTO respuesta * FROM cambiarestadofichamedica (regficha.idfichamedicaitem, regficha.idcentrofichamedicaitem ,2,'CAMBIO DE ESTADO DESDE EL SP actualizarDatosFichaMedicaPendiente');								
                    END;
                END IF;
                cantidadpractica = cantidadpractica - regficha.fmepcantidad;
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
