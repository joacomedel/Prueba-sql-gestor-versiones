CREATE OR REPLACE FUNCTION public.mesaentrada_eliminarrecepcion()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Se ingresan / modifica / elimina los datos de una recepción */

DECLARE
codcomprobante BIGINT;
regtemp record;
rcomp record;
elnumeroregistro varchar;
respuesta  varchar;
rresumen RECORD;
rauditada RECORD;
elem RECORD;
elemrecepcion RECORD;
esderesumen RECORD;
vTipomov char;
auxx integer;
runasiento RECORD;
casientosgenericos refcursor;
rtieneopc RECORD;

BEGIN
                   
       elnumeroregistro = '';
       SELECT INTO regtemp * FROM temprecepcion ;
       IF FOUND THEN
                /****** 19-02-2019 *******/

                 /*      SELECT INTO rcomp *
                FROM contabilidad_periodofiscal
                NATURAL JOIN contabilidad_periodofiscalreclibrofact
                JOIN reclibrofact using (idrecepcion,idcentroregional)
                WHERE nullvalue(pfcerrado) and idrecepcion = regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional;*/

/*KR 09-12-20 Modifico ya que no permite eliminar un registro que NO esta en periodo fiscal alguno */
          
                SELECT  INTO rcomp * 
                FROM reclibrofact LEFT JOIN contabilidad_periodofiscalreclibrofact using (idrecepcion,idcentroregional)
                LEFT JOIN contabilidad_periodofiscal using( idperiodofiscal)
                WHERE nullvalue(pfcerrado) and idrecepcion =  regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional;
                IF FOUND THEN
                  -- El comprobante NO se encuentra en una liquidacion de iva cerrada o KR 09-12-20 , o no se encuentra en liquidación alguna
                  /******19-02-2019  *******/

                  ---RAISE NOTICE 'el comprobante no esta en una liq cerrada';
	              -- Verifico si se requiere eliminar el comprobante
	              IF(regtemp.idrecepcion <> 0  AND regtemp.accion = 'eliminacion') THEN
                                  elnumeroregistro = concat(regtemp.numeroregistro , '/', regtemp.anio);
	                           --Elimino el comprobante
		                    --Verifico que no este sincronizada, si lo esta, primero hay que eliminarla en multivac, marco un error
		                   SELECT INTO auxx * from mapeocompcompras NATURAL JOIN reclibrofact WHERE idrecepcion =regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional and not nullvalue(idcomprobantemultivac);
                                  IF NOT found THEN
                                      --No esta sincronizada
			             SELECT INTO elemrecepcion * FROM recepcion NATURAL JOIN reclibrofact WHERE idrecepcion= regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional;
                                   --KR 09-01-22 SI el registro esta vinculado a una OPC que no esta anulada, no se debe eliminar. TKT 5578
                                      
                                     SELECT INTO rtieneopc * FROM  ordenpagocontablereclibrofact NATURAL JOIN  ordenpagocontableestado
                                     WHERE numeroregistro= regtemp.numeroregistro AND anio = regtemp.anio AND nullvalue(opcfechafin) and idordenpagocontableestadotipo<>6 ;
                                     IF FOUND THEN 
                                        RAISE EXCEPTION 'No es posible anular el comprobante, se encuentra vinculado a una OPC activa !!!  ' USING HINT = 'Informar al Sector de Tesoreria.'; 
                                     ELSE 
	
                                             /* Dani agrego el 12/08/2019 para que al eliminar un comprobante de compra tmb elimine el/los asiento/s asociado */
   
                                             OPEN casientosgenericos for SELECT  idasientogenerico,idcentroasientogenerico
                                                  FROM asientogenerico
                                                  WHERE idcomprobantesiges= concat(elemrecepcion.numeroregistro,'|',elemrecepcion.anio )and idasientogenericocomprobtipo=7;

                                              FETCH casientosgenericos  INTO runasiento;
 
                                              --borrarlos los asientos haciendo:
                                              WHILE found LOOP
                                                          perform contabilidad_eliminarasiento(runasiento.idasientogenerico,runasiento.idcentroasientogenerico);
                                                          FETCH casientosgenericos  INTO runasiento;
   
                                              END LOOP;
                                              CLOSE casientosgenericos;
                                              DELETE FROM contabilidad_periodofiscalreclibrofact WHERE idrecepcion = regtemp.idrecepcion AND idcentroregional = regtemp.idcentroregional;
			                                  DELETE FROM mapeocompcompras WHERE (idrecepcion,idcentroregional) IN (SELECT regtemp.idrecepcion,regtemp.idcentroregional);
			                                  DELETE FROM reclibrofactitemscentroscosto WHERE (idrecepcion,idcentroregional) IN (SELECT regtemp.idrecepcion,regtemp.idcentroregional);
			                                  DELETE FROM reclibrofact WHERE (idrecepcion,idcentroregional) IN (SELECT regtemp.idrecepcion,regtemp.idcentroregional);
			                                  DELETE FROM recepcion WHERE (idrecepcion,idcentroregional) IN (SELECT regtemp.idrecepcion,regtemp.idcentroregional);
			                                  DELETE FROM comprobante WHERE (idcomprobante,idcentroregional) IN (SELECT elemrecepcion.idcomprobante, elemrecepcion.idcentroregional); -- VAS 270522
                                              DELETE FROM fechasfact WHERE (idrecepcion,idcentroregional) IN (SELECT regtemp.idrecepcion,regtemp.idcentroregional);
	                                          DELETE FROM liquidaciontarjetacomprobantegasto WHERE (nroregistro, anio) IN (SELECT regtemp.numeroregistro,regtemp.anio);
			
                                               --Borro si se genero los movimientos en la Cta.Cte
                                              DELETE FROM ctactedeudanoafil WHERE idcomprobantetipos = 49 AND tipodoc = 600  AND idconcepto = 555 AND nrodoc = elemrecepcion.idprestador AND idcomprobante = (regtemp.numeroregistro*10000)+regtemp.anio; 
