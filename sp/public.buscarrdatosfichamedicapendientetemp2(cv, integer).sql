CREATE OR REPLACE FUNCTION public.buscarrdatosfichamedicapendientetemp2(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
--cursores
cursorficha refcursor;
cursorfichaitem refcursor;

--registros
dato RECORD;
regficha RECORD;

--variables
respuesta boolean;
cantidadpractica INTEGER;
cantemitir INTEGER;

BEGIN
CREATE TEMP TABLE ttfichamedicaemisionpendiente (
                  fmepfecha DATE,
                  descripprestador VARCHAR,
				  nrodoc VARCHAR NOT NULL,
				  tipodoc INTEGER NOT NULL,
				  cantresta INTEGER,
				  idnomenclador VARCHAR,
				  ndescripcion VARCHAR,
				  idcapitulo VARCHAR,
				  cdescripcion VARCHAR,
				  idsubcapitulo VARCHAR,
				  scdescripcion VARCHAR,
				  idpractica VARCHAR,
				  pdescripcion VARCHAR,
				  idfichamedica INTEGER,
				  idcentrofichamedica INTEGER
				 
				) WITHOUT OIDS;
				
respuesta = true;
  --busco dada una ficha medica sus items con la practica q se expendio
OPEN cursorficha FOR SELECT fichamedicaitem.idfichamedica,fichamedicaitem.idcentrofichamedica,nrodoc, tipodoc,
              min(fichamedicaemision.fmepfecha) as fmepfecha,idauditoriatipo,	t.idnomenclador, nomenclador.ndescripcion,
              t.idcapitulo,capitulo.cdescripcion,t.idsubcapitulo,subcapitulo.scdescripcion	,	t.idpractica,practica.pdescripcion,	
              prestador.pdescripcion as descripprestador,t.cantidad, (t.cantidad - cantemitida) as cantresta 	
              FROM fichamedicaitem	
              NATURAL JOIN (SELECT *
                           --Tomo las auditorias y las emisiones pendientes solo de este año,puesto que la auditoria psicoterapia inicia de cero cada nuevo año
                           FROM fichamedicaemision
                           WHERE extract('years' from fichamedicaemision.fmepfecha) = extract('years' from current_date)
                           AND fichamedicaemision.nrodoc = $1 AND fichamedicaemision.tipodoc= $2
                            ) as fichamedicaemision

              NATURAL JOIN
              (SELECT sum(fichamedicaitem.fmicantidad) as cantidad,fichamedicaitem.idnomenclador,fichamedicaitem.idcapitulo, 	
                            fichamedicaitem.idsubcapitulo,fichamedicaitem.idpractica,fichamedicaitem.idfichamedica,fichamedicaitem.idcentrofichamedica
                            FROM fichamedicaitem
                            NATURAL JOIN fichamedica
                            WHERE fichamedica.nrodoc=  $1 AND fichamedica.tipodoc = $2
                            --Tomo las auditorias solo de este año,puesto que la auditoria psicoterapia inicia de cero cada nuevo año
                            AND extract('years' from fichamedicaitem.fmifechaauditoria) = extract('years' from current_date)
                            --Le saco estarestriccion (directamente borro la tabla de la consulta)
                            -- del estado pues cuando busco en el consumo, no estoy teniendo en cuenta las practicas ya emitidas	
                            GROUP BY fichamedicaitem.idnomenclador,fichamedicaitem.idcapitulo,
                            fichamedicaitem.idsubcapitulo,fichamedicaitem.idpractica,fichamedicaitem.idfichamedica,fichamedicaitem.idcentrofichamedica 
              ) as t 	
              NATURAL JOIN fichamedicaemisionestado 
              LEFT JOIN prestador USING(idprestador)
              LEFT JOIN (select sum(t.cantemitida) as cantemitida,t.idnomenclador,
                        t.idcapitulo, t.idsubcapitulo,t.idpractica,t.idfichamedica,
                        t.idcentrofichamedica
                        from
                        (SELECT item.cantidad as cantemitida,fichamedicaitem.idnomenclador,
                        fichamedicaitem.idcapitulo, fichamedicaitem.idsubcapitulo,fichamedicaitem.idpractica,fichamedicaitem.idfichamedica,
                        fichamedicaitem.idcentrofichamedica 	
                        FROM fichamedicaitem 
                        NATURAL JOIN fichamedica
                        --NATURAL JOIN fichamedicaitememisiones 
                        NATURAL JOIN orden
                        NATURAL JOIN consumo
                        NATURAL JOIN itemvalorizada 
                        NATURAL JOIN item 
                        LEFT JOIN ordenestados USING(nroorden,centro) 
                        WHERE nullvalue(ordenestados.nroorden)
                        AND nullvalue(ordenestados.centro) 
                         -- Tomo el consumo solo del años en el que estamos, puesto que la auditoria psicoterapia inicia de cero cada nuevo año
                          -- Tomo el consumo solo del años en el que estamos, puesto que la auditoria psicoterapia inicia de cero cada nuevo año
                        AND extract('years' from orden.fechaemision) = extract('years' from current_date)
                        AND extract('years' from fichamedicaitem.fmifechaauditoria) = extract('years' from current_date)
                        AND consumo.nrodoc= $1 AND consumo.tipodoc=$2
                        GROUP BY item.iditem,
                        fichamedicaitem.idnomenclador,fichamedicaitem.idcapitulo, fichamedicaitem.idsubcapitulo,fichamedicaitem.idpractica,
                        fichamedicaitem.idfichamedica,fichamedicaitem.idcentrofichamedica,cantemitida
                        ) as t
             GROUP BY
                        t.idnomenclador,
                        t.idcapitulo, t.idsubcapitulo,t.idpractica,t.idfichamedica,
                        t.idcentrofichamedica
             ) as ttabla 	USING(idfichamedica,idcentrofichamedica,idnomenclador,
                        idcapitulo, idsubcapitulo, idpractica) NATURAL JOIN nomenclador NATURAL JOIN capitulo NATURAL JOIN subcapitulo  JOIN practica 	
                        USING(idnomenclador, idcapitulo, idsubcapitulo, idpractica) 	WHERE fichamedicaemision.nrodoc = $1 AND fichamedicaemision.tipodoc =$2	
                        AND (fichamedicaemision.idauditoriatipo = 2 OR fichamedicaemision.idauditoriatipo = 4) AND 	
                        fichamedicaemisionestado.idfichamedicaemisionestadotipo=1 
                        --AND nullvalue(fichamedicaemisionestado.fmeefechafin) 	
                        GROUP BY fichamedicaitem.idfichamedica,fichamedicaitem.idcentrofichamedica,nrodoc, tipodoc, idauditoriatipo, t.idnomenclador,
                        nomenclador.ndescripcion, t.idcapitulo,capitulo.cdescripcion, 	t.idsubcapitulo,subcapitulo.scdescripcion	,	t.idpractica,
                        practica.pdescripcion, descripprestador,cantidad, cantresta;


FETCH cursorficha INTO regficha;
WHILE  found  LOOP

                IF (regficha.cantresta <= 0) THEN
                   BEGIN
                     OPEN cursorfichaitem FOR SELECT *
                                     FROM fichamedicaitem
                                     WHERE idnomenclador= regficha.idnomenclador AND idcapitulo=regficha.idcapitulo  AND idsubcapitulo=regficha.idsubcapitulo AND
                                     idpractica= regficha.idpractica AND fichamedicaitem.idfichamedica= regficha.idfichamedica AND fichamedicaitem.idcentrofichamedica=regficha.idcentrofichamedica;
                     FETCH cursorfichaitem INTO dato;
                     WHILE  found  LOOP
                       SELECT INTO respuesta * FROM cambiarestadofichamedica
                       (dato.idfichamedicaitem, dato.idcentrofichamedicaitem ,2,'CAMBIO DE ESTADO DESDE EL SP actualizarDatosFichaMedicaPendiente');								
                       FETCH cursorfichaitem INTO dato;
                     END LOOP;
                     close cursorfichaitem;
                   END;
                ELSE
                    BEGIN
                     IF (nullvalue(regficha.cantresta)) THEN
                        cantemitir =regficha.cantidad;
                     ELSE
                        cantemitir =regficha.cantresta;
                     END IF;
                     INSERT INTO ttfichamedicaemisionpendiente VALUES(
                     regficha.fmepfecha,
                     regficha.descripprestador,
                     regficha.nrodoc,
                     regficha.tipodoc,
                     cantemitir ,
                     regficha.idnomenclador,
                     regficha.ndescripcion,
                     regficha.idcapitulo,
                     regficha.cdescripcion,
                     regficha.idsubcapitulo,
                     regficha.scdescripcion,
                     regficha.idpractica,
                     regficha.pdescripcion,
                     regficha.idfichamedica,
                     regficha.idcentrofichamedica);
            END;
                END IF;
    FETCH cursorficha INTO regficha;
END LOOP;
close cursorficha;
return respuesta;	
END;
$function$
