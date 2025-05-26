CREATE OR REPLACE FUNCTION ca.reportehorastrabajadas(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros record;
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

     /*

SELECT ca.reportehorastrabajadas('{idpersona=3 ,amfechadesde=2018-08-01, amfechahasta=2018-08-30}');
SELECT * FROM temptablasalida
*/
--- SET search_path =  pg_catalog;
   SET search_path = ca, public, pg_catalog;
     EXECUTE public.sys_dar_filtros($1) INTO rfiltros;
     IF ( iftableexists('temptablasalida') ) THEN DELETE FROM temptablasalida; 
     ELSE 
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
            horafinjornada INTERVAL,
            idlicencia INTEGER,
            lifechafin DATE,
            ltdescripcion VARCHAR,
            idferiado integer,
            fedescripcion VARCHAR, 
            lheiomisionfichadoingreso BIGINT,
            lheiomisionfichadoegreso BIGINT, 
            cantsaydo_enlic INTEGER,
            jhdia INTEGER
     );

     END IF;
     IF ( iftableexists('tempmovimientos') ) THEN 
		DELETE FROM  tempmovimientos; 
     ELSE
             CREATE TEMP TABLE tempmovimientos (   idpersona INTEGER  NOT NULL,  amfecha DATE  NOT NULL,  amhora TIMESTAMP NOT NULL,  idmovimientotipos INTEGER NULL,  idmovimiento INTEGER NULL,  iddia INTEGER  NULL, idreloj BIGINT);
     END IF;
     IF ( iftableexists('temhorastrabajadas') ) THEN 
	DELETE FROM  temhorastrabajadas;
     ELSE
         /* temporal que almacena movimientos (entrada salida) en un unico registro*/
          CREATE TEMP TABLE temhorastrabajadas (  idmovimiento INTEGER,   idpersona INTEGER, mfecha DATE,idia INTEGER, horaentrada TIMESTAMP WITH TIME ZONE, horasalida TIMESTAMP WITH TIME ZONE, idmovimientotipos INTEGER,canthoras TIMESTAMP WITH TIME ZONE, idreloj BIGINT);
     END IF;    
     IF ( iftableexists('tempmovimientossinpar') ) THEN 
	DELETE FROM  tempmovimientossinpar;
     ELSE
         /* temporal que almacena movimientos (entrada salida) en un unico registro*/
          CREATE TEMP TABLE tempmovimientossinpar (  idmovimiento INTEGER,   idpersona INTEGER, mfecha DATE,idia INTEGER, horaentrada TIMESTAMP WITH TIME ZONE, horasalida TIMESTAMP WITH TIME ZONE, idmovimientotipos INTEGER,canthoras TIMESTAMP WITH TIME ZONE, idreloj BIGINT);
     END IF; 
     /* Obtengo los movimientos de o los empleados */
    INSERT INTO tempmovimientos (idpersona,amfecha,amhora,idmovimientotipos,idmovimiento,iddia,idreloj)
    SELECT m.idpersona,amfecha, to_timestamp(to_char(amhora,'HH24:MI:SS'),'HH24:MI:SS') as amhora,am.idmovimientotipo ,am.idmovimiento ,date_part('dow',amfecha::date)+1 as iddia,am.idreloj
    FROM movimientos m
    NATURAL JOIN auditoriamovimiento am
    JOIN reloj r ON am.idreloj=r.idreloj
    JOIN movimientotipo mt ON am.idmovimientotipo =  mt.idmovimientotipo
    NATURAL JOIN persona
    WHERE TRUE  
          AND ( idpersona = rfiltros.idpersona or rfiltros.idpersona = 0 )
          AND amfecha  >= rfiltros.amfechadesde
          AND amfecha  <= rfiltros.amfechahasta
          AND nullvalue(amfechamodificacionfin)
    ORDER BY idpersona,amfecha,amhora,idmovimientotipos;






     idtipomovant = 2;  -- se inicia con el tipo de movimiento salida

    OPEN cursormovimiento FOR SELECT * FROM tempmovimientos;
    FETCH cursormovimiento INTO unmovimiento;
    WHILE FOUND LOOP -- Recorro cada uno de los movimiento dependiento su clasificacion (I/O) se llena la tabla temporal
          IF(unmovimiento.idmovimientotipos = 1) THEN -- se trata de un movimiento de entrada
                  IF(idtipomovant = 2)then -- movimiento anterior = salida
                           INSERT INTO temhorastrabajadas (   idmovimiento, idpersona , mfecha,idia, horaentrada, horasalida,idmovimientotipos,canthoras,idreloj)
                                  VALUES( unmovimiento.idmovimiento,unmovimiento.idpersona ,unmovimiento.amfecha, unmovimiento.iddia,unmovimiento.amhora,null, unmovimiento.idmovimientotipos,null,unmovimiento.idreloj);

                           diamovanterior = unmovimiento.amfecha;
                           idmovanterior = unmovimiento.idmovimiento;
                   ELSE -- movimiento anterior = entrada
			   INSERT INTO tempmovimientossinpar ( SELECT * FROM temhorastrabajadas WHERE idmovimiento = idmovanterior );
                           DELETE FROM temhorastrabajadas WHERE idmovimiento = idmovanterior;
			   INSERT INTO temhorastrabajadas (idmovimiento, idpersona ,mfecha,idia, horaentrada, horasalida,idmovimientotipos,canthoras)
                                  VALUES( unmovimiento.idmovimiento,unmovimiento.idpersona ,unmovimiento.amfecha, unmovimiento.iddia,unmovimiento.amhora,null, unmovimiento.idmovimientotipos,null);

                           diamovanterior = unmovimiento.amfecha;
                           idmovanterior = unmovimiento.idmovimiento;

                   
