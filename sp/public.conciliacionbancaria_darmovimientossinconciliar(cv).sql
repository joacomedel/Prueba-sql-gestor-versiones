CREATE OR REPLACE FUNCTION public.conciliacionbancaria_darmovimientossinconciliar(character varying)
 RETURNS TABLE(elcomprobante character varying, fechacompr date, detalle character varying, monto double precision, observacion character varying, tablacomp character varying, clavecomp character varying, impconc double precision, idasientogenerico integer, idcentroasientogenerico integer, nrocuentacorigen character varying, agfechacontable date)
 LANGUAGE plpgsql
AS $function$DECLARE
     rfiltros record ;
     rbusq record;
     rconc record;
     eltipocomp varchar;
     cadbusq varchar;
     laoperacion varchar;
         tipomov varchar;
BEGIN
/**
***  LEERR !!! Si se desea realizar cualquier modificacion se debe eliminar la funcion y volver a crear.  ***
***  
*** Ejecutar antes de compilar  = >> DROP FUNCTION darmovimientossinconciliar (date, date);
*** MaLaPi 16-03-2018 Modificar Solo usando PgAdmin3
*/

 EXECUTE sys_dar_filtros($1) INTO rfiltros;
 SELECT INTO rbusq split_part(rfiltros.tipoComp , '|', 2);
 
 IF (FOUND AND rfiltros.tipoComp<>'')THEN
    --RAISE NOTICE 'ENTROOOO AL IFFFF0F (%)',rfiltros.tipoComp;
     eltipocomp = split_part(rfiltros.tipoComp , '|', 1);
     cadbusq = split_part(rfiltros.tipoComp , '|', 2);
     laoperacion = split_part(rfiltros.tipoComp , '|', 3);  
 ELSE 
      --RAISE NOTICE 'NOOOOOOOOOOOOOOOO ENTROOOO AL IFFFFF';
        eltipocomp = 'OPC';
        cadbusq = '';
        laoperacion ='SIN_OP';

 END IF;
  --RAISE NOTICE 'eltipocomp(%)',eltipocomp;
  --RAISE NOTICE 'cadbusq(%)',cadbusq;
  --RAISE NOTICE 'laoperacion(%)',laoperacion;
tipomov = 'tipomov=siges,';

-- GERMAN 23/02/2022 Agrego if para funcionad de busqueda por conciliacin o entre fechas

-------  BelenA, cambio todos los nullvalue(dato) por (dato) IS NULL para optimizar tiempos


--IF NOT nullvalue(rfiltros.idconciliacionbancaria) THEN
IF (rfiltros.idconciliacionbancaria) IS NOT NULL THEN
SELECT INTO rconc * 
FROM conciliacionbancaria 
JOIN cuentabancariasosunc using(idcuentabancaria)
WHERE idconciliacionbancaria = rfiltros.idconciliacionbancaria 
      AND idcentroconciliacionbancaria = rfiltros.idcentroconciliacionbancaria ;
ELSE
    SELECT INTO rconc * 
    FROM cuentabancariasosunc 
    WHERE nrocuentac = rfiltros.nrocuentac;

