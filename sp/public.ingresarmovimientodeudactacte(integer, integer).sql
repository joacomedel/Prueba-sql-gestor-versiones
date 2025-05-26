CREATE OR REPLACE FUNCTION public.ingresarmovimientodeudactacte(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       elnuevoreg record;
       elprestador record;
       rctacte RECORD;	
       numerofac varchar;
       elidctacte bigint;
       rpagoimp RECORD;	
       rformapago RECORD;
       rdeudapagoexistente RECORD;

BEGIN
   --  RAISE NOTICE 'Hola aca estoy ingresarmovimientodeudactacte: %', $2 ;
     SELECT INTO elnuevoreg * FROM reclibrofact where idrecepcion = $1 AND idcentroregional = $2;     
     IF FOUND THEN
                 --elnuevoreg <> 7 para no tomar las liquidaciones de tarjeta
                 --Dani 01102022 se descomenta la condicion de catgasto<>7 . Ver mail de ese dia para  la justificacion
                  /*Dani 01102022 se deja comoestaba originalmente la condicion de catgasto<>7 . Esto e sporque mientras se desactivo empezaron a caer Liq y Flavia reporto 
                  que no es eso lo se quiere.Pero si se podria modificar el sp de ingresamovimientopagoctacte para que no vaya ni FA ni NC a la ctacte cuadno sea CATGASTO=7 */

                  if (nullvalue (elnuevoreg.idrecepcionresumen) and  nullvalue (elnuevoreg.idcentroregionalresumen)
                        and elnuevoreg.catgasto<>7  ) THEN

                       --Malapi El idcomprobantetipos = 49 es Factura Compra, por el momento no interesa detallar aun mas el tipo comprobante
                       numerofac = concat(elnuevoreg.tipofactura,':',elnuevoreg.letra,' ',elnuevoreg.puntodeventa,'-',elnuevoreg.numero, ' Num. Reg:',elnuevoreg.numeroregistro ,'-', elnuevoreg.anio  , ' en recepcion:', elnuevoreg.idrecepcion ,elnuevoreg.idcentroregional);

                       -- busco el idctacte del prestador
                       SELECT INTO elidctacte * FROM prestadorctacte_verifica(elnuevoreg.idprestador);

	                   --Verifico si ya se ingreso este movimiento
                       --Asumo que se puede cambiar el prestador de la factura.
	                   SELECT INTO rctacte *
                       FROM  ctactedeudaprestador
                       WHERE idcomprobante = (elnuevoreg.numeroregistro*10000)+elnuevoreg.anio
							 --AND idcomprobantetipos = 49 AND idprestadorctacte = elidctacte
                             ;
	                IF FOUND THEN

                                -- BelenA 11-04-24 arreglo
                                -- Si encuentra mov en la ctacte, se fija si tiene forma de pago

                                SELECT INTO rformapago *
                                FROM reclibrofact_formpago 
                                WHERE idrecepcion=elnuevoreg.idrecepcion AND idcentroregional=elnuevoreg.idcentroregional;

                                IF ( NOT FOUND OR  rformapago.idvalorescaja = 3) THEN
                                -- Si no tiene forma de pago, o la forma de pago es 3 (ctacte)

                                    --Malapi Verificar este punto, pues para cambiar el importe hay que tener en cuenta el monto usado del mismo.
                                     UPDATE ctactedeudaprestador SET importe = elnuevoreg.monto
                                            , idprestadorctacte = elidctacte
                                            , movconcepto = numerofac
                                            , saldo =(elnuevoreg.monto - (rctacte.importe - abs(rctacte.saldo) ) )
                                            ,fechavencimiento = elnuevoreg.fechavenc
                                     WHERE idcomprobante = (elnuevoreg.numeroregistro*10000)+elnuevoreg.anio
                                           AND idcomprobantetipos = 49
                                           --VAS 01/10/2017: se cargo mal el prestador AND idprestadorctacte = elidctacte
                                                                        ;
                                ELSE
                                    -- Si tiene forma de pago que es distinto de 3, quiero sacar el mov de la ctacte

                                    IF ( rctacte.importe<>rctacte.saldo ) THEN
                                        -- Si el importe y el saldo de la deuda son diferentes, es que se ha imputado algun pago
                                        -- Debo fijarme si existe una imputacion
                                        SELECT INTO rdeudapagoexistente *
                                        FROM ctactedeudapagoprestador
                                        WHERE iddeuda = rctacte.iddeuda AND idcentrodeuda = rctacte.idcentrodeuda
                                          AND importeimp <> 0;

                                        IF FOUND THEN
                                          RAISE EXCEPTION 'EXISTE UNA DEUDA PARA ESTE COMPROBANTE Y YA SE ENCUENTRA IMPUTADA A UN PAGO :(%)',rdeudapagoexistente ;
                                        END IF;
                                    END IF;

                                    -- Si la deuda tiene importe y saldo iguales, es porque no fue imputado (O si estaba imputado se desimputo)
                                    -- Entonces se coloca el importe y saldo en 0 para simular que la deuda fue borrada y que no aparezca en CtaCte
                                    UPDATE ctactedeudaprestador
                                    SET importe=0, saldo=0
                                    WHERE iddeuda = rctacte.iddeuda AND idcentrodeuda = rctacte.idcentrodeuda;

                                END IF;

                    ELSE
                                -- BelenA 11-04-24 arreglo
                                -- Si no encuentra mov en la ctacte, se fija si tiene forma de pago

                                SELECT INTO rformapago *
                                FROM reclibrofact_formpago 
                                WHERE idrecepcion=elnuevoreg.idrecepcion AND idcentroregional=elnuevoreg.idcentroregional;


                                IF ( NOT FOUND OR  rformapago.idvalorescaja = 3) THEN
                                -- Si no tiene forma de pago, o la forma de pago es 3 (ctacte)
                                    INSERT INTO ctactedeudaprestador(idcomprobantetipos, idprestadorctacte,
                                      movconcepto,nrocuentac,importe, idcomprobante, saldo,fechavencimiento)
                                    VALUES(49,elidctacte,numerofac,10311,elnuevoreg.monto,
                                      (elnuevoreg.numeroregistro*10000)+elnuevoreg.anio,elnuevoreg.monto, elnuevoreg.fechavenc);
                                END IF;


                               

                    END IF;
      --KR TKT 5315 Chequeo si estaba en el pago. POR ahora asumo que el pago no esta imputado, si lo esta me va a dar error esto
                      DELETE FROM ctactepagoprestador WHERE idcomprobante = (elnuevoreg.numeroregistro*10000)+elnuevoreg.anio AND idcomprobantetipos = 51;
		      
  
              END IF;
  END IF;
  RETURN TRUE;
END;
$function$
