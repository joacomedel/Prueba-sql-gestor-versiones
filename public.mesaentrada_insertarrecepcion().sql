CREATE OR REPLACE FUNCTION public.mesaentrada_insertarrecepcion()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Se ingresan / modifica / elimina los datos de una recepción */

/* Se ingresan / modifica / elimina los datos de una recepción */

/* Se ingresan / modifica / elimina los datos de una recepción */

DECLARE
codcomprobante BIGINT;
codrecepcion integer;
regtemp record;
idcentrorecepcion integer;
elnumeroregistro varchar;
respuesta  varchar;
curcentrocostos refcursor;
reccentrocosto RECORD;
rresumen RECORD;
rauditada RECORD;
elem RECORD;
esderesumen RECORD;
rtempoformapago RECORD;
rformapago RECORD;

vTipomov char;
auxx integer;
param varchar;
rperfiscal RECORD;

--VARIABLES
  elusuario INTEGER; 

--CURSOR
cformapago REFCURSOR;

BEGIN
        
--KR 05-02-20 Guardamos el usuario que da de alta el comprobante
       SELECT INTO elusuario * FROM sys_dar_usuarioactual();           
       elnumeroregistro = '';
       SELECT INTO regtemp * FROM temprecepcion ;
       IF FOUND THEN
        if(regtemp.idrecepcion = 0 ) THEN
                   INSERT INTO comprobante(fechahora) VALUES (CURRENT_TIMESTAMP);
                   codcomprobante = currval('public.comprobante_idcomprobante_seq');
                   INSERT INTO recepcion(idrecepcion, idcentroregional,idcomprobante,idtiporecepcion,fecha)
                   VALUES(nextval('public.recepcion_idrecepcion_seq'),centro(),codcomprobante,regtemp.idtiporecepcion,regtemp.fecharecepcion);
                   codrecepcion = currval('public.recepcion_idrecepcion_seq');
                   idcentrorecepcion =centro();

                   IF iftableexists('temprlfformpago') THEN
                       
                       RAISE NOTICE 'atemprlfformpago (%,%)',codrecepcion ,idcentrorecepcion ;

                    -- BelenA: Abro un cursor para las formas de pago (Puede haber mas de 1 FP)
                    OPEN cformapago FOR SELECT * FROM temprlfformpago;
                      FETCH cformapago INTO rformapago;
                        WHILE  found LOOP
                        DELETE FROM reclibrofact_formpago WHERE idrecepcion=codrecepcion AND idcentroregional=idcentrorecepcion;

                        SELECT INTO rtempoformapago * 
                        FROM reclibrofact
                        NATURAL JOIN reclibrofact_formpago 
                        WHERE idrlfprecarga=regtemp.idrlfprecarga AND idcentrorlfprecarga=regtemp.idcentrorlfprecarga
                        AND   idvalorescaja = rformapago.idvalorescaja;

                        IF FOUND THEN
                        -- Si ya existe el elemento en reclibrofact y tiene la forma de pago que quiero, la modifico, no guardo otra
                            UPDATE reclibrofact
                            SET rlffpmonto = temprlfformpago.rlffpmonto
                            WHERE idrecepcion=rtempoformapago.idrecepcion AND idcentroregional=rtempoformapago.idcentroregional
                            AND idvalorescaja = rtempoformapago.idvalorescaja;

                        ELSE
                        -- Si no existe, agrego la forma de pago nueva
                          INSERT INTO reclibrofact_formpago(idrecepcion,idcentroregional,rlffpmonto ,idvalorescaja  )
                               SELECT codrecepcion,idcentrorecepcion, rlffpmonto ,idvalorescaja  
                                FROM temprlfformpago 
                               WHERE idrlfprecarga=regtemp.idrlfprecarga AND idcentrorlfprecarga=regtemp.idcentrorlfprecarga;
                        END IF;
                        FETCH cformapago INTO rformapago;
                        END LOOP;
                        CLOSE cformapago;
