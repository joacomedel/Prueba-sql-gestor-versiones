CREATE OR REPLACE FUNCTION public.conciliacionbancaria_auto_facturas(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rusuario RECORD;
    datoaux  RECORD;
    cfacturas refcursor;
    rfactura record;
    cmovsiges CURSOR FOR SELECT * FROM  temp_movsiges; -- temporal con los movimientos de siges que se desean conciliar
    clavecomp varchar;
    rfiltros RECORD;
    rmovsiges record;
    rmovimientobanco  record;
    rparam record;
    rconc  record;
    elidconitem bigint;
    losparam  varchar;
    cant integer;
    cantFila integer;
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

     SELECT INTO rconc * 
       FROM conciliacionbancaria 
       JOIN cuentabancariasosunc using(idcuentabancaria)
       WHERE idconciliacionbancaria = rparam.idconciliacionbancaria 
                AND idcentroconciliacionbancaria = rparam.idcentroconciliacionbancaria ;

     /*obtengo los grupos de SIGES que tienen el mismo idoperacion */
     IF (not iftableexistsparasp('temp_movsiges_aux') ) THEN 
         CREATE TEMP TABLE temp_movsiges_aux AS SELECT * FROM temp_movsiges; -- resguardo la tabla con los movimientos de SIGES
     END IF;
     IF (not iftableexistsparasp('temp_bancamovimiento_aux') ) THEN 
         CREATE TEMP TABLE temp_bancamovimiento_aux AS SELECT * FROM temp_bancamovimiento; -- resguardo la tabla con los movimientos del banco
     END IF;

--
     OPEN cfacturas FOR  SELECT nrofactura,nrosucursal,tipofactura,tipocomprobante,fechaemision,nrocliente,facturaventa.barra,centro,idfacturacupon,facturaventacupon.monto,anulada
     FROM (
            SELECT split_part(split_part(temp_movsiges_aux.clavecomp, '|',1),'=',2)::bigint as idfacturacupon, split_part( split_part(temp_movsiges_aux.clavecomp, '|',2) ,'=',2)::integer  as centro,
split_part(split_part(temp_movsiges_aux.clavecomp, '|',3),'=',2)::bigint as nrofactura, split_part( split_part(temp_movsiges_aux.clavecomp, '|',4) ,'=',2)::integer as tipocomprobante,
split_part(split_part(temp_movsiges_aux.clavecomp, '|',5),'=',2)::integer as nrosucursal,
split_part(split_part(temp_movsiges_aux.clavecomp, '|',6),'=',2)::varchar as tipofactura
            FROM temp_movsiges_aux 
            WHERE tablacomp='facturaventacupon'  
  )as T
     NATURAL JOIN facturaventacupon
     NATURAL JOIN facturaventa
     JOIN  
  cliente
  on (nrodoc=nrocliente and cliente.barra=facturaventa.barra)
 /*where 
 idvalorescaja =rconc.idvalorescajacuentab  AND  nullvalue(anulada) 
and facturaventacupon.monto=rfactura.monto
and centro = rfactura.centro
                      AND idfacturacupon= rfactura.idfacturacupon
                      AND nrofactura= rfactura.nrofactura
                      AND nrosucursal= rfactura.nrosucursal
                      AND tipocomprobante= rfactura.tipocomprobante
                      AND tipofactura= rfactura.tipofactura */;

     FETCH cfacturas INTO rfactura;
     WHILE FOUND LOOP
           --- Repetir por cada idbancaoperacion encontrada
           DELETE FROM temp_movsiges ;
           INSERT INTO temp_movsiges (elcomprobante	,tablacomp	,clavecomp	,fechacompr	,monto	,impconc)  (
               SELECT T.elcomprobante	,T.tablacomp	,T.clavecomp	,T.fechacompr	,T.monto	,T.impconc
               FROM (
                     SELECT  split_part(split_part(temp_movsiges_aux.clavecomp, '|',1),'=',2)::bigint as idfacturacupon, split_part( split_part(temp_movsiges_aux.clavecomp, '|',2) ,'=',2)::integer  as centro,
split_part(split_part(temp_movsiges_aux.clavecomp, '|',3),'=',2)::bigint as nrofactura, split_part( split_part(temp_movsiges_aux.clavecomp, '|',4) ,'=',2)::integer as tipocomprobante,
split_part(split_part(temp_movsiges_aux.clavecomp, '|',5),'=',2)::integer as nrosucursal,
split_part(split_part(temp_movsiges_aux.clavecomp, '|',6),'=',2)::varchar as tipofactura,*
                     FROM temp_movsiges_aux
                     WHERE tablacomp='facturaventacupon'
               )as T
               NATURAL JOIN facturaventacupon
               NATURAL JOIN facturaventa
               WHERE  centro = rfactura.centro
                      AND idfacturacupon= rfactura.idfacturacupon
                      AND nrofactura= rfactura.nrofactura
                      AND nrosucursal= rfactura.nrosucursal
                      AND tipocomprobante= rfactura.tipocomprobante
                      AND tipofactura= rfactura.tipofactura   )

;

          --- Repetir por cada idbancaoperacion encontrada
          --- Buscar movimientos del banco en la misma fecha y el mismo comercio
        
          DELETE FROM temp_bancamovimiento;
          INSERT INTO temp_bancamovimiento (bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito )(
                 SELECT bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito
                 FROM temp_bancamovimiento_aux
                 WHERE bmfecha::date  = rfactura.fechaemision::date
/*ver si es correcto esto...*/
and bmconcepto ilike concat('%','rfactura.nrocliente','%')
         -- AND  bmconcepto ilike concat('%',rrecibo.imputacionrecibo ,'%' )
            AND  abs (rfactura.monto-bmcredito) <1
           );

 
select into datoaux * from temp_bancamovimiento_aux;
RAISE NOTICE '>>>>>>>>Llamada al datoaux.idbancamovimiento%',datoaux;
           -- Corroboro si encontre movimientos del banco cuyo importe coincidan con el importe del recibo
           SELECT into cantFila count(*) FROM temp_bancamovimiento;
           IF (cantFila = 0)THEN
 RAISE NOTICE 'entro a cantfila=0 (%)',cantFila ;

                 INSERT INTO temp_bancamovimiento (bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito )(
                     -- SELECT bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,SUM(bmcredito)
                      SELECT bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito
                      FROM (SELECT bmfecha , bmconcepto, SUM(bmcredito) as montoacreditado
                            FROM temp_bancamovimiento_aux
                            WHERE bmfecha::date  = rfactura.fechaemision::date
                                  AND  bmconcepto ilike concat('%',rfactura.nrocliente,'%' )
                                   AND  abs (rfactura.monto-bmcredito) <1
                            group BY bmfecha,bmconcepto) as T
                      JOIN temp_bancamovimiento_aux USING(bmfecha,bmconcepto)
                      WHERE  abs(montoacreditado - rfactura.monto)<1
                  );
           
           END IF;

          SELECT INTO cant  conciliacionbancaria_conciliarmovimientos(concat('{manual=false, idcentroconciliacionbancaria=',rparam.idcentroconciliacionbancaria,', idconciliacionbancaria=',rparam.idconciliacionbancaria,', nrocuentac=', rparam.nrocuentac ,'}'));
          cantprocesados = cantprocesados + cant;
          FETCH cfacturas INTO rfactura;
      END LOOP;
      CLOSE cfacturas ;

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
END;$function$