END IF;

 IF (eltipocomp ='' OR eltipocomp = 'OPC' ) THEN
 RETURN QUERY
        SELECT * 
        FROM (
        SELECT concat('OPC:',idordenpagocontable,'|',idcentroordenpagocontable)::varchar,
            opcfechaingreso::date ,
            opcobservacion::VARCHAR ,
            popmonto ::double precision as monto,
            case when (trim(split_part(split_part(split_part(popobservacion, 'Estado', 1),'--INFO BANCA--',2),'NroOp.:',2 ))='') THEN
                             popobservacion
                        ELSE 
                             concat(trim(split_part(split_part(split_part(popobservacion, 'Estado', 1),'--INFO BANCA--',2),'NroOp.:',2 )),split_part(split_part(popobservacion, 'Estado', 2),'--INFO BANCA--',1))
                        END ::VARCHAR as observacion,
            'pagoordenpagocontable'::VARCHAR as tablacomp,
            concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|idcentropagoordenpagocontable=',idcentropagoordenpagocontable)::varchar as clavecomp,
            popmonto - conciliacionbancaria_montoconciliado(concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|idcentropagoordenpagocontable=',idcentropagoordenpagocontable),concat('{',tipomov,'idcbitipo=1',',tabla=pagoordenpagocontable',', nrocuentac=', rconc.nrocuentac ,'}')::varchar) as impconc
           ,asientogenerico.idasientogenerico,  asientogenerico.idcentroasientogenerico -- VAS 070922
            ,'SD'::character varying nrocuentacorigen -- VAS 021123
            ,asientogenerico.agfechacontable
        FROM  pagoordenpagocontable
        NATURAL JOIN ordenpagocontableestado
        NATURAL JOIN ordenpagocontable

        JOIN asientogenerico ON (idasientogenericocomprobtipo=1 
                                  AND (idasientogenericorevertido) IS NULL  --BelenA cambio el nullvalue por is null
                                  AND concat(idordenpagocontable,'|',idcentroordenpagocontable  ) = idcomprobantesiges 
                                  --AND nullvalue(idasientogenericorevertido) 
                                  AND agdescripcion not ilike '%REVERSION%' --- VAS 08062022 para poder retornar la información del asiento del comprobante 
         )

        WHERE  idvalorescaja = rconc.idvalorescajacuentab -- forma pago transferencia
            AND opcfechaingreso>=rfiltros.movfechadesde 
                        and opcfechaingreso<=rfiltros.movfechahasta  -- fecha movimientos a conciliar
            AND ( idordenpagocontableestadotipo <> 6 and (opcfechafin)IS NULL) 
        ) as T
    WHERE  
          (opcobservacion ilike concat('%',rfiltros.cadena,'%')  OR T.observacion ilike concat('%',rfiltros.cadena,'%') )
        ORDER BY observacion ASC; 
   END IF;

IF (eltipocomp = 'LT' ) THEN
   RETURN QUERY 
        SELECT concat('LT:',idliquidaciontarjeta,'|',idcentroliquidaciontarjeta)::varchar,
            ltfechapago::date ,
            ltobservacion::VARCHAR ,
            (CASE WHEN cuentabancariasosunc.nrocuentac = '10377' THEN lttotalcupones ELSE ltimporteliquidaciontarjeta END)  ::double precision as monto, 
            --ltimporteliquidaciontarjeta ::double precision as monto,
            ltobservacion::VARCHAR as observacion,
            'liquidaciontarjeta'::VARCHAR as tablacomp,
            concat('idliquidaciontarjeta=',idliquidaciontarjeta,'|idcentroliquidaciontarjeta=',idcentroliquidaciontarjeta)::varchar as clavecomp,

            (CASE WHEN cuentabancariasosunc.nrocuentac = '10377' THEN           
            (lttotalcupones - 
            conciliacionbancaria_montoconciliado(concat('idliquidaciontarjeta=',idliquidaciontarjeta,'|idcentroliquidaciontarjeta=',idcentroliquidaciontarjeta),concat('{',tipomov,'idcbitipo=2',',tabla=liquidaciontarjeta',', nrocuentac=', rconc.nrocuentac ,'}')::varchar ))
            ELSE 
            (ltimporteliquidaciontarjeta - 
            conciliacionbancaria_montoconciliado(concat('idliquidaciontarjeta=',idliquidaciontarjeta,'|idcentroliquidaciontarjeta=',idcentroliquidaciontarjeta),concat('{',tipomov,'idcbitipo=2',',tabla=liquidaciontarjeta',', nrocuentac=', rconc.nrocuentac ,'}')::varchar )) END) as impconc
             ,asientogenerico.idasientogenerico,    asientogenerico.idcentroasientogenerico -- VAS 070922
             ,'SD'::character varying nrocuentacorigen -- VAS 021123
             ,asientogenerico.agfechacontable
        FROM  liquidaciontarjeta
        NATURAL JOIN cuentabancariasosunc
        NATURAL JOIN liquidaciontarjetaestado
        --LEFT JOIN conciliacionbancariaitemliquidaciontarjeta USING (idliquidaciontarjeta,idcentroliquidaciontarjeta)
        /*Vas 09/06/22 para poder retornar la información del asiento del comprobante  */
        JOIN mapeoliquidaciontarjeta USING (idliquidaciontarjeta,idcentroliquidaciontarjeta )
        JOIN asientogenerico ON ( idasientogenericocomprobtipo= 4
                                AND (idasientogenericorevertido) IS NULL  --BelenA cambio el nullvalue por is null
                                  AND idcomprobantesiges =  concat(nroordenpago,'|',idcentroordenpago )
                                  --AND nullvalue(idasientogenericorevertido)
                                  AND agdescripcion not ilike '%REVERSION%' )
        /****Vas 09/06/22*/
        /*WHERE   
        --comento Dani el 13082020 por q no traia por ejemplo movimientos de siges del centro=Viedma
        --idbanco =191  --banco credicoop AND 
            nrocuentac = rfiltros.nrocuentac
            AND ltfechapago>=rfiltros.movfechadesde and ltfechapago<=rfiltros.movfechahasta  -- fecha movimientos a conciliar
            --KR 24-10-22 el estado de la liquidacion tiene que ser cerrada
            --AND ( idtipoestadoliquidaciontarjeta <> 1 and nullvalue(ltefechafin)) 
            AND ( idtipoestadoliquidaciontarjeta=2 and nullvalue(ltefechafin)) 
            AND ltobservacion ilike concat('%',rfiltros.cadena,'%') ;*/
        WHERE   
            nrocuentac = rfiltros.nrocuentac
            AND ((ltefechafin) IS NULL and idtipoestadoliquidaciontarjeta=2)             
            AND ltfechapago>=rfiltros.movfechadesde and ltfechapago<=rfiltros.movfechahasta  -- fecha movimientos a conciliar
            AND ltobservacion ilike concat('%',rfiltros.cadena,'%') ;

  END IF;
  

  IF (eltipocomp ='RE' ) THEN
   RETURN QUERY 
 SELECT concat('REC:',idrecibo,'|',centro)::varchar,
            fecharecibo::date ,
            imputacionrecibo::VARCHAR ,
            recibocupon.monto ::double precision as monto,
            /*imputacionrecibo::VARCHAR as observacion,*/
            
            concat(datosrecibo.nrocliente,' ',datosrecibo.denominacion,' ',substring(
split_part(imputacionrecibo,'-',1)::varchar,length(split_part(imputacionrecibo,'-',1)::varchar)-8,length(split_part(imputacionrecibo,'-',1)::varchar))
,' - ',imputacionrecibo) ::VARCHAR as observacion ,
        
            'recibocupon'::VARCHAR as tablacomp,
            concat('idrecibocupon=',idrecibocupon,'|idcentrorecibocupon=',idcentrorecibocupon)::varchar as clavecomp,
            recibocupon.monto - conciliacionbancaria_montoconciliado(concat('idrecibocupon=',idrecibocupon,'|idcentrorecibocupon=',idcentrorecibocupon),concat('{',tipomov,'idcbitipo=3',',tabla=recibocupon',', nrocuentac=', rconc.nrocuentac ,'}')::varchar) as impconc
             ,asientogenerico.idasientogenerico,    asientogenerico.idcentroasientogenerico -- VAS 070922
             , datosrecibo.nrocuentacorigen -- VAS 011123
             ,asientogenerico.agfechacontable
            
        FROM recibo 
        NATURAL JOIN recibocupon
        /*LEFT JOIN ctactepagocliente  ON (idcomprobante = idrecibo and centro = idcentropago )
           left  join clientectacte using(idclientectacte,idcentroclientectacte)
        left join cliente  on (cliente.nrocliente=clientectacte.nrocliente and cliente.barra=clientectacte.barra)*/
        LEFT JOIN (select idcomprobante ,idcentropago,nrocliente ,barra,denominacion,idclientectacte,idcentroclientectacte
                           ,    nrocuentac as nrocuentacorigen
                   from ctactepagocliente 
                   LEFT JOIN cuentascontables USING (nrocuentac)
                   natural join clientectacte 
                   natural join cliente
                   union
                   select idcomprobante ,idcentropago,nrodoc as nrocliente ,tipodoc as barra,denominacion,1 as idclientectacte,1 as idcentroclientectacte
                           ,nrocuentac as nrocuentacorigen
                   from cuentacorrientepagos 
                   LEFT JOIN cuentascontables USING (nrocuentac)
                   join cliente on (nrodoc=nrocliente and cliente.barra=cuentacorrientepagos.tipodoc)
        ) as datosrecibo ON (idcomprobante = idrecibo and centro = idcentropago )
        /*VAS 09-06-22*/
        JOIN asientogenerico ON ( idasientogenericocomprobtipo= 8
                                AND (idasientogenericorevertido) IS NULL  --BelenA cambio el nullvalue por is null
                                  AND idcomprobantesiges =  concat(idrecibo,'|',centro )
                                  --AND nullvalue(idasientogenericorevertido)
                                  AND agdescripcion not ilike '%REVERSION%' )
         /*VAS 09-06-22*/
         /*WHERE fecharecibo::date >= rfiltros.movfechadesde and fecharecibo::date<=rfiltros.movfechahasta
            and idvalorescaja = rconc.idvalorescajacuentab 
            and nullvalue(reanulado)
            and (sys_generafiltroconvarchar(laoperacion,imputacionrecibo,concat('%',cadbusq,'%')) )
                 --or
                 and (not nullvalue (datosrecibo.idcomprobante) /*and datosrecibo.idclientectacte=1 
                      and idcentroclientectacte=1*/)    
            ;*/

        WHERE idvalorescaja = rconc.idvalorescajacuentab 
            and (reanulado) IS NULL
            and fecharecibo::date >= rfiltros.movfechadesde and fecharecibo::date<=rfiltros.movfechahasta
            and (sys_generafiltroconvarchar(laoperacion,imputacionrecibo,concat('%',cadbusq,'%')) )
                 --or
                 and ((datosrecibo.idcomprobante) IS NOT NULL /*and datosrecibo.idclientectacte=1 
                      and idcentroclientectacte=1*/)    
            ;
 
  END IF;

  
   IF (eltipocomp ='FA' ) THEN
   RETURN QUERY SELECT concat(tipofactura,' ',nrofactura,'|',nrosucursal)::varchar,
            fechaemision::date ,
            denominacion::VARCHAR ,
            fvc.monto ::double precision as monto,
            denominacion::VARCHAR as observacion,
            'facturaventacupon'::VARCHAR as tablacomp,
            concat('idfacturacupon=',idfacturacupon,'|centro=',fvc.centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura)::varchar as clavecomp,
            fvc.monto - 

