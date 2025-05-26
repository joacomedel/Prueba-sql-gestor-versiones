CREATE OR REPLACE FUNCTION public.eliminarrecibo_crearconsumoasi()
 RETURNS bigint
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
   xiddeuda bigint;


BEGIN
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
idcomprobantetipo = 12;-- Corresponde al comprobante de migracion de ASI
OPEN cursorconsumo FOR SELECT * FROM tempconsumoasi
                       LEFT JOIN cuentacorrienteconceptotipo USING(idconcepto);
	FETCH cursorconsumo into unconsumo;
	WHILE found LOOP
        tituexiste = FALSE;
        IF NOT nullvalue(unconsumo.nrocuentacontable) THEN 
           nrocuentacontable = unconsumo.nrocuentacontable;
        ELSE
           nrocuentacontable = '10311'; --Cta Cte Asistencial NQN
        END IF;
        movimientoconcepto = '';
        fechamov = CURRENT_TIMESTAMP;

       comprobantemovimiento = idcomprobantetipo * 10000000000 + nextval('consumoasi_idconsumoasi_seq');
       movimientoconcepto = concat(unconsumo.caconcepto,movimientoconcepto);
    
       if (unconsumo.ctacte=1) then
           --Se trata de un Afiliado

           SELECT INTO datoscuentacorriente * FROM benefsosunc
                       JOIN afilsosunc ON (afilsosunc.nrodoc = benefsosunc.nrodoctitu
                                       AND afilsosunc.tipodoc = benefsosunc.tipodoctitu)
                       WHERE benefsosunc.nrodoc =  unconsumo.nrodoc;
                    
           IF FOUND THEN
		       tituexiste = TRUE;
                       /*idcuentacorriente = datoscuentacorriente.idctacte;
                       idtipocuentacorriente = datoscuentacorriente.tipodoctitu;*/
                        idcuentacorriente = lpad(to_number(datoscuentacorriente.nrodoctitu,'99999999')*10+datoscuentacorriente.tipodoctitu,9,'0');
    --                    idcuentacorriente = to_number(datoscuentacorriente.nrodoctitu,'99999999')*10+datoscuentacorriente.tipodoctitu;
                        idtipocuentacorriente = datoscuentacorriente.tipodoctitu;
		                nrodocumento = datoscuentacorriente.nrodoctitu;
           ELSE --Es un titular
                SELECT INTO datoscuentacorriente * FROM afilsosunc
                                                   WHERE afilsosunc.nrodoc =  unconsumo.nrodoc;
			    IF FOUND THEN
                                tituexiste = TRUE;
			       /*idcuentacorriente = datoscuentacorriente.idctacte;
			       idtipocuentacorriente = datoscuentacorriente.tipodoc;*/
                   idcuentacorriente = lpad(to_number(datoscuentacorriente.nrodoc,'99999999')*10+datoscuentacorriente.tipodoc,9,'0'); 
    --			   idcuentacorriente = to_number(datoscuentacorriente.nrodoc,'99999999')*10+datoscuentacorriente.tipodoc;
			       idtipocuentacorriente = datoscuentacorriente.tipodoc;
			       nrodocumento = datoscuentacorriente.nrodoc;
			    END IF;
           END IF;
           IF tituexiste THEN
		   --Inserto el consumo en la tabla de consumo de ASI
		        INSERT INTO consumoasiv2(idconsumoasi,cafechamigracion,nrodoc,tipodoc,caimporte,signo,idcomprobantetipos,caconcepto,idconcepto,idusuario)
		            VALUES(comprobantemovimiento,CURRENT_TIMESTAMP,unconsumo.nrodoc,unconsumo.tipodoc,unconsumo.caimporte,signomovimiento,idcomprobantetipo,movimientoconcepto,unconsumo.idconcepto,rusuario.idusuario);
		    /*Asiento el movimiento en la cuenta corriente*/ 
 	            INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
	                VALUES (idcomprobantetipo,idtipocuentacorriente,idcuentacorriente,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.caimporte,comprobantemovimiento,unconsumo.caimporte,unconsumo.idconcepto,nrodocumento);
                xiddeuda=currval('cuentacorrientedeuda_iddeuda_seq');
           END IF;
      else
        --Se trata de un Cliente
           INSERT INTO consumoasiv2(idconsumoasi,cafechamigracion,idclientectacte,idcentroclientectacte,caimporte,signo,idcomprobantetipos,caconcepto,idconcepto,idusuario)
  		        VALUES(comprobantemovimiento,CURRENT_TIMESTAMP,unconsumo.idclientectacte,unconsumo.idcentroclientectacte,unconsumo.caimporte,signomovimiento,idcomprobantetipo,movimientoconcepto,unconsumo.idconcepto,rusuario.idusuario);
           INSERT INTO ctactedeudacliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo)
               	VALUES (idcomprobantetipo,unconsumo.idclientectacte,unconsumo.idcentroclientectacte,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.caimporte,comprobantemovimiento,unconsumo.caimporte);
           xiddeuda=currval('ctactedeudacliente_iddeuda_seq');
      end if;

--	ELSE		UPDATE tempconsumoasi SET error = TRUE WHERE idconsumoasi = unconsumo.idconsumoasi;	END IF;
      fetch cursorconsumo into unconsumo;
	END LOOP;
close cursorconsumo;	

--KAR 24-11-22 en mis pruebas no me pasa que el saldo de una deuda ficticia quede con 0, con lo cual lo seteo pq si ha pasado. No importa la deuda que sea siempre el saldo si es x anulacion debe ser 0, sino se envia a descontar x ejemplo. TKT 5510 
 UPDATE cuentacorrientedeuda set saldo = 0 where  movconcepto ilike '%Por Anulacion del Recibo:%';
 UPDATE ctactedeudacliente set saldo = 0 where  movconcepto ilike '%Por Anulacion del Recibo:%';

return xiddeuda*100+centro();
END;


$function$