/*
                       INSERT INTO reclibrofact_formpago(idrecepcion,idcentroregional,rlffpmonto ,idvalorescaja  )
                       SELECT codrecepcion,idcentrorecepcion, rlffpmonto ,idvalorescaja  
                   FROM temprlfformpago 
                       WHERE idrlfprecarga=regtemp.idrlfprecarga AND idcentrorlfprecarga=regtemp.idcentrorlfprecarga;
*/

                        -- BelenA 03-06-24 Me fijo si el monto del total y el de la suma de las formas de pago coincide, sino salta un error
                        SELECT into rtempoformapago sum(rlffpmonto) as sumamonto 
                        FROM temprlfformpago; 

                        IF  (rtempoformapago.sumamonto <> regtemp.monto)  THEN
                        RAISE EXCEPTION 'EL MONTO DE LA PRECARGA Y LA SUMA DE LAS FORMAS DE PAGO NO COINCIDEN  % <-> %', regtemp.monto, rtempoformapago.sumamonto;
                        END IF;

                    END IF;    


                     
                   --KR 11-09-20 Guardo la info en las nuevas tablas
                    IF iftableexists('temp_actividad') THEN
                       INSERT INTO reclibrofact_catgastoactividad(idrecepcion,idcentroregional,rlfaiva21 ,rlfaiva105 ,rlfaiva27,rlfanetoiva105,rlfanetoiva21 ,rlfanetoiva27,rlfanogravado ,rlfapercepciones,rlfaretganancias ,rlfarlfpiibbneuquen ,
    rlfarlfpiibbrionegro,rlfarlfpiibbotrajuri ,rlfadescuento21 ,rlfarecargo21 ,rlfaivadescuento21 ,rlfaivarecargo21 ,rlfadescuento27 ,rlfarecargo27 ,rlfaivadescuento27 ,rlfaivarecargo27 ,rlfadescuento105 ,   rlfarecargo105 ,rlfaivadescuento105 ,rlfaivarecargo105 ,rlfaexento ,rlfadescuentoexento ,rlfarecargoexento ,idactividad ,catgasto,rlfaretiva,rlfaimpdebcred)
        
                      SELECT codrecepcion,idcentrorecepcion, rlfaiva21 ,rlfaiva105 ,rlfaiva27,rlfanetoiva105,rlfanetoiva21 ,rlfanetoiva27,rlfanogravado ,rlfapercepciones,rlfaretganancias ,rlfarlfpiibbneuquen ,
    rlfarlfpiibbrionegro,rlfarlfpiibbotrajuri ,rlfadescuento21 ,rlfarecargo21 ,rlfaivadescuento21 ,rlfaivarecargo21 ,rlfadescuento27 ,rlfarecargo27 ,rlfaivadescuento27 ,rlfaivarecargo27 ,rlfadescuento105 ,rlfarecargo105 ,rlfaivadescuento105 ,rlfaivarecargo105 ,rlfaexento ,rlfadescuentoexento ,rlfarecargoexento ,idactividad ,catgasto , rlfaretiva, rlfaimpdebcred
                  FROM temp_actividad 
                   WHERE idrlfprecarga=regtemp.idrlfprecarga AND idcentrorlfprecarga=regtemp.idcentrorlfprecarga;
                   END IF;
 
                   IF iftableexists('tempactividadcentroscosto') THEN
                       INSERT INTO reclibrofact_actividadcentroscosto(idrecepcion,idcentroregional,idcentrocosto ,accmonto ,idactividad ,catgasto ,accidporcentaje)
        
                      SELECT codrecepcion,idcentrorecepcion, idcentrocosto ,accmonto ,idactividad ,catgasto ,accidporcentaje
                  FROM tempactividadcentroscosto 
                  WHERE idrlfprecarga=regtemp.idrlfprecarga AND idcentrorlfprecarga=regtemp.idcentrorlfprecarga;
                  END IF;
  
 

                    if(regtemp.idtiporecepcion = 6 ) THEN 
                        INSERT INTO mapeocompcompras (idrecepcion)
                        VALUES (codrecepcion);
                    END IF;
                    
   
 
                   if(regtemp.idtiporecepcion = 6 OR regtemp.idtiporecepcion = 3 )THEN
                         param = contabilidad_periodofiscal_info (concat('{fechaemicioncomp=',regtemp.fechaemision,',pftipoiva=C}'));  
                         EXECUTE sys_dar_filtros(param) INTO rperfiscal;

                         RAISE NOTICE 'Hola mesaentrada_insertarrecepcion';
                         IF existecolumtemp('temprecepcion', 'idrlfprecarga') THEN
 
                              INSERT INTO reclibrofact (idrecepcion, idcentroregional,numeroregistro,anio, fechavenc,numfactura, monto,idprestador,
                              idlocalidad,idtipocomprobante,idcentroregionalresumen,idrecepcionresumen,clase,montosiniva,
                              descuento,recargo,exento,fechaemision,fechaimputacion,catgasto,condcompra,
                              talonario,iva21,iva105,iva27,letra,netoiva105,netoiva21,netoiva27,nogravado,numero
                              ,obs,percepciones
                              ,puntodeventa,retganancias
                              ,retiibb,retiva,subtotal,tipocambio,tipofactura,rlfpiibbneuquen,rlfpiibbrionegro,rlfpiibbotrajuri,idactividad, idusuariocarga
                              ,rlfdescuento21 ,rlfrecargo21 ,rlfivadescuento21 ,rlfivarecargo21 ,rlfdescuento27 ,rlfrecargo27 ,rlfivadescuento27 ,rlfivarecargo27   ,rlfdescuento105    ,rlfrecargo105 ,rflivadescuento105,rlfivarecargo105 ,rlftotaliva ,rlftotalimpuesto ,idrlfprecarga,idcentrorlfprecarga, impdebcred )

