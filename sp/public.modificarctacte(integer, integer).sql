CREATE OR REPLACE FUNCTION public.modificarctacte(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
--RECORD

	rctacte RECORD;
	relinforme RECORD; 
	rorigenctacte RECORD; 
        rusuario RECORD;
--VARIABLES
        pidimputacion bigint;

BEGIN
        SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
        IF NOT FOUND THEN 
             rusuario.idusuario = 25;
        END IF;
	SELECT INTO relinforme * FROM informefacturacion AS if WHERE nroinforme = $1 AND idcentroinformefacturacion=$2;
	CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
	INSERT INTO tempcliente(nrocliente,barra) VALUES(relinforme.nrocliente,relinforme.barra);
	SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2) as clavepersonactacte 
		FROM (
		SELECT verifica_origen_ctacte() as origen 
		) as t;
         DROP TABLE tempcliente;
	
	IF rorigenctacte.origentabla = 'clientectacte' THEN 
		SELECT INTO rctacte * FROM  ctactepagocliente WHERE idcomprobante = ($1*100)+$2;	
		IF FOUND THEN 
        --pongo el pago en 0
			pidimputacion = nextval('ctactedeudapagocliente_idimputacion_seq'); 
			UPDATE  ctactepagocliente SET 
				saldo = 0,
				movconcepto = CONCAT('Pago anulado. Se anuló el comprobante vinculado al mismo. ', movconcepto, '. Desde sp modificarctacte')--,
			--	anulado = now()
				WHERE idpago = rctacte.idpago AND idcentropago = rctacte.idcentropago; 
--KR 19-03-19 Genero la deuda que anula el pago. 
                        INSERT INTO ctactedeudacliente(idcomprobantetipos,idclientectacte,movconcepto,nrocuentac,
                     importe,idcomprobante,saldo)
	  VALUES  (21,rctacte.idclientectacte,'Deuda generada al anularse el pago. ',rctacte.nrocuentac,rctacte.importe*(-1),rctacte.idcomprobante,0);
                        INSERT INTO ctactedeudapagocliente (idpago, iddeuda, idcentrodeuda, idcentropago, importeimp, idusuario, idimputacion)
                        VALUES  (rctacte.idpago,currval('ctactedeudacliente_iddeuda_seq'),centro(),rctacte.idcentropago,rctacte.importe*(-1),rusuario.idusuario,pidimputacion); 
		END IF; 
        END IF; 

	IF rorigenctacte.origentabla = 'prestadorctacte'  THEN 
		SELECT INTO rctacte * FROM  ctactepagoprestador WHERE idcomprobante = ($1*100)+$2;	
		IF FOUND THEN 
			pidimputacion = nextval('ctactedeudapagocliente_idimputacion_seq'); 
			UPDATE  ctactepagoprestador SET 
				saldo = 0,
				movconcepto = CONCAT('Pago cancelado al anularse el comprobante vinculado al mismo. ', movconcepto, '. Desde sp modificarctacte'),
				anulado = now()
				WHERE idpago = rctacte.idpago AND idcentropago = rctacte.idcentropago; 

                        --KR 19-03-19 Genero la deuda que anula el pago. 
                        INSERT INTO ctactedeudaprestador(idcomprobantetipos,idprestadorctacte,idcomprobante,movconcepto,
                     nrocuentac,importe,saldo)
	  VALUES  (21,rctacte.idprestadorctacte,rctacte.idcomprobante,'Deuda generada al anularse el pago. ',rctacte.nrocuentac,rctacte.importe*(-1),0);
                        INSERT INTO ctactedeudapagoprestador (idpago, iddeuda, idcentrodeuda, idcentropago, importeimp, idusuario, idimputacion)
                        VALUES  (rctacte.idpago,currval('ctactedeudaprestador_iddeuda_seq'),centro(),rctacte.idcentropago,rctacte.importe*(-1),rusuario.idusuario,pidimputacion); 
 /*
		--sumo al importe del saldo el pago que ya no existe 
			UPDATE ctactedeudaprestador as tf SET saldo = saldo + T.importeimp		        
	                    FROM (SELECT SUM(importeimp) AS importeimp, iddeuda, idcentrodeuda 
                                    FROM ctactedeudapagoprestador 
		                    WHERE idpago = rctacte.idpago AND idcentropago = rctacte.idcentropago
                                    GROUP BY iddeuda, idcentrodeuda) AS T
	                        WHERE tf.iddeuda = T.iddeuda AND tf.idcentrodeuda = T.idcentrodeuda; 
		--pongo el pago en 0
			UPDATE  ctactedeudapagoprestador SET importeimp = 0 
			WHERE idpago = rctacte.idpago AND idcentropago = rctacte.idcentropago;
*/
		END IF; 
        END IF;  
return true;
END;
$function$
