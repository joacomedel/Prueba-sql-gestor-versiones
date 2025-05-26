CREATE OR REPLACE FUNCTION public.migrarconsumodesdeasi()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que migra los saldos de ASI de ctacte */
DECLARE
--	respuesta = boolean;
    cursorconsumo refcursor;
    unconsumo RECORD;
   datoscuentacorriente RECORD;
   titureci RECORD;
   ordenanulada RECORD;
   movimietocancelar RECORD;
   nrocuentacontable VARCHAR;
   idcuentacorriente VARCHAR;
   movimientoconcepto VARCHAR;

   fechamov  TIMESTAMP;
   signomovimiento INTEGER;
   idtipocuentacorriente INTEGER;
   comprobantemovimiento BIGINT;
   idcomprobantetipo INTEGER;
    existe BOOLEAN;
BEGIN
idcomprobantetipo = 12;-- Corresponde al comprobante de migracion de ASI
OPEN cursorconsumo FOR SELECT * FROM tempconsumoasi;
	FETCH cursorconsumo into unconsumo;
	WHILE found LOOP
	  existe = false;
      nrocuentacontable = '10311'; --Cta Cte Asistencial NQN
      movimientoconcepto = 'M.ASI ';
      fechamov = CURRENT_TIMESTAMP;

       IF unconsumo.caimporte >= 0 THEN signomovimiento = 1;
       ELSE signomovimiento = -1; END IF;
       comprobantemovimiento = idcomprobantetipo * 10000000000 + nextval('consumoasi_idconsumoasi_seq');
       SELECT INTO datoscuentacorriente * FROM benefsosunc
                   JOIN afilsosunc ON (afilsosunc.nrodoc = benefsosunc.nrodoctitu
                                   AND afilsosunc.tipodoc = benefsosunc.tipodoctitu)
                   WHERE --benefsosunc.barra = unconsumo.barra AND
                   benefsosunc.nrodoc =  unconsumo.nrodoc;
                IF FOUND THEN
                 existe = TRUE;
                   /*idcuentacorriente = datoscuentacorriente.idctacte;
                   idtipocuentacorriente = datoscuentacorriente.tipodoctitu;*/
                    idcuentacorriente = to_number(datoscuentacorriente.nrodoctitu,'99999999')*10+datoscuentacorriente.tipodoctitu;
                   idtipocuentacorriente = datoscuentacorriente.tipodoc;
                ELSE --Es un titular
                   SELECT INTO datoscuentacorriente * FROM afilsosunc
                                               WHERE afilsosunc.nrodoc =  unconsumo.nrodoc;
                IF FOUND THEN
                    existe = TRUE;
                   /*idcuentacorriente = datoscuentacorriente.idctacte;
                   idtipocuentacorriente = datoscuentacorriente.tipodoc;*/
                   idcuentacorriente = to_number(datoscuentacorriente.nrodoc,'99999999')*10+datoscuentacorriente.tipodoc;
                   idtipocuentacorriente = datoscuentacorriente.tipodoc;
                END IF;
                END IF;

       movimientoconcepto = concat(movimientoconcepto , unconsumo.caconcepto);
    IF existe THEN
     /*Inserto el consumo en la tabla de consumo de ASI*/
    INSERT INTO consumoasi(idconsumoasi,cafechamigracion,nrodoc,tipodoc,caimporte,signo,idcomprobantetipos,caconcepto)
    VALUES(comprobantemovimiento,CURRENT_TIMESTAMP,unconsumo.nrodoc,unconsumo.tipodoc,unconsumo.caimporte,signomovimiento,idcomprobantetipo,movimientoconcepto);
    /*Asiento el movimiento en la cuenta contable*/

    INSERT INTO cuentacorriente(idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,comprobante,idconcepto)
    VALUES (idcomprobantetipo,idtipocuentacorriente,idcuentacorriente,fechamov,movimientoconcepto,nrocuentacontable,unconsumo.caimporte*signomovimiento,signomovimiento,comprobantemovimiento,comprobantemovimiento,unconsumo.idconcepto);
    ELSE
        UPDATE tempconsumoasi SET error = TRUE WHERE idconsumoasi = unconsumo.idconsumoasi;
    END IF;	
    fetch cursorconsumo into unconsumo;
	
	END LOOP;
close cursorconsumo;	
--respuesta = 'false';

return 'true';
END;
$function$