conciliacionbancaria_montoconciliado(concat('idfacturacupon=',idfacturacupon,'|centro=',fvc.centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura),concat('{',tipomov,'idcbitipo=4',',tabla=facturaventacupon',', nrocuentac=', rconc.nrocuentac , '}')::varchar ) as impconc
         ,asientogenerico.idasientogenerico,    asientogenerico.idcentroasientogenerico -- VAS 070922
         ,'SD'::character varying nrocuentacorigen -- VAS 021123
         ,asientogenerico.agfechacontable
        FROM facturaventa 
        JOIN facturaventacupon as fvc USING(nrofactura,tipofactura,nrosucursal,tipocomprobante)
                -- LEFT JOIN conciliacionbancariaitemfacturaventacupon as cbifv USING (idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura) 
        JOIN cliente ON (nrocliente = nrodoc and facturaventa.barra = cliente.barra)
        JOIN asientogenerico  ON ( idasientogenericocomprobtipo= 5 
                           AND (idasientogenericorevertido) IS NULL  --BelenA cambio el nullvalue por is null
                           AND idcomprobantesiges =  concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura)
                           --AND nullvalue(idasientogenericorevertido)
                           AND  agdescripcion not ilike '%REVERSION%' ) --- VAS 08062022 para poder retornar la información del asiento del comprobante 
    
        /* WHERE fechaemision  >= rfiltros.movfechadesde and fechaemision<= rfiltros.movfechahasta
            AND (tipofactura ='FA'  or tipofactura ='DC' or tipofactura ='RC'  or tipofactura ='NC')
            AND idvalorescaja = rconc.idvalorescajacuentab  
            AND  nullvalue(anulada) 
            AND denominacion ilike concat('%',rfiltros.cadena,'%')  ; */
        WHERE idvalorescaja = rconc.idvalorescajacuentab  
            AND (tipofactura ='FA'  or tipofactura ='DC' or tipofactura ='RC'  or tipofactura ='NC')
            AND  (anulada) IS NULL
            AND fechaemision  >= rfiltros.movfechadesde and fechaemision<= rfiltros.movfechahasta
            AND denominacion ilike concat('%',rfiltros.cadena,'%')  ;
 END IF;
