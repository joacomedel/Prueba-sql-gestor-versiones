CREATE OR REPLACE FUNCTION public.conciliacionbancaria_auto_pagoordenpagocontablereintegros(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rusuario RECORD;
    roperacion record;
    rbancaoperacion record;
    cbancaoperacion refcursor;
    cmovsiges CURSOR FOR SELECT * FROM  temp_movsiges; -- temporal con los movimientos de siges que se desean conciliar
    clavecomp varchar;
    sqllaclave varchar;
    sql  varchar;
    cpagoopc refcursor;
    rpagoopc record;
    rinfopago record;
    rmovsiges record;
    rmovimientobanco  record;
    rparam record;
    elidconitem bigint;
    losparam  varchar;
    cant integer;
    saldo_sin_conciliar_siges double precision;
    monto  double precision;
    cantprocesados integer;

BEGIN

     cantprocesados = 0;
     EXECUTE sys_dar_filtros($1) INTO rparam;
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

     OPEN cbancaoperacion FOR SELECT idbancaoperacion, count(*)
     FROM (
            SELECT split_part(split_part(temp_movsiges_aux.clavecomp, '|',1),'=',2)::bigint as idpagoordenpagocontable , split_part( split_part(temp_movsiges_aux.clavecomp, '|',2) ,'=',2)::integer  as idcentropagoordenpagocontable
            FROM temp_movsiges_aux
            WHERE tablacomp='pagoordenpagocontable' 
     )as T
     NATURAL JOIN pagoordenpagocontable
     LEFT JOIN ordenpagocontablebancatransferencia USING (idcentropagoordenpagocontable, idpagoordenpagocontable)
     LEFT JOIN bancatransferencia USING (idbancatransferencia)
     LEFT JOIN bancaoperacion USING (idbancaoperacion)
     WHERE  true  AND not nullvalue(idbancatransferencia) 
     GROUP BY idbancaoperacion
     having count(*)>1 ;

     FETCH cbancaoperacion INTO rbancaoperacion;
     WHILE FOUND LOOP
           --- Repetir por cada idbancaoperacion encontrada
           DELETE FROM temp_movsiges ;
           INSERT INTO temp_movsiges (elcomprobante	,tablacomp	,clavecomp	,fechacompr	,monto	,impconc)  (
               SELECT T.elcomprobante	,T.tablacomp	,T.clavecomp	,T.fechacompr	,T.monto	,T.impconc
               FROM (
                     SELECT split_part(split_part(temp_movsiges_aux.clavecomp, '|',1),'=',2)::bigint as idpagoordenpagocontable , split_part( split_part(temp_movsiges_aux.clavecomp, '|',2) ,'=',2)::integer  as idcentropagoordenpagocontable,*
                     FROM temp_movsiges_aux
                     WHERE tablacomp='pagoordenpagocontable' 
               )as T
               NATURAL JOIN pagoordenpagocontable
               LEFT JOIN ordenpagocontablebancatransferencia USING (idcentropagoordenpagocontable, idpagoordenpagocontable)
               LEFT JOIN bancatransferencia USING (idbancatransferencia)
               LEFT JOIN bancaoperacion USING (idbancaoperacion)
               WHERE  idbancaoperacion = rbancaoperacion.idbancaoperacion
           );

          --- Repetir por cada idbancaoperacion encontrada
          --- Buscar movimientos del banco en la misma fecha y el mismo importe
          SELECT INTO roperacion * FROM bancaoperacion WHERE idbancaoperacion = rbancaoperacion.idbancaoperacion;
          DELETE FROM temp_bancamovimiento;
          INSERT INTO temp_bancamovimiento (bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito )(
                 SELECT bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito
                 FROM temp_bancamovimiento_aux
                 WHERE bmdebito = roperacion.bomontototal
                       AND bmfecha = roperacion.bofechapago);

          SELECT INTO cant  conciliacionbancaria_conciliarmovimientos(concat('{manual=false, idcentroconciliacionbancaria=',rparam.idcentroconciliacionbancaria,', idconciliacionbancaria=',rparam.idconciliacionbancaria,', nrocuentac=', rparam.nrocuentac ,'}'));
          cantprocesados = cantprocesados + cant;
      FETCH cbancaoperacion INTO rbancaoperacion;
      END LOOP;
      CLOSE cbancaoperacion;

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