--KR 09-09-20 SE debe eliminar de ctactedeudaprestador, se pone el saldo en 0
                                               update ctactedeudaprestador set saldo= 0, movconcepto = concat('Movimiento cancelado porque se elimino el comprobante. ', movconcepto)
  WHERE idcomprobante = (regtemp.numeroregistro*10000)+regtemp.anio AND idcomprobantetipos = 49;
--KR 08-03-22 SE DEBE borrar de prestador no de cliente. tkt 4907
                                              DELETE FROM ctactepagoprestador WHERE idcomprobante = (regtemp.numeroregistro*10000)+regtemp.anio AND idcomprobantetipos = 51;
			                                  DELETE FROM ctactepagonoafil WHERE idcomprobante =(regtemp.numeroregistro*10000)+regtemp.anio AND idcomprobantetipos = 51 AND tipodoc = 600 AND nrodoc= elemrecepcion.idprestador;

--MaLaPi 03-05-2022 Debe eliminar de Pago del cliente, para los caso que se trate de una nota de recupero
                                                 DELETE FROM ctactepagocliente WHERE (idcomprobante = (regtemp.numeroregistro*10000)+regtemp.anio OR nullvalue(idcomprobante)) 
                                                        AND idcomprobantetipos = 51
                                                        AND movconcepto ilike 'Mov. en cta cte por ingreso de comprobante%' 
                                                        AND movconcepto ilike concat('%recepcion Nro.:',regtemp.idrecepcion,'-',regtemp.idcentroregional);
                                              -- Borro los datos de Auditoria, si es que existen y no se inicio con la auditoria.
			                                  SELECT INTO rauditada * FROM facturaordenesutilizadas WHERE nroregistro = regtemp.numeroregistro AND  anio = regtemp.anio LIMIT 1;
			                                  IF NOT FOUND THEN
				                                 DELETE FROM facturacionfechas WHERE nroregistro = regtemp.numeroregistro AND  anio = regtemp.anio;
				                                 DELETE FROM festados  WHERE nroregistro = regtemp.numeroregistro AND  anio = regtemp.anio;
				                                 DELETE FROM factura WHERE nroregistro = regtemp.numeroregistro AND  anio = regtemp.anio;
			    	                             SELECT into rresumen * from reclibrofact where idrecepcion=regtemp.idrecepcionresumen and idcentroregional=regtemp.idcentroregionalresumen;
				                                 IF FOUND THEN
				                                          -- Esta en un resumen, por lo que hay que recalcular su importe y su fecha vto.
					                                      UPDATE factura SET fimportetotal = (SELECT sum(fimportetotal+descuento) as fimportetotal
                                                                         FROM factura JOIN reclibrofact ON nroregistro=numeroregistro and factura.anio=reclibrofact.anio
                                                                         WHERE idresumen=rresumen.numeroregistro AND anioresumen= rresumen.anio)
					                                      WHERE nroregistro = rresumen.numeroregistro AND factura.anio = rresumen.anio;

					                                      UPDATE reclibrofact set fechavenc =(select max(fechavenc) as fechavenc from factura as f
                                           						join reclibrofact r on f.nroregistro=r.numeroregistro and f.anio=r.anio	WHERE f.idresumen=rresumen.numeroregistro AND f.anioresumen= rresumen.anio)
                                            			  WHERE numeroregistro = rresumen.numeroregistro AND anio = rresumen.anio;
			                                     END IF;
                                              ELSE
				                                  -- Si hay ordenes vinculadas , doy un error
				                                  RAISE EXCEPTION 'En auditoria %', concat(regtemp.numeroregistro,'-',regtemp.anio) USING HINT = 'Eliminar las ordenes vinculadas antes de proceder.';
			                                  END IF;
                                                 END IF;--no esta vinculado a una OPC no anulada
				            ELSE
			                    -- El comprobante se encuentra sincronizado
                                -- Si lo esta, doy un error
			                    RAISE EXCEPTION 'Sincronizado con multivac  %', concat(regtemp.numeroregistro,'-',regtemp.anio) USING HINT = 'Eliminar en Multivac antes de proceder.';
                            END IF;
               END IF; -- Cierre del ELSE if(regtemp.idrecepcion <> 0  AND regtemp.accion = 'eliminar') THEN
               ELSE
                   RAISE NOTICE 'el comprobante no esta en una liq cerrada';
			       -- Si lo esta, doy un error
			       RAISE EXCEPTION 'El comprobante se encuentra vinculado a una liquidacion IVA CERRADA !!!  ' USING HINT = 'Informar al Sector Contable.';
               END IF;-- El comprobante no se encuentra en una liq iva cerrada
	
         END IF;

RETURN elnumeroregistro;
END;
$function$
