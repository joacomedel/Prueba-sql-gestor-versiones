CREATE OR REPLACE FUNCTION public.insertarrecepcion()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Se ingresan los datos de la recepcionÂº*/

DECLARE
codcomprobante BIGINT;
codrecepcion integer;
regtemp record;
idcentrorecepcion integer;
elnumeroregistro varchar;
respuesta  varchar;
curcentrocostos refcursor;
reccentrocosto RECORD;
elem RECORD;
esderesumen RECORD;
vTipomov char;
auxx integer;

BEGIN
                   
       elnumeroregistro = '';
       SELECT INTO regtemp * FROM temprecepcion ;
       IF FOUND THEN
       /* -- Lo comento porque me parece que está demás. Cristian: febrero 2012
       IF (regtemp.idtipocomprobante = 7) THEN 
       -- Si es una liquidacion, se debe guardar como una factura
       regtemp.idtipocomprobante = 1;
       END IF;
       */
            if(regtemp.idrecepcion = 0 ) THEN
            
                   INSERT INTO comprobante(fechahora) VALUES (CURRENT_TIMESTAMP);
                   codcomprobante = currval('public.comprobante_idcomprobante_seq');
                   INSERT INTO recepcion(idrecepcion, idcentroregional,idcomprobante,idtiporecepcion,fecha)
                   VALUES(nextval('public.recepcion_idrecepcion_seq'),centro(),codcomprobante,regtemp.idtiporecepcion,regtemp.fecharecepcion);
                   codrecepcion = currval('public.recepcion_idrecepcion_seq');
                   idcentrorecepcion =centro();
                   
                   INSERT INTO mapeocompcompras (idrecepcion)
                   VALUES (codrecepcion);
                   
                   if(regtemp.idtiporecepcion = 6)THEN
                              INSERT INTO reclibrofact (idrecepcion, idcentroregional,numeroregistro,anio, fechavenc,numfactura, monto,idprestador,
                              idlocalidad,idtipocomprobante,idcentroregionalresumen,idrecepcionresumen,clase,montosiniva,
                              descuento,recargo,exento,fechaemision,fechaimputacion,catgasto,condcompra,
                              talonario,iva21,iva105,iva27,letra,netoiva105,netoiva21,netoiva27,nogravado,numero
                              ,obs,percepciones
                              ,puntodeventa,retganancias
                              ,retiibb,retiva,subtotal,tipocambio,tipofactura
                              )VALUES(codrecepcion,idcentrorecepcion,nextval('public.reclibrofact_numeroregistro_seq'),date_part('year'::text, ('now'::text)::date),regtemp.fechavenc
                              ,regtemp.numfactura,regtemp.monto, regtemp.idprestador,
                              regtemp.idlocalidad,regtemp.idtipocomprobante, regtemp.idcentroregionalresumen, regtemp.idrecepcionresumen, regtemp.clase,regtemp.montosiniva,
                              regtemp.descuento, regtemp.recargo,regtemp.exento, regtemp.fechaemision, regtemp.fechaimputacion, regtemp.catgasto,  regtemp.condcompra,
                              regtemp.talonario,  regtemp.iva21, regtemp.iva105,regtemp.iva27, regtemp.letra, regtemp.netoiva105, regtemp.netoiva21, regtemp.netoiva27,
                              regtemp.nogravado,  lpad(regtemp.numero, 8, '0'),
                              regtemp.obs,  regtemp.percepciones,  regtemp.puntodeventa, regtemp.retganancias,
                              regtemp.retiibb, regtemp.retiva,  regtemp.subtotal,  regtemp.tipocambio,  regtemp.tipofactura
                              );

                              elnumeroregistro = concat(currval('public.reclibrofact_numeroregistro_seq'), '/',date_part('year'::text, ('now'::text)::date));
                             
                             UPDATE temprecepcion SET idrecepcion=codrecepcion,idcentroregional= idcentrorecepcion;
                  END IF;
                  SELECT INTO esderesumen * 
                  FROM reclibrofact 
                  WHERE NOT nullvalue(idrecepcionresumen) AND not nullvalue(idcentroregionalresumen) AND
                  idrecepcion=codrecepcion AND idcentroregional = idcentrorecepcion;                  

                    
                  IF FOUND THEN --el comprobante pertenece a un resumen
                     
                     UPDATE reclibrofact SET monto = (SELECT sum(monto)
                                                      FROM reclibrofact
                     WHERE idrecepcionresumen=esderesumen.idrecepcionresumen AND idcentroregionalresumen= esderesumen.idcentroregionalresumen) 
                     WHERE idrecepcion = esderesumen.idrecepcionresumen AND idcentroregional= esderesumen.idcentroregionalresumen;

                  END IF; 

            ELSE
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
                              retiibb = regtemp.retiibb,
                              retiva = regtemp.retiva,
                              subtotal =  regtemp.subtotal,
                              tipocambio = regtemp.tipocambio,
                              tipofactura = regtemp.tipofactura
                           WHERE idrecepcion = regtemp.idrecepcion and idcentroregional = regtemp.idcentroregional;
                  codrecepcion =  regtemp.idrecepcion;
                  idcentrorecepcion = regtemp.idcentroregional;
                  elnumeroregistro = concat(regtemp.numeroregistro , '/', regtemp.anio);


-- CS 2016-11-18               
-- Actualizo el Resumen de la Factura, porque puede ser que la misma ya no este vinculada a éste
                  UPDATE reclibrofact set monto = (SELECT sum(monto) from reclibrofact WHERE idrecepcionresumen=elem.idrecepcionresumen AND idcentroregionalresumen= elem.idcentroregionalresumen)
                  WHERE idrecepcion = elem.idrecepcionresumen and idcentroregional = elem.idcentroregionalresumen;
-- //////////////
         
                  
 
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
END IF;
            -- CS 2016-11-21 Este control ahora se hace en el sp insertarfactura           
--            if ((regtemp.catgasto=4 OR regtemp.catgasto=6) OR regtemp.paraauditoria ) THEN

              SELECT INTO respuesta * FROM insertarfactura(codrecepcion, idcentrorecepcion );

--            end if;
--------------------------------------------------------------------------------
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
--KR 30-01-15 corroboro si además debo hacer un movimiento en la cuenta corriente, dada la categoria de gasto
           IF (regtemp.movctacte) THEN 
              PERFORM ingresarmovimientoctactecatgasto();
           END IF; 
RETURN elnumeroregistro;
END;
$function$