RAISE NOTICE 'horaentrada (%)',to_char(unmovimiento.amhora,'HH24:MI:SS')::interval ;
                   END IF;
                   idtipomovant = 1;

           ELSE  -- se trata de un movimiento de salida
                   IF(idtipomovant = 1)then -- movimiento anterior = I
                                  if(unmovimiento.amfecha = diamovanterior )then
                                            UPDATE temhorastrabajadas
                                            SET horasalida = unmovimiento.amhora , canthoras = to_timestamp(to_char(unmovimiento.amhora  - horaentrada,'HH24:MI:SS'),'HH24:MI:SS')
                                            WHERE idmovimiento = idmovanterior and unmovimiento.amfecha=diamovanterior;
                                  ELSE
					INSERT INTO tempmovimientossinpar (
						SELECT * FROM temhorastrabajadas WHERE idmovimiento = idmovanterior
						);
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
                 ELSE '00:00:00' END ::interval ) as canthtrab,peapellido,penombre,
                 SUM(CASE WHEN (idmovimientotipos =1 AND idreloj = 5) THEN 1 ELSE 0 END) AS omisionfichadaingreso,
                 SUM(CASE WHEN (idmovimientotipos =2 AND idreloj = 5) THEN 1 ELSE 0 END) AS omisionfichadaegreso
             FROM temhorastrabajadas
             NATURAL JOIN persona
             group by idpersona,peapellido,penombre,mfecha,idia,horasalida,horaentrada;

             FETCH cursortempmov INTO unmovtemp;
             WHILE FOUND LOOP
                 -- LLENAR Las horas que le corresponden trabajar enesa jornada

                 SELECT INTO jornadapersona  idpersona,   jhdia
                   ,jhhorainicio as iniciojornada,
                    jhhorafin as finjornada
                    ,(jhhorafin - jhhorainicio) as canthorasjornada
                    ,penombre, peapellido
                  FROM persona 
                  LEFT JOIN jornada USING(idpersona)
                  LEFT JOIN jornadahorario USING (idjornada)
                 -- RIGHT JOIN persona USING(idpersona)
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
                    INSERT INTO temptablasalida(idpersona,apellido,nombres,fecha,canthorastrabajadas,canthorajornada,canthorasextras,hrextrassosunc,horaentrada,horaalida,horainiciojornada,horafinjornada, lheiomisionfichadoingreso,lheiomisionfichadoegreso,jhdia )
                    VALUES(unmovtemp.idpersona,unmovtemp.peapellido,unmovtemp.penombre,unmovtemp.mfecha,to_timestamp(unmovtemp.canthtrab::text,'HH24:MI:SS'::text),
                                     to_timestamp(jornadapersona.canthorasjornada::text,'HH24:MI:SS'::text),
                                     to_char(unmovtemp.canthtrab,'HH24:MI:SS'::text)::interval - to_char(jornadapersona.canthorasjornada,'HH24:MI:SS'::text)::interval,
                                     hrsextrasosunc,to_char(unmovtemp.horaentrada,'HH24:MI:SS'::text)::interval, to_char(unmovtemp.horasalida,'HH24:MI:SS'::text)::interval,
                                     to_char(jornadapersona.iniciojornada,'HH24:MI:SS'::text)::interval,to_char(jornadapersona.finjornada,'HH24:MI:SS'::text)::interval
                    ,unmovtemp.omisionfichadaingreso,unmovtemp.omisionfichadaegreso,jornadapersona.jhdia);
     FETCH cursortempmov INTO unmovtemp;
     END LOOP;
     

