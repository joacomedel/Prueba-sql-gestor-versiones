CREATE OR REPLACE FUNCTION public.migrarconsumodesdeasiv2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que migra los saldos de ASI de ctacte */
DECLARE

   cursorconsumo refcursor;
   unconsumo RECORD;
   datoscuentacorriente RECORD;
   titureci RECORD;
   ordenanulada RECORD;
   movimietocancelar RECORD;
   nrocuentacontable VARCHAR;
   idcuentacorriente VARCHAR;
   nrodocumento VARCHAR;
   movimientoconcepto VARCHAR;
   rusuario RECORD;
   fechamov  TIMESTAMP;
   signomovimiento INTEGER;
   idtipocuentacorriente INTEGER;
   comprobantemovimiento BIGINT;
   idcomprobantetipo INTEGER;
   tituexiste BOOLEAN;
   rtipoconcepto RECORD;
   rorigenctacte RECORD;


BEGIN
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

OPEN cursorconsumo FOR SELECT * FROM tempconsumoasi
                       LEFT JOIN cuentacorrienteconceptotipo USING(idconcepto);
	FETCH cursorconsumo into unconsumo;
	WHILE found LOOP
        tituexiste = FALSE;
        IF NOT nullvalue(unconsumo.nrocuentacontable) THEN 
           nrocuentacontable = unconsumo.nrocuentacontable;
        ELSE
--KR 05-09-22 La cuenta contable que se usa es la 10321 no la 10311
--           nrocuentacontable = '10311'; --Cta Cte Asistencial NQN
             nrocuentacontable = '10321'; --Cta Cte Asistencial NQN
        END IF;
        movimientoconcepto = '';
        fechamov = CURRENT_TIMESTAMP;
        IF iftableexistsparasp('tempordenpagoimputacion') THEN 
             idcomprobantetipo = 60;-- Corresponde al comprobante de un MP 
             comprobantemovimiento = (unconsumo.nroordenpago*100)+unconsumo.idcentroordenpago;
        ELSE 
             idcomprobantetipo = 12;-- Corresponde al comprobante de migracion de ASI
             comprobantemovimiento = idcomprobantetipo * 10000000000 + nextval('consumoasi_idconsumoasi_seq');
        END IF;
      
       SELECT INTO datoscuentacorriente * FROM benefsosunc
                   JOIN afilsosunc ON (afilsosunc.nrodoc = benefsosunc.nrodoctitu
                                   AND afilsosunc.tipodoc = benefsosunc.tipodoctitu)
                   WHERE benefsosunc.nrodoc =  unconsumo.nrodoc;
       IF FOUND THEN
		   tituexiste = TRUE;
                   /*idcuentacorriente = datoscuentacorriente.idctacte;
                   idtipocuentacorriente = datoscuentacorriente.tipodoctitu;*/
                    idcuentacorriente = to_number(datoscuentacorriente.nrodoctitu,'99999999')*10+datoscuentacorriente.tipodoctitu;
                    idtipocuentacorriente = datoscuentacorriente.tipodoctitu;
		            nrodocumento = datoscuentacorriente.nrodoctitu;
      ELSE --Es un titular
                   SELECT INTO datoscuentacorriente * FROM afilsosunc
                                               WHERE afilsosunc.nrodoc =  unconsumo.nrodoc;
			IF FOUND THEN
                            tituexiste = TRUE;
			   /*idcuentacorriente = datoscuentacorriente.idctacte;
			   idtipocuentacorriente = datoscuentacorriente.tipodoc;*/
			   idcuentacorriente = to_number(datoscuentacorriente.nrodoc,'99999999')*10+datoscuentacorriente.tipodoc;
			   idtipocuentacorriente = datoscuentacorriente.tipodoc;
			   nrodocumento = datoscuentacorriente.nrodoc;
			END IF;
      END IF;
      IF tituexiste THEN
		/*movimientoconcepto = concat(movimientoconcepto , unconsumo.caconcepto);*/
               movimientoconcepto = concat(unconsumo.caconcepto,movimientoconcepto);
		/*Inserto el consumo en la tabla de consumo de ASI*/
		INSERT INTO consumoasiv2(idconsumoasi,cafechamigracion,nrodoc,tipodoc,caimporte,signo,idcomprobantetipos,caconcepto,idconcepto,idusuario)
		VALUES(idcomprobantetipo * 10000000000 + nextval('consumoasi_idconsumoasi_seq'),CURRENT_TIMESTAMP,unconsumo.nrodoc,unconsumo.tipodoc,unconsumo.caimporte,signomovimiento,idcomprobantetipo,movimientoconcepto,unconsumo.idconcepto,rusuario.idusuario);
		/*Asiento el movimiento en la cuenta corriente*/

      CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
      INSERT INTO tempcliente(nrocliente,barra) VALUES(unconsumo.nrodoc,unconsumo.tipodoc);
      SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5)::integer as centroclavepersonactacte 
		FROM (SELECT verifica_origen_ctacte() as origen ) as t;
      DROP TABLE tempcliente;

      IF unconsumo.caimporte >= 0 THEN
	/*Se trata de una deuda*/
        IF rorigenctacte.origentabla = 'afiliadoctacte' THEN        
		INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
		VALUES (idcomprobantetipo,idtipocuentacorriente,idcuentacorriente,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.caimporte,comprobantemovimiento,unconsumo.caimporte,unconsumo.idconcepto,nrodocumento);
       END IF;
       IF rorigenctacte.origentabla = 'clientectacte' THEN 
         INSERT INTO ctactedeudacliente (idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo)
		VALUES(idcomprobantetipo,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte , fechamov,movimientoconcepto
		,nrocuentacontable,unconsumo.caimporte, comprobantemovimiento,unconsumo.caimporte);
       END IF;
       ELSE
         IF rorigenctacte.origentabla = 'afiliadoctacte' THEN        
	/*Se trata de un saldo a favor, se ingresa como un pago para que luego pueda ser imputado*/
		INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
		VALUES (idcomprobantetipo,idtipocuentacorriente,idcuentacorriente,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.caimporte,comprobantemovimiento,unconsumo.caimporte,unconsumo.idconcepto,nrodocumento);
         END IF;
         IF rorigenctacte.origentabla = 'clientectacte' THEN 
            INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto
						,nrocuentac,importe,idcomprobante,saldo) 
					VALUES(idcomprobantetipo,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.caimporte,comprobantemovimiento, unconsumo.caimporte);
  
         END IF;
       END IF;
  ELSE
		UPDATE tempconsumoasi SET error = TRUE WHERE idconsumoasi = unconsumo.idconsumoasi;
	END IF;
  fetch cursorconsumo into unconsumo;
	
END LOOP;
close cursorconsumo;	
--respuesta = 'false';

return 'true';
END;$function$
