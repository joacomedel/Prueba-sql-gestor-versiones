CREATE OR REPLACE FUNCTION ca.reportehorastrabajadas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       cursormovimiento  refcursor;
       unmovimiento record;
       idmovanterior integer;
       idtipomovant integer;
       cursortempmov refcursor;
       unmovtemp record;
       jornadapersona record;
       hora time;
       diamovanterior date;
       hrsextrasosunc interval;
       diferencia interval;


BEGIN
     SET search_path = ca, pg_catalog;
     /* Obtengo los movimientos de o los empleados */

     CREATE TEMP TABLE temptablasalida ( idpersona INTEGER,
            fecha  DATE,
            canthorastrabajadas TIMESTAMP(0) WITH TIME ZONE,
            canthorajornada TIMESTAMP(0) WITH TIME ZONE,
            apellido VARCHAR,
            nombres VARCHAR,
            canthorasextras INTERVAL,
            hrextrassosunc INTERVAL,
            horaentrada INTERVAL,
            horaalida INTERVAL,
            horainiciojornada INTERVAL,
            horafinjornada INTERVAL
     );


    CREATE TEMP TABLE tempmovimientos (   idpersona INTEGER  NOT NULL,  amfecha DATE  NOT NULL,  amhora TIMESTAMP NOT NULL,  idmovimientotipos INTEGER NULL,  idmovimiento INTEGER NULL,  iddia INTEGER  NULL); 

INSERT INTO tempmovimientos (idpersona,amfecha,amhora,idmovimientotipos,idmovimiento,iddia) 
SELECT m.idpersona,amfecha, to_timestamp(to_char(amhora,'HH24:MI:SS'),'HH24:MI:SS') as amhora,m.idmovimientotipos ,m.idmovimiento ,date_part('dow',amfecha::date)+1 as iddia  
FROM movimientos m   
NATURAL JOIN auditoriamovimiento am
JOIN reloj r ON am.idreloj=r.idreloj    
JOIN movimientotipo mt ON am.idmovimientotipo =  mt.idmovimientotipo       
NATURAL JOIN persona 
WHERE TRUE  AND idpersona = '3' AND amfecha  >= '2018/08/01'  AND amfecha   <= '2018/09/14' 
ORDER BY idpersona,amfecha,amhora,idmovimientotipos;






     idtipomovant = 2;  -- se inicia con el tipo de movimiento salida

     /* temporal que almacena movimientos (entrada salida) en un unico registro*/
    CREATE TEMP TABLE temhorastrabajadas (  idmovimiento INTEGER,   idpersona INTEGER, mfecha DATE,idia INTEGER, horaentrada TIMESTAMP WITH TIME ZONE, horasalida TIMESTAMP WITH TIME ZONE, idmovimientotipos INTEGER,canthoras TIMESTAMP WITH TIME ZONE);

    OPEN cursormovimiento FOR SELECT * FROM tempmovimientos;
    FETCH cursormovimiento INTO unmovimiento;
    WHILE FOUND LOOP -- Recorro cada uno de los movimiento dependiento su clasificacion (I/O) se llena la tabla temporal

          IF(unmovimiento.idmovimientotipos = 1) THEN -- se trata de un movimiento de entrada
                  IF(idtipomovant = 2)then -- movimiento anterior = salida
                           INSERT INTO temhorastrabajadas (   idmovimiento, idpersona , mfecha,idia, horaentrada, horasalida,idmovimientotipos,canthoras)
                                  VALUES( unmovimiento.idmovimiento,unmovimiento.idpersona ,unmovimiento.amfecha, unmovimiento.iddia,unmovimiento.amhora,null, unmovimiento.idmovimientotipos,null);

                           diamovanterior = unmovimiento.amfecha;
                           idmovanterior = unmovimiento.idmovimiento;
                   ELSE -- movimiento anterior = entrada
                           DELETE FROM temhorastrabajadas WHERE idmovimiento = idmovanterior;
                           INSERT INTO temhorastrabajadas (   idmovimiento, idpersona ,mfecha,idia, horaentrada, horasalida,idmovimientotipos,canthoras)
                                  VALUES( unmovimiento.idmovimiento,unmovimiento.idpersona ,unmovimiento.amfecha, unmovimiento.iddia,unmovimiento.amhora,null, unmovimiento.idmovimientotipos,null);

                           diamovanterior = unmovimiento.amfecha;
                           idmovanterior = unmovimiento.idmovimiento;
                   END IF;
                   idtipomovant = 1;

           ELSE  -- se trata de un movimiento de salida
                   IF(idtipomovant = 1)then -- movimiento anterior = I
                                  if(unmovimiento.amfecha = diamovanterior )then
                                            UPDATE temhorastrabajadas
                                            SET horasalida = unmovimiento.amhora , canthoras = to_timestamp(to_char(unmovimiento.amhora  - horaentrada,'HH24:MI:SS'),'HH24:MI:SS')
                                            WHERE idmovimiento = idmovanterior and unmovimiento.amfecha=diamovanterior;
                                  ELSE
                                      DELETE FROM temhorastrabajadas WHERE idmovimiento = idmovanterior;
                                  END IF;
                   END IF;    -- si el movimiento anterior = O no hay nada para hacer
                   idtipomovant = 2;
           END IF;

     FETCH cursormovimiento INTO unmovimiento;
     END LOOP;


     CLOSE cursormovimiento;