IF (eltipocomp ='NC' ) THEN
   RETURN QUERY SELECT concat(tipofactura,' ',nrofactura,'|',nrosucursal)::varchar,
            fechaemision::date ,
            denominacion::VARCHAR ,
            fvc.monto ::double precision as monto,
            denominacion::VARCHAR as observacion,
            'facturaventacupon'::VARCHAR as tablacomp,
            concat('idfacturacupon=',idfacturacupon,'|centro=',fvc.centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura)::varchar as clavecomp,
            fvc.monto - 

conciliacionbancaria_montoconciliado(concat('idfacturacupon=',idfacturacupon,'|centro=',fvc.centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura),concat('{',tipomov,'idcbitipo=4',',tabla=facturaventacupon',', nrocuentac=', rconc.nrocuentac , '}')::varchar ) as impconc
         ,asientogenerico.idasientogenerico,    asientogenerico.idcentroasientogenerico -- VAS 070922
         ,'SD'::character varying nrocuentacorigen -- VAS 021123
         ,asientogenerico.agfechacontable as agfechacontable
        FROM facturaventa 
        JOIN facturaventacupon fvc USING(nrofactura,tipofactura,nrosucursal,tipocomprobante)
                -- LEFT JOIN conciliacionbancariaitemfacturaventacupon as cbifv USING (idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura) 
        JOIN cliente ON (nrocliente = nrodoc and facturaventa.barra = cliente.barra)
        JOIN asientogenerico  ON ( idasientogenericocomprobtipo= 5 
                           AND (idasientogenericorevertido) IS NULL  --BelenA cambio el nullvalue por is null
                           AND idcomprobantesiges =  concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura)
                           --AND nullvalue(idasientogenericorevertido)
                           AND  agdescripcion not ilike '%REVERSION%' ) --- VAS 08062022 para poder retornar la información del asiento del comprobante 
        
        /*WHERE fechaemision  >= rfiltros.movfechadesde and fechaemision<= rfiltros.movfechahasta
            AND ( tipofactura ='DC' or tipofactura ='RC' or tipofactura ='NC')
            AND idvalorescaja = rconc.idvalorescajacuentab  
            AND  nullvalue(anulada) 
            AND denominacion ilike concat('%',rfiltros.cadena,'%');*/
            WHERE idvalorescaja = rconc.idvalorescajacuentab
            AND ( tipofactura ='DC' or tipofactura ='RC' or tipofactura ='NC')
            AND (anulada) IS NULL
            AND fechaemision  >= rfiltros.movfechadesde and fechaemision<= rfiltros.movfechahasta
            AND denominacion ilike concat('%',rfiltros.cadena,'%');
 END IF;

 IF (eltipocomp ='MIN' ) THEN
   RETURN QUERY SELECT 
