CREATE OR REPLACE FUNCTION public.mesaentrada_modificarrecepcion()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Se ingresan / modifica / elimina los datos de una recepción */

DECLARE
codcomprobante BIGINT;
codrecepcion integer;
regtemp record;
rcomp record;
idcentrorecepcion integer;
elnumeroregistro varchar;
respuesta  varchar;
curcentrocostos refcursor;
reccentrocosto RECORD;
rresumen RECORD;
rauditada RECORD;
elem RECORD;
esderesumen RECORD;
vTipomov char;
auxx integer;

--VARIABLES
  elusuario INTEGER; 

BEGIN

--KR 05-02-20 Guardamos el ULTIMO usuario que modifica el comprobante
       SELECT INTO elusuario * FROM sys_dar_usuarioactual();       

       vTipomov='N';
       elnumeroregistro = '';
       SELECT INTO regtemp * FROM temprecepcion ;
       IF FOUND THEN
       /****** 19-02-2019 *******/

         SELECT INTO rcomp *
         FROM contabilidad_periodofiscal
         NATURAL JOIN contabilidad_periodofiscalreclibrofact
         JOIN reclibrofact using (idrecepcion,idcentroregional)
         WHERE 
/*KR 28-10-20 Descomento el not...no entiendo pq estaba comentado. De esta forma no pueden modificar un comprobante aun con la liquidacion abierta*/
              not nullvalue(pfcerrado) and idrecepcion = regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional;

         IF NOT FOUND THEN 
            -- El comprobante NO se encuentra en una liquidacion de iva cerrada
        /******19-02-2019  *******/

    if(regtemp.idrecepcion <> 0) THEN   
        -- Me fijo si el comprobante ya fue sincronizado a Multivac (idcomprobantemultivac<>null)
           vTipomov='U';
                  select into auxx 1
                         from mapeocompcompras
                         WHERE idrecepcion =regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional and nullvalue(idcomprobantemultivac);
                  if found then
                     vTipomov='I';
                  end if;

                  UPDATE mapeocompcompras
                         SET tipomov=vTipomov, update='true', fechaupdate=current_timestamp
                         WHERE idrecepcion =regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional;
                         
                  UPDATE recepcion SET idtiporecepcion= regtemp.idtiporecepcion ,fecha = regtemp.fecharecepcion
                         WHERE idrecepcion =regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional;

                  SELECT INTO elem idrecepcionresumen, idcentroregionalresumen 
                          FROM reclibrofact 
                          WHERE idrecepcion = regtemp.idrecepcion and idcentroregional = regtemp.idcentroregional; 
                
                 codrecepcion =  regtemp.idrecepcion;
                 idcentrorecepcion = regtemp.idcentroregional;

                 IF iftableexists('temp_actividad') THEN

-- Primero elimino todas las actividades de un comprobante
           DELETE FROM reclibrofact_catgastoactividad WHERE  idrecepcion = codrecepcion AND idcentroregional =  idcentrorecepcion;
                
                   INSERT INTO reclibrofact_catgastoactividad(idrecepcion,idcentroregional,rlfaiva21 ,rlfaiva105 ,rlfaiva27,rlfanetoiva105,rlfanetoiva21 ,rlfanetoiva27,rlfanogravado ,rlfapercepciones,rlfaretganancias ,rlfarlfpiibbneuquen ,
    rlfarlfpiibbrionegro,rlfarlfpiibbotrajuri ,rlfadescuento21 ,rlfarecargo21 ,rlfaivadescuento21 ,rlfaivarecargo21 ,rlfadescuento27 ,rlfarecargo27 ,rlfaivadescuento27 ,rlfaivarecargo27 ,rlfadescuento105 ,
    rlfarecargo105 ,rlfaivadescuento105 ,rlfaivarecargo105 ,rlfaexento ,rlfadescuentoexento ,rlfarecargoexento ,idactividad ,catgasto,rlfaretiva, rlfaimpdebcred)
        
                 SELECT codrecepcion,idcentrorecepcion, rlfaiva21 ,rlfaiva105 ,rlfaiva27,rlfanetoiva105,rlfanetoiva21 ,rlfanetoiva27,rlfanogravado ,rlfapercepciones,rlfaretganancias ,rlfarlfpiibbneuquen ,
    rlfarlfpiibbrionegro,rlfarlfpiibbotrajuri ,rlfadescuento21 ,rlfarecargo21 ,rlfaivadescuento21 ,rlfaivarecargo21 ,rlfadescuento27 ,rlfarecargo27 ,rlfaivadescuento27 ,rlfaivarecargo27 ,rlfadescuento105 ,
    rlfarecargo105 ,rlfaivadescuento105 ,rlfaivarecargo105 ,rlfaexento ,rlfadescuentoexento ,rlfarecargoexento ,idactividad ,catgasto , rlfaretiva, rlfaimpdebcred
               FROM temp_actividad 
               WHERE idrlfprecarga=regtemp.idrlfprecarga AND idcentrorlfprecarga=regtemp.idcentrorlfprecarga;
                 END IF;
 
                 IF iftableexists('tempactividadcentroscosto') THEN

