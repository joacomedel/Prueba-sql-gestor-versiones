CREATE OR REPLACE FUNCTION public.conciliacionbancaria_actualizar()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
    rliq RECORD;
    rusuario RECORD;
    cconciliacion CURSOR FOR SELECT * FROM temp_conciliacionbancaria;
    rconciliacion record;
    elidconciliacionbancaria bigint;
    elidcentroconciliacionbancaria integer;
    rconanterior record;
    rsaldofinalanterior double precision;
    cbsaldo_anterior double precision;
    afectasaldo boolean;
BEGIN
rsaldofinalanterior=0;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;

OPEN cconciliacion;
     FETCH cconciliacion INTO rconciliacion;
WHILE found LOOP

          /*si existe una conciliacion para esa cuenta para el mes anterior entonces el saldo inicial de la nueva conciliacion es el saldo final de la conciliacion anterior, casocontrario es el ingresado por el usuario*/
           SELECT INTO rconanterior * 
           FROM conciliacionbancaria 
           WHERE conciliacionbancaria.idcuentabancaria=rconciliacion.idcuentabancaria  
                and cbfechadesdemovimiento=rconciliacion.cbfechadesdemovimiento::date- interval '1 month' 
                
           ORDER BY idconciliacionbancaria desc limit 1;
           
           IF  FOUND THEN
                       --Dani comento el 30092020 como conclusion de la reunion con Tere
                       -- rsaldofinalanterior=rconanterior.cbsaldofinalcb;
                      rsaldofinalanterior=rconanterior.cbsaldofinalbco;
                      cbsaldo_anterior = rconanterior.cbsaldo;
           ELSE  
                       rsaldofinalanterior=rconciliacion.cbsaldoinicialcb;
                       cbsaldo_anterior = rconciliacion.cbsaldo;
  

           END IF;
  
           IF (nullvalue(rconciliacion.idconciliacionbancaria)) THEN  --Inserta
                  if (rconciliacion.cbafectasaldoanterior) then --si toma en cuenta el saldo de la conciliacion anterior
                         --BelenA 26/02/25 agrego cbmontomaximodiferencia
                         INSERT INTO conciliacionbancaria (cbfechadesdemovimiento,cbfechahastamovimiento,cbescripcion,cbsaldo,cbsaldofinalbco,cbsaldofinalcb,cbsaldoinicialcb,idprestador,idcuentabancaria, cbmontomaximodiferencia)
                         VALUES(rconciliacion.cbfechadesdemovimiento,rconciliacion.cbfechahastamovimiento,rconciliacion.cbescripcion
,round(cbsaldo_anterior::numeric,3),round(rconciliacion.cbsaldofinalbco::numeric,3),round(rconciliacion.cbsaldofinalcb::numeric,3),round(rsaldofinalanterior::numeric,3),rconciliacion.idprestador,rconciliacion.idcuentabancaria, round(rconciliacion.cbmontomaximodiferencia::numeric,2));
                         elidconciliacionbancaria = currval('conciliacionbancaria_idconciliacionbancaria_seq');
                         elidcentroconciliacionbancaria = centro();
                         PERFORM conciliacionbancariacambiarestado(elidconciliacionbancaria,elidcentroconciliacionbancaria,1,' Desde SP:conciliacionbancariaactualizar');
                  else  --si NO toma en cuenta el saldo de la conciliacion anterior
                        --BelenA 26/02/25 agrego cbmontomaximodiferencia
                        INSERT INTO conciliacionbancaria (cbfechadesdemovimiento,cbfechahastamovimiento,cbescripcion,cbsaldo,cbsaldofinalbco,cbsaldofinalcb,cbsaldoinicialcb,idprestador,idcuentabancaria, cbmontomaximodiferencia)
                         VALUES(rconciliacion.cbfechadesdemovimiento,rconciliacion.cbfechahastamovimiento,rconciliacion.cbescripcion
,round(rconciliacion.cbsaldo::numeric,3),round(rconciliacion.cbsaldofinalbco::numeric,3),round(rconciliacion.cbsaldofinalcb::numeric,3),round(rconciliacion.cbsaldoinicialcb::numeric,3),rconciliacion.idprestador,rconciliacion.idcuentabancaria, round(rconciliacion.cbmontomaximodiferencia::numeric,2));
                         elidconciliacionbancaria = currval('conciliacionbancaria_idconciliacionbancaria_seq');
                         elidcentroconciliacionbancaria = centro();
                         PERFORM conciliacionbancariacambiarestado(elidconciliacionbancaria,elidcentroconciliacionbancaria,1,' Desde SP:conciliacionbancariaactualizar');

    end if;

            ELSE --Actualiza
                         elidconciliacionbancaria  = rconciliacion.idconciliacionbancaria;
                         elidcentroconciliacionbancaria   = rconciliacion.idcentroconciliacionbancaria;

             afectasaldo= rconciliacion.cbafectasaldoanterior;
       
           if (afectasaldo) then --si debe tener en cuenta el saldo final de la conciliacion anterior como saldo inicial
                         UPDATE conciliacionbancaria
                         SET    cbfechadesdemovimiento = rconciliacion.cbfechadesdemovimiento,
                                cbfechahastamovimiento = rconciliacion.cbfechahastamovimiento,
                                idcuentabancaria = rconciliacion.idcuentabancaria,
                                cbescripcion = rconciliacion.cbescripcion,
                                cbsaldo = round(rconciliacion.cbsaldo::numeric,2),
                                cbsaldofinalbco = round(rconciliacion.cbsaldofinalbco::numeric,2),
                                cbsaldofinalcb = round(rconciliacion.cbsaldofinalcb::numeric,2),
                                cbsaldoinicialcb = round(rsaldofinalanterior::numeric,2),
                                idprestador = rconciliacion.idprestador,
                                --BelenA 26/02/25 agrego cbmontomaximodiferencia
                                cbmontomaximodiferencia = round(rconciliacion.cbmontomaximodiferencia::numeric,2)
                        WHERE idconciliacionbancaria = rconciliacion.idconciliacionbancaria
                               AND idcentroconciliacionbancaria = rconciliacion.idcentroconciliacionbancaria;
          
                        RAISE NOTICE 'UPDATE';
            else --si NO debe tener en cuenta el saldo final de la conciliacion anterior como saldo inicial
                   UPDATE conciliacionbancaria
                         SET    cbfechadesdemovimiento = rconciliacion.cbfechadesdemovimiento,
                                cbfechahastamovimiento = rconciliacion.cbfechahastamovimiento,
                                idcuentabancaria = rconciliacion.idcuentabancaria,
                                cbescripcion = rconciliacion.cbescripcion,
                                cbsaldo = round(rconciliacion.cbsaldo::numeric,2),
                                cbsaldofinalbco = round(rconciliacion.cbsaldofinalbco::numeric,2),
                                cbsaldofinalcb = round(rconciliacion.cbsaldofinalcb::numeric,2),
                               -- para que desprecie el saldo final de la conciliacion anterior y tenga en cuenta el dato de la ventana
                                cbsaldoinicialcb = round(rconciliacion.cbsaldoinicialcb::numeric,2),
                                idprestador = rconciliacion.idprestador,
                                --BelenA 26/02/25 agrego cbmontomaximodiferencia
                                cbmontomaximodiferencia = round(rconciliacion.cbmontomaximodiferencia::numeric,2)
                        WHERE idconciliacionbancaria = rconciliacion.idconciliacionbancaria
                               AND idcentroconciliacionbancaria = rconciliacion.idcentroconciliacionbancaria;
          
        END IF;
         END IF;
     FETCH cconciliacion INTO rconciliacion;
     END LOOP;
     CLOSE cconciliacion;
     RETURN concat(elidconciliacionbancaria,'|',elidcentroconciliacionbancaria);

return true;
END;$function$
