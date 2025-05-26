CREATE OR REPLACE FUNCTION public.mesaentrada_abmprecarga(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--RECORD
        reccentrocosto RECORD;
        rprecarga RECORD;
        rrlfp RECORD;
        ractividad  RECORD;
        relcc  RECORD;
        rrlfact  RECORD;
        rformapago RECORD;
        rperfiscal RECORD;
        rexistecomp  RECORD;
--VARIABLES  
        elusuario INTEGER;
        respuesta VARCHAR;
        idprecarga BIGINT;
        idcentroprecarga INTEGER;
        viva21 DOUBLE PRECISION DEFAULT 0.0;
        viva105 DOUBLE PRECISION DEFAULT 0.0;
        viva27 DOUBLE PRECISION DEFAULT 0.0;
        vnetoiva105 DOUBLE PRECISION DEFAULT 0.0;
        vnetoiva21 DOUBLE PRECISION DEFAULT 0.0;
        vnetoiva27 DOUBLE PRECISION DEFAULT 0.0;
        vnogravado DOUBLE PRECISION DEFAULT 0.0;
        vpercepciones DOUBLE PRECISION DEFAULT 0.0;
        -- <---> vvv BelenA Agrego
        vimpdebcred DOUBLE PRECISION DEFAULT 0.0;
        vretganancias DOUBLE PRECISION DEFAULT 0.0;
        vrlfpiibbneuquen DOUBLE PRECISION DEFAULT 0.0;
        vrlfpiibbrionegro DOUBLE PRECISION DEFAULT 0.0;
        vrlfpiibbotrajuri DOUBLE PRECISION DEFAULT 0.0;

    
        vretiibb DOUBLE PRECISION DEFAULT 0.0;
        vrlfpdescuento21 DOUBLE PRECISION DEFAULT 0.0;
        vrlfprecargo21 DOUBLE PRECISION DEFAULT 0.0;
        vrlfpivadescuento21 DOUBLE PRECISION DEFAULT 0.0;
        vrlfpivarecargo21 DOUBLE PRECISION DEFAULT 0.0;
        vrlfpdescuento27 DOUBLE PRECISION DEFAULT 0.0;
        vrlfprecargo27 DOUBLE PRECISION DEFAULT 0.0;
        vrlfpivadescuento27 DOUBLE PRECISION DEFAULT 0.0;
        vrlfpivarecargo27 DOUBLE PRECISION DEFAULT 0.0;
        vrlfpdescuento105 DOUBLE PRECISION DEFAULT 0.0;
        vrlfprecargo105 DOUBLE PRECISION DEFAULT 0.0;
        vrlfpivadescuento105 DOUBLE PRECISION DEFAULT 0.0;
        vrlfpivarecargo105 DOUBLE PRECISION DEFAULT 0.0;
        vrlfpexento DOUBLE PRECISION DEFAULT 0.0;
        vrlfpdescuentoexento DOUBLE PRECISION DEFAULT 0.0;
        vrlfprecargoexento DOUBLE PRECISION DEFAULT 0.0;
        vrlfretiva DOUBLE PRECISION DEFAULT 0.0;
        param varchar;
--CURSOR 
       curcentrocostos REFCURSOR;
       currlfactividad REFCURSOR;
       cformapago REFCURSOR;
BEGIN
 
 IF iftableexists('temp_precarga') THEN
  SELECT INTO elusuario * FROM sys_dar_usuarioactual();         
  SELECT INTO rprecarga * FROM temp_precarga;
  IF not (rprecarga.fechaemision > to_char( date_trunc('month',now())-'48month' ::interval-'1sec' ::interval, 'YYYY-MM-DD') 
                         and rprecarga.fechaemision < to_char( date_trunc('day',now())+'1day' ::interval, 'YYYY-MM-DD' ))THEN
                    -- La fecha de emision del comprobante NO PUEDE SER > a la fecha actual + 1 ni menor a 12 meses
      RAISE EXCEPTION 'FECHA EMISION INVALIDA';
  END IF;
--KR 06-06-22 ya se valida en java metodo verificarExisteComprobante en BDRecLibroFac_Precarga, pero agrego aqui tb la validacion

  SELECT INTO rexistecomp * FROM rlf_precarga natural join rlf_precarga_estado       
    where nullvalue(rlfpefechafin) and (tipoestadofactura=12 or tipoestadofactura=13 ) and idprestador=rprecarga.idprestador and clase=rprecarga.clase and idtipocomprobante=rprecarga.idtipocomprobante 
          and numfactura= case when rprecarga.puntodeventa::numeric =0 then (rprecarga.numero::numeric)::text else concat(rprecarga.puntodeventa::numeric,rprecarga.numero) end  
        AND ( idrlfprecarga <> rprecarga.idrlfprecarga  or nullvalue(rprecarga.idrlfprecarga)); 

  IF FOUND THEN 
       RAISE EXCEPTION 'El comprobante ya existe! ( ID-Precarga,%)',concat (rexistecomp.idrlfprecarga ,'-',rexistecomp.idcentrorlfprecarga);
  END IF;

  SELECT INTO rrlfp * FROM rlf_precarga WHERE idrlfprecarga= rprecarga.idrlfprecarga AND idcentrorlfprecarga = rprecarga.idcentrorlfprecarga;
  IF NOT FOUND and rprecarga.accion = 'ingresar' THEN  -- no existe la precarga

     param = contabilidad_periodofiscal_info (concat('{fechaemicioncomp=',rprecarga.fechaemision,',pftipoiva=C}'));  
     EXECUTE sys_dar_filtros(param) INTO rperfiscal;
    INSERT INTO rlf_precarga(fechaemision,letra,numero,obs,rlfpiibbotrajuri,numfactura,rlfpiibbrionegro,idtipocomprobante,netoiva105,netoiva21,condcompra,rlfretiva,netoiva27,percepciones,rlfpdescuentoexento,iva27,fecharecepcion,nogravado,rlfprecargoexento,iva21,fechavenc,retganancias,rlfpexento,rlfpmonto,rlfpiibbneuquen,subtotal,iva105,idprestador,rlfp_movctacte,rlfp_idusuario,puntodeventa,idrecepcionresumen,idcentroregionalresumen,clase,fechaimputacion,tipofactura,montosiniva,impdebcred) 
    VALUES (rprecarga.fechaemision,rprecarga.letra,rprecarga.numero,rprecarga.obs,rprecarga.rlfpiibbotrajuri::numeric,rprecarga.numfactura::bigint,rprecarga.rlfpiibbrionegro::numeric,rprecarga.idtipocomprobante::integer,rprecarga.netoiva105::numeric,rprecarga.netoiva21::numeric,rprecarga.condcompra::integer,rprecarga.retiva::numeric,rprecarga.netoiva27::numeric,rprecarga.percepciones::numeric,rprecarga.descuento::numeric,rprecarga.iva27::numeric,rprecarga.fecharecepcion,rprecarga.nogravado::numeric,rprecarga.recargo::numeric,rprecarga.iva21::numeric,rprecarga.fechavenc,rprecarga.retganancias::numeric,rprecarga.exento::numeric,rprecarga.monto::numeric,rprecarga.rlfpiibbneuquen::numeric,rprecarga.subtotal::numeric,rprecarga.iva105::numeric,rprecarga.idprestador,rprecarga.movctacte,elusuario, rprecarga.puntodeventa, rprecarga.idrecepcionresumen, rprecarga.idcentroregionalresumen,rprecarga.clase,rperfiscal.fechaimputacion,rprecarga.tipofactura,rprecarga.subtotal::numeric, rprecarga.impdebcred::numeric);

    idprecarga = currval('rlf_precarga_idrlfprecarga_seq');
    idcentroprecarga =  centro();
    INSERT INTO rlf_precarga_estado(idrlfprecarga,idcentrorlfprecarga, rlfpedescripcion, rlfpeidusuario,tipoestadofactura)
    VALUES(idprecarga,idcentroprecarga, concat('Precarga realizada el ', now(), '. SP guardar_precarga_comprobante_compra'), elusuario, 12);

    

 ELSE -- el comprobante existe, lo modifico
    UPDATE  rlf_precarga SET fechaemision = rprecarga.fechaemision,
                 fechavenc =  rprecarga.fechavenc,
                 numfactura = rprecarga.numfactura, 
                 rlfpmonto = rprecarga.monto::numeric,
                 idprestador = rprecarga.idprestador,
                             tipofactura = rprecarga.tipofactura,
                             idtipocomprobante = rprecarga.idtipocomprobante::integer,
                             clase = rprecarga.letra ,
                             montosiniva = rprecarga.subtotal::numeric,
                             
                             condcompra =  rprecarga.condcompra::integer,
                             talonario = rprecarga.talonario::integer,
                             iva21 = rprecarga.iva21::numeric,
                             iva105 =  rprecarga.iva105::numeric,
                             iva27 = rprecarga.iva27::numeric,
                             letra = rprecarga.letra,
                             netoiva105 = rprecarga.netoiva105::numeric,
                             netoiva21 =  rprecarga.netoiva21::numeric,
                             netoiva27 =  rprecarga.netoiva27::numeric,
                             nogravado = rprecarga.nogravado::numeric,
                             numero = rprecarga.numero,
                             obs =  rprecarga.obs,
                             percepciones = rprecarga.percepciones::numeric,
                             puntodeventa =  rprecarga.puntodeventa,
                             retganancias = rprecarga.retganancias::numeric,
                             rlfpiibbneuquen = rprecarga.rlfpiibbneuquen::numeric,
                             rlfpiibbrionegro = rprecarga.rlfpiibbrionegro::numeric,
                             rlfpiibbotrajuri = rprecarga.rlfpiibbotrajuri::numeric,
                             rlfretiva = rprecarga.retiva::numeric,
                             subtotal =  rprecarga.subtotal::numeric,
                             tipocambio = rprecarga.tipocambio::numeric,
                             rlfp_idusuariomodifica = elusuario,
                             rlfp_movctacte = rprecarga.movctacte,
                             fechaimputacion = rprecarga.fechaimputacion,
                             idrecepcionresumen =rprecarga.idrecepcionresumen, 
                             idcentroregionalresumen =rprecarga.idcentroregionalresumen,
                             -- <---> BelenA agrego
                             impdebcred=rprecarga.impdebcred::numeric
    WHERE idrlfprecarga= rprecarga.idrlfprecarga AND idcentrorlfprecarga = rprecarga.idcentrorlfprecarga;
    idprecarga = rprecarga.idrlfprecarga;
    idcentroprecarga =  rprecarga.idcentrorlfprecarga;
   
 END IF;

--guardo los cc
    DELETE FROM rlf_precargaitemscentroscosto WHERE idrlfprecarga= idprecarga AND idcentrorlfprecarga = idcentroprecarga;
    OPEN curcentrocostos FOR SELECT * FROM tempprecargacc;
    FETCH curcentrocostos INTO reccentrocosto;
    WHILE  found LOOP
       SELECT INTO relcc * FROM rlf_precargaitemscentroscosto 
                  WHERE idrlfprecarga= reccentrocosto.idrlfprecarga AND  idcentrorlfprecarga=reccentrocosto.idcentrorlfprecarga AND idcentrocosto=reccentrocosto.idcentrocosto AND  idactividad = reccentrocosto.idactividad;
       IF FOUND THEN 
                UPDATE rlf_precargaitemscentroscosto SET iccmonto = reccentrocosto.monto,
                                                         idporcentaje = reccentrocosto.idporcentaje
                WHERE idrlfprecarga= reccentrocosto.idrlfprecarga AND  idcentrorlfprecarga=reccentrocosto.idcentrorlfprecarga AND idcentrocosto=reccentrocosto.idcentrocosto AND  idactividad = reccentrocosto.idactividad;

       ELSE   -- Inserto los centros de costos del comprobante
        INSERT INTO rlf_precargaitemscentroscosto(idrlfprecarga,idcentrorlfprecarga,idcentrocosto,iccmonto,idactividad,catgasto,idporcentaje)
        VALUES(idprecarga,idcentroprecarga,reccentrocosto.idcentrocosto,reccentrocosto.monto,reccentrocosto.idactividad,reccentrocosto.catgasto,reccentrocosto.idporcentaje);
       END IF;
    FETCH curcentrocostos INTO reccentrocosto;
    END LOOP;
    CLOSE curcentrocostos;
    

--guardo las actividades
   DELETE FROM rlf_precargaactividad WHERE idrlfprecarga= idprecarga AND idcentrorlfprecarga = idcentroprecarga;
    OPEN currlfactividad FOR SELECT * FROM tempprecargaactividad;
    FETCH currlfactividad INTO ractividad;
    WHILE  found LOOP

        viva21 = viva21+ractividad.paiva21;
        viva105 = viva105+ractividad.paiva105;
        viva27 = viva27+ractividad.paiva27;
        vnetoiva105 = vnetoiva105+ractividad.panetoiva105;
        vnetoiva21 = vnetoiva21+ractividad.panetoiva21;
        vnetoiva27 = vnetoiva27+ractividad.panetoiva27;
        vnogravado = vnogravado+ractividad.panogravado;
        vpercepciones = vpercepciones+ractividad.papercepciones;
        vretganancias = vretganancias+ractividad.paretganancias;
        vrlfpiibbneuquen = vrlfpiibbneuquen+ractividad.parlfpiibbneuquen;
        vrlfpiibbrionegro = vrlfpiibbrionegro+ ractividad.parlfpiibbrionegro;
        vrlfpiibbotrajuri = vrlfpiibbotrajuri+ractividad.parlfpiibbotrajuri ;
      
        vrlfpdescuento21=vrlfpdescuento21+ractividad.padescuento21;
        vrlfprecargo21=vrlfprecargo21+ractividad.parecargo21;
        vrlfpivadescuento21=vrlfpivadescuento21+ractividad.paivadescuento21;
        vrlfpivarecargo21=vrlfpivarecargo21+ractividad.paivarecargo21;
        vrlfpdescuento27=vrlfpdescuento27+ractividad.padescuento27;
        vrlfprecargo27=vrlfprecargo27+ractividad.parecargo27;
        vrlfpivadescuento27=vrlfpivadescuento27+ractividad.paivadescuento27;
        vrlfpivarecargo27=vrlfpivarecargo27+ractividad.paivarecargo27;
        vrlfpdescuento105=vrlfpdescuento105+ractividad.padescuento105;
        vrlfprecargo105= vrlfprecargo105 +ractividad.parecargo105;
        vrlfpivadescuento105= vrlfpivadescuento105 + ractividad.paivadescuento105;
        vrlfpivarecargo105= vrlfpivarecargo105 +ractividad.paivarecargo105;
        vrlfpexento= vrlfpexento +ractividad.paexento;
        vrlfpdescuentoexento=vrlfpdescuentoexento + ractividad.padescuentoexento;
        vrlfprecargoexento= vrlfprecargoexento + ractividad.parecargoexento;
        vrlfretiva = vrlfretiva + ractividad.paretiva;
        vretiibb = vretiibb + ractividad.parlfpiibbneuquen + ractividad.parlfpiibbrionegro+ractividad.parlfpiibbotrajuri ;
        -- <--->
        vimpdebcred = vimpdebcred+ractividad.paimpdebcred;
 
        SELECT INTO rrlfact * FROM rlf_precargaactividad  
                  WHERE idrlfprecarga= ractividad.idrlfprecarga AND  idcentrorlfprecarga=ractividad.idcentrorlfprecarga AND idactividad = ractividad.idactividad  AND  catgasto = ractividad.catgasto;
       IF FOUND THEN 
           UPDATE rlf_precargaactividad SET paiva21=ractividad.paiva21,
                                            paiva105=ractividad.paiva105,
                                            paiva27=ractividad.paiva27,
                                            panetoiva105=ractividad.panetoiva105,
                                            panetoiva21=ractividad.panetoiva21,
                                            panetoiva27=ractividad.panetoiva27,
                                            panogravado=ractividad.panogravado,
                                            papercepciones=ractividad.papercepciones,
                                            
                                            paretganancias=ractividad.paretganancias,
                                            parlfpiibbneuquen=ractividad.parlfpiibbneuquen,                      
                                            parlfpiibbrionegro=ractividad.parlfpiibbrionegro,
                                            parlfpiibbotrajuri=ractividad.parlfpiibbotrajuri,
                                            padescuento21=ractividad.padescuento21,
                                            parecargo21=ractividad.parecargo21,
                                            paivadescuento21=ractividad.paivadescuento21,
                                            paivarecargo21=ractividad.paivarecargo21,
                                            padescuento27=ractividad.padescuento27,
                                            parecargo27=ractividad.parecargo27, 
                                            paivadescuento27=ractividad.paivadescuento27,
                                            paivarecargo27=ractividad.paivarecargo27,
                                            padescuento105=ractividad.padescuento105,
                                            parecargo105=ractividad.parecargo105,
                                            paivadescuento105=ractividad.paivadescuento105,
                                            paivarecargo105=ractividad.paivarecargo105,
                                            paexento=ractividad.paexento,
                                            padescuentoexento=ractividad.padescuentoexento,
                                            parecargoexento=ractividad.parecargoexento,
                                            paretiva = ractividad.paretiva,
                                            patniva21  = ractividad.patniva21,
                     patiiva21  = ractividad.patiiva21,
                     patniva105  = ractividad.patniva105,
                     patiiva105  = ractividad.patiiva105,
                     patniva27  = ractividad.patniva27,
                     patiiva27  = ractividad.patiiva27,
                     patnexento = ractividad.patnexento,
                     pasubtotal  = ractividad.pasubtotal, 
                     pamontosiniva  = ractividad.pamontosiniva,
                     pamonto = ractividad.pamonto,
                     -- <--->
                     paimpdebcred=ractividad.paimpdebcred
           WHERE idrlfprecarga= ractividad.idrlfprecarga AND  idcentrorlfprecarga=ractividad.idcentrorlfprecarga AND idactividad = ractividad.idactividad  AND  catgasto = ractividad.catgasto;

       ELSE   
           INSERT INTO rlf_precargaactividad(idrlfprecarga,idcentrorlfprecarga,paiva21,paiva105,paiva27,panetoiva105,panetoiva21,panetoiva27,panogravado,papercepciones,paretganancias,parlfpiibbneuquen,                        
                                  parlfpiibbrionegro,parlfpiibbotrajuri,padescuento21,parecargo21,paivadescuento21,paivarecargo21,padescuento27,parecargo27, paivadescuento27,paivarecargo27,padescuento105
                                  ,parecargo105,paivadescuento105,paivarecargo105,paexento,padescuentoexento,parecargoexento,idactividad,catgasto ,paretiva 
                                  ,patniva21,patiiva21,patniva105,patiiva105,patniva27,patiiva27,patnexento,pasubtotal,pamontosiniva,pamonto, paimpdebcred)       
        VALUES (idprecarga,idcentroprecarga,ractividad.paiva21,ractividad.paiva105,ractividad.paiva27,ractividad.panetoiva105,ractividad.panetoiva21,ractividad.panetoiva27,ractividad.panogravado,ractividad.papercepciones,ractividad.paretganancias
        ,ractividad.parlfpiibbneuquen,ractividad.parlfpiibbrionegro,ractividad.parlfpiibbotrajuri,ractividad.padescuento21,ractividad.parecargo21,ractividad.paivadescuento21,ractividad.paivarecargo21,ractividad.padescuento27
        ,ractividad.parecargo27, ractividad.paivadescuento27,ractividad.paivarecargo27,ractividad.padescuento105,ractividad.parecargo105,ractividad.paivadescuento105,ractividad.paivarecargo105,ractividad.paexento,ractividad.padescuentoexento
        ,ractividad.parecargoexento,ractividad.idactividad,ractividad.catgasto ,ractividad.paretiva
        ,ractividad.patniva21,ractividad.patiiva21,ractividad.patniva105,ractividad.patiiva105,ractividad.patniva27,ractividad.patiiva27,ractividad.patnexento,ractividad.pasubtotal,ractividad.pamontosiniva,ractividad.pamonto,ractividad.paimpdebcred);
       END IF;
 
    
    FETCH currlfactividad INTO ractividad;
    END LOOP;
    CLOSE currlfactividad;

--desactivo las actividades que se eliminaron 
   

  
   UPDATE  rlf_precarga SET  iva21 = viva21,
                             iva105 =  viva105,
                             iva27 = viva27,
                             netoiva105 = vnetoiva105,
                             netoiva21 =  vnetoiva21,
                             netoiva27 =  vnetoiva27,
                             nogravado = vnogravado,
                             percepciones = vpercepciones,
                             retganancias = vretganancias,
                             rlfpiibbneuquen = vrlfpiibbneuquen,
                             rlfpiibbrionegro = vrlfpiibbrionegro,
                             rlfpiibbotrajuri = vrlfpiibbotrajuri, 
                             rlfpdescuento21= vrlfpdescuento21,
                             rlfprecargo21 = vrlfprecargo21,
                             rlfpivadescuento21 = vrlfpivadescuento21,
                             rlfpivarecargo21=vrlfpivarecargo21,
                             rlfpdescuento27=vrlfpdescuento27,
                             rlfprecargo27=vrlfprecargo27, 
                             rlfpivadescuento27=vrlfpivadescuento27,
                             rlfpivarecargo27=vrlfpivarecargo27,
                             rlfpdescuento105=vrlfpdescuento105,
                             rlfprecargo105= vrlfprecargo105 ,
                             rlfpivadescuento105= vrlfpivadescuento105 ,
                             rlfpivarecargo105= vrlfpivarecargo105 ,
                             rlfpexento= vrlfpexento,
                             rlfpdescuentoexento=vrlfpdescuentoexento,
                             rlfprecargoexento= vrlfprecargoexento,
                             rlfretiva = vrlfretiva,
                             retiibb = vretiibb, 
                             subtotal = vnetoiva105 +vnetoiva21 + vnetoiva27,
                             impdebcred = vimpdebcred
/*,                          rlfpmonto = vnetoiva105 +vnetoiva21 + vnetoiva27 +  vrlfpexento + vnogravado   
                                        + viva105+viva21+viva27 - vrlfpdescuento21- vrlfpivadescuento21-vrlfpdescuento27-vrlfpivadescuento27-vrlfpdescuento105- vrlfpivadescuento105 -vrlfpdescuentoexento+
vrlfprecargo27 + vrlfprecargo105 +vrlfprecargo21 +
vrlfpivarecargo27+vrlfpivarecargo105+vrlfpivarecargo21 +
                                          vrlfprecargoexento+vrlfpiibbneuquen +vrlfpiibbrionegro +vrlfpiibbotrajuri+vpercepciones+vrlfretiva*/
    WHERE idrlfprecarga=idprecarga AND idcentrorlfprecarga =  idcentroprecarga;
 
 else
  RAISE EXCEPTION 'R-001, No existen datos para sugerir información. ';
 end if;


 -- BelenA 04-06-24 como ahora puedo tener mas de una forma de pago, elimino las que tenia y agrego las nuevas
 --comento el update para que solo me haga los inserts


 DELETE FROM rlf_precarga_formpago WHERE idrlfprecarga= idprecarga AND idcentrorlfprecarga = idcentroprecarga; 
  OPEN cformapago FOR SELECT * FROM tempprecargafp;
  FETCH cformapago INTO rformapago;
    WHILE  found LOOP
--KR 26-09-22 por ahora dejo que solo tenga una forma de pago, el modelo permite mas de una pero hay que permitir que el sistema las manipule
/*       SELECT INTO relcc * FROM rlf_precarga_formpago WHERE idrlfprecarga= rformapago.idrlfprecarga and idcentrorlfprecarga = rformapago.idcentrorlfprecarga;
       IF FOUND THEN 
                UPDATE rlf_precarga_formpago SET rlfpfpmonto = rformapago.rlfpfpmonto,
                                                 idvalorescaja = CASE WHEN nullvalue(rformapago.idvalorescaja) THEN 3 else rformapago.idvalorescaja end 
                WHERE idrlfprecarga= rformapago.idrlfprecarga and idcentrorlfprecarga = rformapago.idcentrorlfprecarga;

       ELSE   -- Inserto los centros de costos del comprobante
*/      INSERT INTO rlf_precarga_formpago(idrlfprecarga,idcentrorlfprecarga,idvalorescaja,rlfpfpmonto)
        VALUES(idprecarga,idcentroprecarga, CASE WHEN nullvalue(rformapago.idvalorescaja) THEN 3 else rformapago.idvalorescaja end ,rformapago.rlfpfpmonto);
--       END IF;
    FETCH cformapago INTO rformapago;
    END LOOP;
    CLOSE cformapago;
  
  

return concat(idprecarga,'|', idcentroprecarga); 
END;$function$