-- Primero elimino todos los centros de costo de todas las actividades de un comprobante
           DELETE FROM reclibrofact_actividadcentroscosto WHERE idrecepcion = codrecepcion AND idcentroregional =  idcentrorecepcion;
                   INSERT INTO reclibrofact_actividadcentroscosto(idrecepcion,idcentroregional,idcentrocosto ,accmonto ,idactividad ,catgasto ,accidporcentaje)
        
                   SELECT codrecepcion,idcentrorecepcion, idcentrocosto ,accmonto ,idactividad ,catgasto ,accidporcentaje
                    FROM tempactividadcentroscosto 
                    WHERE idrlfprecarga=regtemp.idrlfprecarga AND idcentrorlfprecarga=regtemp.idcentrorlfprecarga;
                 END IF;
  
                 IF iftableexists('temprlfformpago') THEN

-- Primero elimino todas las formas de pago de un comprobante 
               DELETE FROM reclibrofact_formpago WHERE  idrecepcion = codrecepcion AND idcentroregional =  idcentrorecepcion;
                   INSERT INTO reclibrofact_formpago(idrecepcion,idcentroregional,rlffpmonto ,idvalorescaja  )
        
                   SELECT codrecepcion,idcentrorecepcion, rlffpmonto ,idvalorescaja  
               FROM temprlfformpago 
               WHERE idrlfprecarga=regtemp.idrlfprecarga AND idcentrorlfprecarga=regtemp.idcentrorlfprecarga;
                 END IF;

                  /* LO AGREGO HASTA PONER LA VERSION FINAL EN PRODUCCIOM*/    
                  IF existecolumtemp('temprecepcion', 'idrlfprecarga') THEN
                         UPDATE reclibrofact SET fechavenc =  regtemp.fechavenc, numfactura = regtemp.numfactura, monto = regtemp.monto,
                               numeroregistro =  regtemp.numeroregistro,idprestador = regtemp.idprestador,
                              idlocalidad = regtemp.idlocalidad,idtipocomprobante = regtemp.idtipocomprobante,
                              idcentroregionalresumen = regtemp.idcentroregionalresumen,
                              idrecepcionresumen = regtemp.idrecepcionresumen,
                              anio =  regtemp.anio ,
                              clase = regtemp.clase ,
                              montosiniva = regtemp.montosiniva,
                              recargo = regtemp.recargo,
                              exento = regtemp.exento,
                              fechaemision = regtemp.fechaemision,
                              fechaimputacion = regtemp.fechaimputacion,
                              catgasto = regtemp.catgasto,
                              condcompra =  regtemp.condcompra,
                              talonario = regtemp.talonario,
                              iva21 = regtemp.iva21,
                              iva105 =  regtemp.iva105,
                              iva27 = regtemp.iva27,
                              letra = regtemp.letra,
                              netoiva105 = regtemp.netoiva105,
                              netoiva21 =  regtemp.netoiva21,
                              netoiva27 =  regtemp.netoiva27,
                              nogravado = regtemp.nogravado,
                              numero = regtemp.numero,
                              obs =  regtemp.obs,
                              percepciones = regtemp.percepciones,
                              puntodeventa =  regtemp.puntodeventa,
                              retganancias = regtemp.retganancias,
--                              retiibb = regtemp.retiibb,
retiibb =  (regtemp.rlfpiibbneuquen + regtemp.rlfpiibbrionegro + regtemp.rlfpiibbotrajuri) ,
                              retiva = regtemp.retiva,
                              subtotal =  regtemp.subtotal,
                              tipocambio = regtemp.tipocambio,
                              tipofactura = regtemp.tipofactura,
                              rlfpiibbneuquen = regtemp.rlfpiibbneuquen,
                              rlfpiibbrionegro = regtemp.rlfpiibbrionegro,
