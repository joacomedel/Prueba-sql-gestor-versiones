CREATE OR REPLACE FUNCTION public.ingresarmovimientopagoctacte(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       elnuevoreg record;
       elprestador record;
       rctacte RECORD;
       numerofac varchar;
       elidctacte bigint;
BEGIN

  SELECT INTO elnuevoreg *  FROM reclibrofact where idrecepcion = $1 AND idcentroregional = $2;
  IF FOUND THEN
 
             --Malapi El idcomprobantetipos = 51 es Nota de Credito, por el momento no interesa detallar aun mas el tipo comprobante   
              numerofac = concat(elnuevoreg.tipofactura,'-', 	elnuevoreg.puntodeventa,' ',elnuevoreg.letra,elnuevoreg.numero, ' en recepcion:', elnuevoreg.idrecepcion , elnuevoreg.idcentroregional);
--Dani agrego el 01102022 por pedido de Flavia para que como se encontro que las Fac con catgasto=7 no iban a ctactedeudaprestador, entonces tampoco vayan las NC que hasta el momento si iban
             if(elnuevoreg.catgasto<>7)   THEN
              -- busco el idctacte del prestador
              SELECT INTO elidctacte * FROM prestadorctacte_verifica(elnuevoreg.idprestador);

	          --Verifico si ya se ingreso este movimiento
              --Asumo que se puede cambiar el prestador de la factura.
	      SELECT INTO rctacte *
                  FROM ctactepagoprestador
                   WHERE idcomprobante = (elnuevoreg.numeroregistro*10000)+elnuevoreg.anio
							AND idcomprobantetipos = 51 AND idprestadorctacte = elidctacte;
	      IF FOUND THEN
                      --Malapi Verificar este punto, pues para cambiar el importe hay que tener en cuenta el monto usado del mismo.
		              UPDATE ctactepagoprestador SET importe = elnuevoreg.monto *-1
					         ,idprestadorctacte = elidctacte
					         ,movconcepto = numerofac
					         ,saldo =  (abs(elnuevoreg.monto) - (abs(rctacte.importe) - abs(rctacte.saldo)))*-1
		              WHERE idcomprobante = (elnuevoreg.numeroregistro*10000)+elnuevoreg.anio
							AND idcomprobantetipos = 51 AND idprestadorctacte = elidctacte;
	      ELSE

                     INSERT INTO ctactepagoprestador(idcomprobantetipos, idprestadorctacte, movconcepto,nrocuentac,importe, idcomprobante, saldo)
                     VALUES(51,elidctacte,numerofac,10311,elnuevoreg.monto*-1, (elnuevoreg.numeroregistro*10000)+elnuevoreg.anio,(abs(elnuevoreg.monto)*-1));
             END IF;
             --KR TKT 5315 Chequeo si estaba en la deuda. POR ahora asumo que la deuda no esta imputado, si lo esta me va a dar error esto
                      DELETE FROM ctactedeudaprestador WHERE idcomprobante = (elnuevoreg.numeroregistro*10000)+elnuevoreg.anio AND idcomprobantetipos = 49;
	
   END IF;
 END IF;
   RETURN TRUE;
END;
$function$
