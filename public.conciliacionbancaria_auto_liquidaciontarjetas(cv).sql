CREATE OR REPLACE FUNCTION public.conciliacionbancaria_auto_liquidaciontarjetas(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rusuario RECORD;

    cliquidaciontarjeta refcursor;
    rliquidaciontarjeta record;
    cmovsiges CURSOR FOR SELECT * FROM  temp_movsiges; -- temporal con los movimientos de siges que se desean conciliar
    clavecomp varchar;

    rmovsiges record;
    rmovimientobanco  record;
    rparam record;
    elidconitem bigint;
    losparam  varchar;
    cant integer;
cantFila integer;
    monto  double precision;
    cantprocesados integer;
    cantliqt integer;

BEGIN

     cantprocesados = 0;
     EXECUTE sys_dar_filtros($1) INTO rparam;
     --{manual=false, idcentroconciliacionbancaria=1, idconciliacionbancaria=10}
     -- SELECT INTO rparam false as manual, 1 as  idcentroconciliacionbancaria , 10 as idconciliacionbancaria;
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;
     cant = 0;

     /*obtengo los grupos de SIGES que tienen el mismo idoperacion */
     IF (not iftableexistsparasp('temp_movsiges_aux') ) THEN 
         CREATE TEMP TABLE temp_movsiges_aux AS SELECT * FROM temp_movsiges; -- resguardo la tabla con los movimientos de SIGES
     END IF;
     IF (not iftableexistsparasp('temp_bancamovimiento_aux') ) THEN 
         CREATE TEMP TABLE temp_bancamovimiento_aux AS SELECT * FROM temp_bancamovimiento; -- resguardo la tabla con los movimientos del banco
     END IF;


     IF rparam.idbanco!=41 THEN

--
         OPEN cliquidaciontarjeta FOR SELECT trim(replace(split_part(ltobservacion,'-',1),'Comercio ','')) as elcomercio,idliquidaciontarjeta,idcentroliquidaciontarjeta, ltfechapago ,ltimporteliquidaciontarjeta
         FROM (
                SELECT split_part(split_part(temp_movsiges_aux.clavecomp, '|',1),'=',2)::bigint as idliquidaciontarjeta , split_part( split_part(temp_movsiges_aux.clavecomp, '|',2) ,'=',2)::integer  as idcentroliquidaciontarjeta
                FROM temp_movsiges_aux
                WHERE tablacomp='liquidaciontarjeta'
         )as T
         NATURAL JOIN liquidaciontarjeta
         GROUP BY trim(replace(split_part(ltobservacion,'-',1),'Comercio ','')),idliquidaciontarjeta,idcentroliquidaciontarjeta,ltfechapago ,ltimporteliquidaciontarjeta;

         FETCH cliquidaciontarjeta INTO rliquidaciontarjeta;
         WHILE FOUND LOOP
               --- Repetir por cada idbancaoperacion encontrada
               DELETE FROM temp_movsiges ;
               INSERT INTO temp_movsiges (elcomprobante	,tablacomp	,clavecomp	,fechacompr	,monto	,impconc)  (
                   SELECT T.elcomprobante	,T.tablacomp	,T.clavecomp	,T.fechacompr	,T.monto	,T.impconc
                   FROM (
                         SELECT split_part(split_part(temp_movsiges_aux.clavecomp, '|',1),'=',2)::bigint as idliquidaciontarjeta , split_part( split_part(temp_movsiges_aux.clavecomp, '|',2) ,'=',2)::integer  as idcentroliquidaciontarjeta,*
                         FROM temp_movsiges_aux
                         WHERE tablacomp='liquidaciontarjeta'
                   )as T
                   NATURAL JOIN liquidaciontarjeta
                   WHERE  idcentroliquidaciontarjeta = rliquidaciontarjeta.idcentroliquidaciontarjeta
                          AND idliquidaciontarjeta = rliquidaciontarjeta.idliquidaciontarjeta
               );

              --- Repetir por cada idbancaoperacion encontrada
              --- Buscar movimientos del banco en la misma fecha y el mismo comercio
            
              DELETE FROM temp_bancamovimiento;
              INSERT INTO temp_bancamovimiento (bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito )(
                     SELECT bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito
                     FROM temp_bancamovimiento_aux
                     WHERE bmfecha  = rliquidaciontarjeta.ltfechapago
                       -- Dani comento el 05082020 porque no coincidian los formatos de los string a comparar 
                       -- AND  bmconcepto ilike concat('%',rliquidaciontarjeta.elcomercio ,'%' )
            AND  split_part(bmconcepto,'-',2) ilike concat('%',split_part(rliquidaciontarjeta.elcomercio,' ',1) ,'%' )
                           AND  abs (rliquidaciontarjeta.ltimporteliquidaciontarjeta -bmcredito) <1
               );
               -- Corroboro si encontre movimientos del banco cuyo importe coincidan con el importe de la liquidacion
               SELECT into cantFila count(*) FROM temp_bancamovimiento;
               IF (cantFila = 0)THEN
                     INSERT INTO temp_bancamovimiento (bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito )(
                         -- SELECT bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,SUM(bmcredito)
                          SELECT bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito
                          FROM (SELECT bmfecha , bmconcepto, SUM(bmcredito) as montoacreditado
                                FROM temp_bancamovimiento_aux
                                WHERE bmfecha  = rliquidaciontarjeta.ltfechapago
                                      AND  bmconcepto ilike concat('%',rliquidaciontarjeta.elcomercio ,'%' )
                                      -- AND  abs (rliquidaciontarjeta.ltimporteliquidaciontarjeta -bmcredito) <1
                                group BY bmfecha,bmconcepto) as T
                          JOIN temp_bancamovimiento_aux USING(bmfecha,bmconcepto)
                          WHERE  abs(montoacreditado - rliquidaciontarjeta.ltimporteliquidaciontarjeta)<1
                      );
               
               END IF;

              SELECT INTO cant  conciliacionbancaria_conciliarmovimientos(concat('{manual=false, idcentroconciliacionbancaria=',rparam.idcentroconciliacionbancaria,', idconciliacionbancaria=',rparam.idconciliacionbancaria,', nrocuentac=', rparam.nrocuentac ,'}'));
              cantprocesados = cantprocesados + cant;
          FETCH cliquidaciontarjeta INTO rliquidaciontarjeta;
          END LOOP;
          CLOSE cliquidaciontarjeta;



      
    ELSE

        SELECT conciliacionbancaria_auto_mp_liquidaciontarjetas($1) INTO cantprocesados;

    END IF;


      -- Restauro las temporales
      DELETE FROM temp_bancamovimiento;
      DELETE FROM temp_movsiges;

      INSERT INTO temp_bancamovimiento (bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito )(
                 SELECT bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito
                 FROM temp_bancamovimiento_aux );

      INSERT INTO temp_movsiges (elcomprobante	,tablacomp	,clavecomp	,fechacompr	,monto	,impconc)  (
               SELECT a.elcomprobante	,a.tablacomp	,a.clavecomp	,a.fechacompr	,a.monto	,a.impconc
               FROM temp_movsiges_aux as a ) ;




return cantprocesados;
END;
$function$