idactividad = regtemp.idactividad,
                              rlfpiibbotrajuri = regtemp.rlfpiibbotrajuri ,
                              rlfdescuento21 = regtemp.rlfdescuento21,
                            rlfrecargo21 = regtemp.rlfrecargo21,
                            rlfivadescuento21 = regtemp.rlfivadescuento21,
                            rlfivarecargo21 = regtemp.rlfivarecargo21, 
                                rlfdescuento27  = regtemp.rlfdescuento27, 
                                rlfrecargo27 = regtemp.rlfrecargo27,
                            rlfivadescuento27 = regtemp.rlfivadescuento27,
                            rlfivarecargo27 = regtemp.rlfivarecargo27, 
                                rlfdescuento105 = regtemp.rlfdescuento105, 
                                rlfrecargo105 = regtemp.rlfrecargo105,
                            rflivadescuento105= regtemp.rflivadescuento105,
                            rlfivarecargo105 = regtemp.rlfivarecargo105,
                            rlftotaliva = regtemp.rlftotaliva,
                    
					-- VAS 21-02-23 agrego el campo descuento que contiene el descuento excento        descuento  =  regtemp.rlfdescuento21+ regtemp.rlfdescuento27+ regtemp.rlfdescuento105
					 descuento  =  regtemp.rlfdescuento21+ regtemp.rlfdescuento27+ regtemp.rlfdescuento105+ regtemp.descuento,
					 
                            rlftotalimpuesto = regtemp.rlftotalimpuesto,
                            idrlfprecarga = regtemp.idrlfprecarga,
                            idcentrorlfprecarga = regtemp.idcentrorlfprecarga,
--KR 05-02-20 guardo el usuario que modifica 21/04/23 puse aqui el update
                                idusuariomodifica= elusuario,
                                -- <---> BelenA agrego:
                                impdebcred = regtemp.impdebcred
                           WHERE idrecepcion = regtemp.idrecepcion and idcentroregional = regtemp.idcentroregional;
                 ELSE 
                          UPDATE reclibrofact SET fechavenc =  regtemp.fechavenc, numfactura = regtemp.numfactura, monto = regtemp.monto,
                               numeroregistro =  regtemp.numeroregistro,idprestador = regtemp.idprestador,
                              idlocalidad = regtemp.idlocalidad,idtipocomprobante = regtemp.idtipocomprobante,
                              idcentroregionalresumen = regtemp.idcentroregionalresumen,
                              idrecepcionresumen = regtemp.idrecepcionresumen,
                              anio =  regtemp.anio ,
                              clase = regtemp.clase ,
                              montosiniva = regtemp.montosiniva,
                              descuento = regtemp.descuento,
                              recargo = regtemp.recargo,
                              exento = regtemp.exento,
                              fechaemision = regtemp.fechaemision,
                              fechaimputacion = regtemp.fechaimputacion,
                              catgasto = regtemp.catgasto,
                              condcompra =  regtemp.condcompra,
                              talonario = regtemp.talonario,
                              iva21 = regtemp.iva21,
                              iva105 =  regtemp.iva105,
                              iva27 = regtemp.iva27,
                              letra = regtemp.letra,
                              netoiva105 = regtemp.netoiva105,
                              netoiva21 =  regtemp.netoiva21,
                              netoiva27 =  regtemp.netoiva27,
                              nogravado = regtemp.nogravado,
                              numero = regtemp.numero,
                              obs =  regtemp.obs,
                              percepciones = regtemp.percepciones,
                              puntodeventa =  regtemp.puntodeventa,
                              retganancias = regtemp.retganancias,
--                              retiibb = regtemp.retiibb,
retiibb =  (regtemp.rlfpiibbneuquen + regtemp.rlfpiibbrionegro + regtemp.rlfpiibbotrajuri) ,
                              retiva = regtemp.retiva,
                              subtotal =  regtemp.subtotal,
                              tipocambio = regtemp.tipocambio,
                              tipofactura = regtemp.tipofactura,
                              rlfpiibbneuquen = regtemp.rlfpiibbneuquen,
                              rlfpiibbrionegro = regtemp.rlfpiibbrionegro,