-- KR 27-08-19 resto de los dias aquellos que el empleado no trabaja segun su jornada. Ej. empleados de farmacia trabajan sabado, por ende no hay que descontarlo. Corresponde trabajar.
     INSERT INTO temptablasalida(idpersona,apellido,nombres,fecha, idlicencia,lifechafin,ltdescripcion, cantsaydo_enlic) (
                  SELECT idpersona,peapellido,penombre,lifechainicio,idlicencia,lifechafin,ltdescripcion

                  ,CASE WHEN ltdiascorridos AND (jhdia <>1 OR nullvalue(jhdia)) THEN restartipodiasafechas(concat('fechadesde=',lifechainicio,',fechahasta=',(CASE WHEN lifechafin > rfiltros.amfechahasta THEN rfiltros.amfechahasta ELSE lifechafin END),',tipodia=domingo')) ELSE 0 END
                   +
                   CASE WHEN ltdiascorridos AND (jhdia <>7  OR nullvalue(jhdia)) THEN restartipodiasafechas(concat('fechadesde=',lifechainicio,',fechahasta=',(CASE WHEN lifechafin > rfiltros.amfechahasta THEN rfiltros.amfechahasta ELSE lifechafin END),',tipodia=sabado')) ELSE 0 END

                  FROM licencia
                  NATURAL JOIN licenciatipo
                  NATURAL JOIN persona 
                  LEFT JOIN  (SELECT jhdia, idpersona FROM ca.jornada    JOIN ca.jornadahorario USING (idjornada) 
				WHERE jorfechainicio <= rfiltros.amfechadesde and jorfechafin >=rfiltros.amfechahasta AND (jhdia = 7 OR jhdia = 1)) AS jornadaempleado
		  USING (idpersona) 
                  WHERE -- ltpordia and
                         lifechainicio   >=  rfiltros.amfechadesde
                        and lifechainicio   <=rfiltros.amfechahasta
                        and ( idpersona = rfiltros.idpersona or rfiltros.idpersona = 0 )
                  );
                  
     INSERT INTO temptablasalida (idpersona,apellido,nombres,fecha,  idferiado , fedescripcion )(
            SELECT idpersona,apellido,nombres, fefecha, idferiado , fedescripcion
            FROM feriado
            JOIN feriadocentro using (idferiado)
            CROSS JOIN (SELECT DISTINCT idpersona,apellido,nombres,  CASE WHEN (idgrupoliquidaciontipo = 2 ) THEN 99 ELSE 1 END as idcentroregional
                        FROM temptablasalida
                        JOIN ca.grupoliquidacionempleado using (idpersona)
                        
                        )as t
            WHERE fefecha >=  rfiltros.amfechadesde
                  AND fefecha <= rfiltros.amfechahasta
                  AND  feriadocentro.idcentroregional = t.idcentroregional
     );

          
          
return 	true;
END;
$function$