/* tengo que volver a comentar */
  --CREATE TABLE tablasalida;
      OPEN cursortempmov FOR
            SELECT idpersona,mfecha, idia ,horasalida,horaentrada,
                 SUM(CASE WHEN not nullvalue(canthoras) THEN
                          concat(lpad(extract(hour from canthoras),2,'0'),':',
                                 lpad(extract(minute from canthoras),2,'0'),':',
                                 lpad(extract(second from canthoras),2,'0')
                          )
                 ELSE '00:00:00' END ::interval ) as canthtrab
             FROM temhorastrabajadas
             group by idpersona,mfecha,idia,horasalida,horaentrada;

             FETCH cursortempmov INTO unmovtemp;
             WHILE FOUND LOOP
                 -- LLENAR Las horas que le corresponden trabajar enesa jornada

                 SELECT INTO jornadapersona  idpersona,   jhdia
                   ,jhhorainicio as iniciojornada,
                    jhhorafin as finjornada
                    ,(jhhorafin - jhhorainicio) as canthorasjornada
                    ,penombre, peapellido
                  FROM jornada
                  NATURAL JOIN jornadahorario
                  RIGHT JOIN persona USING(idpersona)
                  WHERE persona.idpersona=unmovtemp.idpersona
                        and jorfechainicio <= unmovtemp.mfecha and jorfechafin >= unmovtemp.mfecha
                        and jhdia=unmovtemp.idia;
                    /*
                    * El calculo de la hora extra en sosunc se reza de la siguiente manera.
                    * Si la persona llega antes del inicio de jornada es irrelevante
                    * Si la persona llega despues del inicio de jornada hay que restar a las horas extras el tiempo que llego tarde
                    */

                    IF(to_char(unmovtemp.horaentrada,'HH24:MI:SS')::interval > to_char(jornadapersona.iniciojornada,'HH24:MI:SS')::interval)
                    THEN
                           diferencia =   to_char(unmovtemp.horaentrada,'HH24:MI:SS')::interval - to_char(jornadapersona.iniciojornada,'HH24:MI:SS')::interval;
                           hrsextrasosunc = (to_char(unmovtemp.horasalida,'HH24:MI:SS')::interval - to_char(jornadapersona.finjornada,'HH24:MI:SS')::interval )
                                            - diferencia;
                         --     hrsextrasosunc =              diferencia;
                    ELSE
                                            hrsextrasosunc = (to_char(unmovtemp.horasalida,'HH24:MI:SS')::interval - to_char(jornadapersona.finjornada,'HH24:MI:SS')::interval );
                    END IF;
                    INSERT INTO temptablasalida(idpersona,apellido,nombres,fecha,canthorastrabajadas,canthorajornada,canthorasextras,hrextrassosunc,horaentrada,horaalida,horainiciojornada,horafinjornada)
                    VALUES(unmovtemp.idpersona,jornadapersona.peapellido,jornadapersona.penombre,unmovtemp.mfecha,to_timestamp(unmovtemp.canthtrab::text,'HH24:MI:SS'::text),
                                     to_timestamp(jornadapersona.canthorasjornada::text,'HH24:MI:SS'::text),
                                     to_char(unmovtemp.canthtrab,'HH24:MI:SS'::text)::interval - to_char(jornadapersona.canthorasjornada,'HH24:MI:SS'::text)::interval,
                                     hrsextrasosunc,to_char(unmovtemp.horaentrada,'HH24:MI:SS'::text)::interval, to_char(unmovtemp.horasalida,'HH24:MI:SS'::text)::interval,
                                     to_char(jornadapersona.iniciojornada,'HH24:MI:SS'::text)::interval,to_char(jornadapersona.finjornada,'HH24:MI:SS'::text)::interval
                    );
     FETCH cursortempmov INTO unmovtemp;
     END LOOP;

return 	true;
END;
$function$