concat('MIN:',op.nroordenpago,'|',op.idcentroordenpago)::varchar,
               fechaingreso::date ,
               replace(concepto,'Pago a otros:','')::VARCHAR ,
               --Dani reemplazo el 17032023 por pedido de Silvia solo debe mostrar la cuenta afecta al banco y mostrar dicho monto
               -- importetotal ::double precision as monto,
           --    debe ::double precision as monto,
           -- BelenA 11-01-24 el monto dependera si tiene un ordenpagoimputacion con el nrocuentac o si es la minuta el que lo tiene y me importa el total
        CASE WHEN (monto_imp)IS NULL THEN importetotal ELSE  monto_imp END ::double precision AS importetotal,
               replace(concepto,'Pago a otros:','')::VARCHAR as observacion,
              'ordenpago'::VARCHAR as tablacomp

             ,concat('nroordenpago=',op.nroordenpago,'|idcentroordenpago=',op.idcentroordenpago)::varchar as clavecomp,
               (CASE WHEN (monto_imp) IS NULL THEN importetotal ELSE  monto_imp END ::double precision ) - 
               conciliacionbancaria_montoconciliado(concat('nroordenpago=',op.nroordenpago,'|idcentroordenpago=',op.idcentroordenpago),concat('{','tipomov=siges,','tabla=ordenpago',', nrocuentac=', rconc.nrocuentac ,'}')::varchar ) as impconc 
             ,asientogenerico.idasientogenerico,    asientogenerico.idcentroasientogenerico -- VAS 070922
             ,'SD'::character varying nrocuentacorigen -- VAS 021123
             ,asientogenerico.agfechacontable as agfechacontable