idactividad = regtemp.idactividad,
                              rlfpiibbotrajuri = regtemp.rlfpiibbotrajuri ,
                              --KR 05-02-20 guardo el usuario que modifica 21/04/23 puse aqui el update
                                idusuariomodifica= elusuario,
                                -- <---> BelenA agrego:
                                impdebcred = regtemp.impdebcred
                           WHERE idrecepcion = regtemp.idrecepcion and idcentroregional = regtemp.idcentroregional;
                  END IF;
                  
                  elnumeroregistro = concat(regtemp.numeroregistro , '/', regtemp.anio);

    -- CS 2016-11-18               
    -- Actualizo el Resumen de la Factura, porque puede ser que la misma ya no este vinculada a éste
                  UPDATE reclibrofact set monto = (SELECT sum(monto) from reclibrofact WHERE idrecepcionresumen=elem.idrecepcionresumen AND idcentroregionalresumen= elem.idcentroregionalresumen)
                  WHERE idrecepcion = elem.idrecepcionresumen and idcentroregional = elem.idcentroregionalresumen;
 
               SELECT INTO esderesumen * 
                  FROM reclibrofact 
                  WHERE NOT nullvalue(idrecepcionresumen) AND not nullvalue(idcentroregionalresumen) AND
                  idrecepcion=regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional;                  

                    
                  IF FOUND THEN --el comprobante pertenece a un resumen
                     
                     UPDATE reclibrofact SET monto = (SELECT sum(monto)
                                                      FROM reclibrofact
                     WHERE idrecepcionresumen=esderesumen.idrecepcionresumen AND idcentroregionalresumen= esderesumen.idcentroregionalresumen) 
                     WHERE idrecepcion = esderesumen.idrecepcionresumen AND idcentroregional= esderesumen.idcentroregionalresumen;
                  END IF; 
                   IF(regtemp.idtiporecepcion = 6 )THEN 
        -- Primero elimino todos los centros de costo de un comprobante
           DELETE FROM reclibrofactitemscentroscosto WHERE  idrecepcion = codrecepcion AND idcentroregional = idcentrorecepcion;
                   OPEN curcentrocostos FOR SELECT * FROM temprecepcioncc;
            FETCH curcentrocostos INTO reccentrocosto;
            WHILE  found LOOP
               -- Inserto los centros de costos del comprobante
               INSERT INTO reclibrofactitemscentroscosto(idrecepcion,idcentroregional,idcentrocosto,monto)
               VALUES(codrecepcion,idcentrorecepcion,reccentrocosto.idcentrocosto,reccentrocosto.monto);
             FETCH curcentrocostos INTO reccentrocosto;
            END LOOP;
            CLOSE curcentrocostos;
                END IF;
                IF(regtemp.idtiporecepcion = 3 )THEN -- Se esta dando de alta un resumen
        -- Primero elimino todos los centros de costo de un comprobante
           DELETE FROM fechasfact WHERE  idrecepcion = codrecepcion AND idcentroregional = idcentrorecepcion;
                   OPEN curcentrocostos FOR SELECT * FROM temprecepcionfechas;
           FETCH curcentrocostos INTO reccentrocosto;
           WHILE  found LOOP
           -- Inserto los centros de costos del comprobante
            INSERT INTO fechasfact(idrecepcion,idcentroregional,fechainicio,fechafin)
            VALUES(codrecepcion,idcentrorecepcion,reccentrocosto.fechainicio,reccentrocosto.fechafin);
            FETCH curcentrocostos INTO reccentrocosto;
            END LOOP;
            CLOSE curcentrocostos;
                 END IF;  

             
  

    
      

            
       END IF;
         
 --KR 05-02-20 guardo el usuario que modifica 
-- KR 21-04-23 updateo antes con el usuario
 --    UPDATE reclibrofact SET idusuariomodifica= elusuario WHERE idrecepcion = regtemp.idrecepcion and idcentroregional = regtemp.idcentroregional;

     ELSE
            -- Si lo esta, doy un error 
            RAISE EXCEPTION 'El comprobante se encuentra vinculado a una liquidacion IVA CERRADA !!!  ' USING HINT = 'Informar al Sector Contable.';
     END IF;-- El comprobante no se encuentra en una liq iva cerrada

END IF;

RETURN elnumeroregistro;
END;$function$