VALUES(codrecepcion,idcentrorecepcion,nextval('public.reclibrofact_numeroregistro_seq'),date_part('year'::text, ('now'::text)::date),regtemp.fechavenc
                              ,CASE WHEN regtemp.idtiporecepcion = 3 THEN codrecepcion ELSE regtemp.numfactura END,regtemp.monto, regtemp.idprestador,
                              regtemp.idlocalidad,regtemp.idtipocomprobante, regtemp.idcentroregionalresumen, regtemp.idrecepcionresumen, regtemp.clase,regtemp.montosiniva,
                              regtemp.descuento, regtemp.recargo,regtemp.exento, regtemp.fechaemision,
                              --regtemp.fechaimputacion, 
                              rperfiscal.fechaimputacion,
                              regtemp.catgasto,  regtemp.condcompra,
                              regtemp.talonario,  regtemp.iva21, regtemp.iva105,regtemp.iva27, regtemp.letra, regtemp.netoiva105, regtemp.netoiva21, regtemp.netoiva27,
                              regtemp.nogravado,  lpad(regtemp.numero, 8, '0'),
                              regtemp.obs,  regtemp.percepciones,  regtemp.puntodeventa, regtemp.retganancias,
                             -- regtemp.retiibb
(regtemp.rlfpiibbneuquen + regtemp.rlfpiibbrionegro + regtemp.rlfpiibbotrajuri)
, regtemp.retiva,  regtemp.subtotal,  regtemp.tipocambio,  regtemp.tipofactura,
                              regtemp.rlfpiibbneuquen,regtemp.rlfpiibbrionegro,regtemp.rlfpiibbotrajuri,regtemp.idactividad,elusuario
                              ,regtemp.rlfdescuento21,
                               regtemp.rlfrecargo21,
                               regtemp.rlfivadescuento21,
                               regtemp.rlfivarecargo21, 
                               regtemp.rlfdescuento27, 
                               regtemp.rlfrecargo27,
                               regtemp.rlfivadescuento27,
                               regtemp.rlfivarecargo27, 
                               regtemp.rlfdescuento105, 
                               regtemp.rlfrecargo105,
                               regtemp.rflivadescuento105,
                               regtemp.rlfivarecargo105,
                               regtemp.rlftotaliva,
                               regtemp.rlftotalimpuesto,
                               regtemp.idrlfprecarga,
                               regtemp.idcentrorlfprecarga,
                               regtemp.impdebcred);

                         ELSE 
                                RAISE NOTICE 'ENTRE AL ELSE temprecepcion idrlfprecarga';
                              INSERT INTO reclibrofact (idrecepcion, idcentroregional,numeroregistro,anio, fechavenc,numfactura, monto,idprestador,
                              idlocalidad,idtipocomprobante,idcentroregionalresumen,idrecepcionresumen,clase,montosiniva,
                              descuento,recargo,exento,fechaemision,fechaimputacion,catgasto,condcompra,
                              talonario,iva21,iva105,iva27,letra,netoiva105,netoiva21,netoiva27,nogravado,numero
                              ,obs,percepciones
                              ,puntodeventa,retganancias
                              ,retiibb,retiva,subtotal,tipocambio,tipofactura,rlfpiibbneuquen,rlfpiibbrionegro,rlfpiibbotrajuri,idactividad, idusuariocarga, impdebcred 
                              )VALUES(codrecepcion,idcentrorecepcion,nextval('public.reclibrofact_numeroregistro_seq'),date_part('year'::text, ('now'::text)::date),regtemp.fechavenc
                              ,CASE WHEN regtemp.idtiporecepcion = 3 THEN codrecepcion ELSE regtemp.numfactura END,regtemp.monto, regtemp.idprestador,
                              regtemp.idlocalidad,regtemp.idtipocomprobante, regtemp.idcentroregionalresumen, regtemp.idrecepcionresumen, regtemp.clase,regtemp.montosiniva,
                              regtemp.descuento, regtemp.recargo,regtemp.exento, regtemp.fechaemision,
                              --regtemp.fechaimputacion, 
                              rperfiscal.fechaimputacion,
                              regtemp.catgasto,  regtemp.condcompra,
                              regtemp.talonario,  regtemp.iva21, regtemp.iva105,regtemp.iva27, regtemp.letra, regtemp.netoiva105, regtemp.netoiva21, regtemp.netoiva27,
                              regtemp.nogravado,  lpad(regtemp.numero, 8, '0'),
                              regtemp.obs,  regtemp.percepciones,  regtemp.puntodeventa, regtemp.retganancias,
                             -- regtemp.retiibb
(regtemp.rlfpiibbneuquen + regtemp.rlfpiibbrionegro + regtemp.rlfpiibbotrajuri)
, regtemp.retiva,  regtemp.subtotal,  regtemp.tipocambio,  regtemp.tipofactura,
                              regtemp.rlfpiibbneuquen,regtemp.rlfpiibbrionegro,regtemp.rlfpiibbotrajuri,regtemp.idactividad,elusuario, regtemp.impdebcred
                              );

                            
                    END IF;
                    elnumeroregistro = concat(currval('public.reclibrofact_numeroregistro_seq'), '/',date_part('year'::text, ('now'::text)::date));
                    UPDATE temprecepcion SET idrecepcion=codrecepcion,idcentroregional= idcentrorecepcion, numeroregistro = concat(currval('public.reclibrofact_numeroregistro_seq'))::BIGINT, anio = date_part('year'::text, ('now'::text)::date);
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
   --KR 07-10-20 Modifico para dar desde precarga como alta un resumen 
                   IF iftableexists('temprecepcionfechas') THEN
                       OPEN curcentrocostos FOR SELECT * FROM temprecepcionfechas;
               FETCH curcentrocostos INTO reccentrocosto;
               WHILE  found LOOP
               -- Inserto los centros de costos del comprobante
                    INSERT INTO fechasfact(idrecepcion,idcentroregional,fechainicio,fechafin)
                 VALUES(codrecepcion,idcentrorecepcion,reccentrocosto.fechainicio,reccentrocosto.fechafin);
                       FETCH curcentrocostos INTO reccentrocosto;
               END LOOP;
               CLOSE curcentrocostos;
                    ELSE 
--KR definir la fechaini y fin, hoy se cargan en la ventana en la bbdd  BDLibroFacturacion
                       INSERT INTO fechasfact(idrecepcion,idcentroregional,fechainicio,fechafin)
                 VALUES(codrecepcion,idcentrorecepcion,CURRENT_DATE-60,CURRENT_DATE+30);
                    END IF;
                 END IF;
        END IF;

 
   

END IF;-- SELECT INTO regtemp * FROM temprecepcion ;
RETURN elnumeroregistro;
END;
$function$