FROM  ordenpago op
NATURAL JOIN cambioestadoordenpago
JOIN ordenpagotipo using (idordenpagotipo) 
-- BelenA 11-01-24 se cambio para que cuando una minuta tiene mas de una imputacion 
-- busque si entre las imputaciones hay una con el nrocuentac correspondiente
LEFT JOIN (SELECT nroordenpago , idcentroordenpago,SUM(debe-haber)as monto_imp, nrocuentac 
           FROM ordenpagoimputacion 
            WHERE nrocuentac=rconc.nrocuentac
             GROUP BY nroordenpago , idcentroordenpago, nrocuentac
            ) as opi ON (opi.nroordenpago=op.nroordenpago AND opi.idcentroordenpago=op.idcentroordenpago)
 JOIN asientogenerico  ON  (idasientogenericocomprobtipo=4  
                  AND (idasientogenericorevertido) IS NULL  --BelenA cambio el nullvalue por is null
                  --AND nullvalue(idasientogenericorevertido) 
                  AND  concat(op.nroordenpago,'|',op.idcentroordenpago) = idcomprobantesiges  
                  AND  agdescripcion not ilike '%REVERSION%'
           ) --- VAS 08062022 para poder retornar la información del asiento del comprobante 

 WHERE 
               (idordenpagotipo <>7 AND idordenpagotipo <> 2 )
               AND   ( opi.nrocuentac = rconc.nrocuentac or   op.nrocuentachaber = rconc.nrocuentac )
               AND ( (ceopfechafin) IS NULL and idtipoestadoordenpago <>4   ) 
               AND fechaingreso>=rfiltros.movfechadesde and fechaingreso<=rfiltros.movfechahasta  -- fecha movimientos a conciliar
               --AND ( nullvalue(ceopfechafin)and idtipoestadoordenpago <>4   ) 
               AND concepto ilike concat('%','','%')
        ;

  END IF;

  
--------------------

IF (eltipocomp ='FACOMP' ) THEN
   RETURN QUERY SELECT 
        concat('FACOMP:',rlf.idrecepcion, '-',rlf.idcentroregional)::varchar, 
        rlf.fechaemision::date,
        concat(rlf.tipofactura,' ',rlf.clase,' - ',rlf.numfactura,' | ' ,p.idprestador, ' - ',pdescripcion) ::VARCHAR, 
        --rlf.monto ::double precision as monto,  --- BelenA comento esto, no me toma el total del comprobante sino de la FP
        reclibrofact_formpago.rlffpmonto ::double precision as monto,
        concat(rlf.tipofactura,' ',rlf.clase,' - ',rlf.numfactura,' | ' ,p.idprestador, ' - ',pdescripcion) ::VARCHAR as observacion , 
        'reclibrofact'::VARCHAR as tablacomp,
        concat('idrecepcion=',rlf.idrecepcion,'|idcentroregional=',rlf.idcentroregional)::varchar as clavecomp,     
        --rlf.monto - conciliacionbancaria_montoconciliado(concat('idrecepcion=',rlf.idrecepcion,'|idcentroregional=',rlf.idcentroregional),
        --concat('{',tipomov,'idcbitipo=7',',tabla=reclibrofact',', nrocuentac=', 10261 ,'}')::varchar) as impconc, --- BelenA comento esto, no me toma el total del comprobante sino de la FP
        reclibrofact_formpago.rlffpmonto - conciliacionbancaria_montoconciliado(concat('idrecepcion=',rlf.idrecepcion,'|idcentroregional=',rlf.idcentroregional),
        concat('{',tipomov,'idcbitipo=7',',tabla=reclibrofact',', nrocuentac=', 10261 ,'}')::varchar) as impconc,
        asientogenerico.idasientogenerico,  asientogenerico.idcentroasientogenerico,
        'SD'::character varying nrocuentacorigen
        ,asientogenerico.agfechacontable
        FROM reclibrofact rlf       
        LEFT JOIN reclibrofact_formpago ON (rlf.idrecepcion=reclibrofact_formpago.idrecepcion AND rlf.idcentroregional=reclibrofact_formpago.idcentroregional)
        LEFT JOIN cuentabancariasosunc as cbs  ON (reclibrofact_formpago.idvalorescaja=cbs.idvalorescajacuentab)
        LEFT JOIN tipocomprobante as  t ON (rlf.idtipocomprobante = t.idtipocomprobante)
        LEFT JOIN prestador as p ON (rlf.idprestador = p.idprestador)
        JOIN asientogenerico ON ( idasientogenericocomprobtipo= 7
                                AND (idasientogenericorevertido) IS NULL  --BelenA cambio el nullvalue por is null
                                  AND idcomprobantesiges =  concat(rlf.numeroregistro, '|',rlf.anio)
                                  --AND nullvalue(idasientogenericorevertido)
                                  AND agdescripcion not ilike '%REVERSION%' )

        WHERE true  
        AND cbs.nrocuentac= rconc.nrocuentac AND
        rlf.fechaemision >= rfiltros.movfechadesde AND 
        rlf.fechaemision <= rfiltros.movfechahasta;
        --AND cbs.nrocuentac= rconc.nrocuentac;

 END IF;

--------------------
END
$function$
