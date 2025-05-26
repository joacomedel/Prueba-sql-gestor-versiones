CREATE OR REPLACE FUNCTION public.sys_asentarpagodeudactacte_conarchivo(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*select sys_asentarpagodeudactacte_conarchivo('{"iddeuda":"24498"}');
select w_asentarpagodeudactacte('{"iddeuda":"24498","idcentrodeuda":"1","importepago":"5005.24","autorizacion":"12932554698","nrotarjeta":"2181572983","nrocupon":"2181572983"}')

*/
DECLARE

    cursorprincipal CURSOR FOR SELECT iddeuda,idcentrodeuda,importepago,autorizacion,nrotarjeta,nrocupon,external_reference,min(idprocesaarchivomp) as idprocesaarchivomp,count(*) as cantidad,saldodeuda 
FROM (
 SELECT iddeuda,idcentrodeuda,TRANSACTION_AMOUNT,trim(case when LENGTH(TRANSACTION_AMOUNT) - POSITION('.' IN TRANSACTION_AMOUNT) > 2 then replace(replace(TRANSACTION_AMOUNT,'.',''),',','.') else TRANSACTION_AMOUNT end) as importepago,SOURCE_ID as autorizacion,ORDER_ID as nrotarjeta,ORDER_ID as nrocupon,external_reference,idprocesaarchivomp,ctactedeudacliente.saldo as saldodeuda 
                              FROM sys_procesa_archivo_mp
                              JOIN ctactedeudacliente  on concat(iddeuda,'|',idcentrodeuda) = external_reference
                              WHERE nullvalue(pampprocesado)  --AND ctactedeudacliente.saldo <> 0 

                             
                              ORDER BY idcentrodeuda,iddeuda
) as t
GROUP BY iddeuda,idcentrodeuda,importepago,autorizacion,nrotarjeta,nrocupon,external_reference,saldodeuda;
                           --   LIMIT 1;

--VARIABLES 
   vvalorcagamercadopago INTEGER;
--RECORD
      respuestajson jsonb;
      respuestajson1 jsonb;
      rdeuda RECORD;
      rpago  RECORD;
      rformapagouw RECORD;
      vimporte float;
      vnrotarjeta VARCHAR;
      vnrocupon VARCHAR;
begin


OPEN cursorprincipal;
	FETCH cursorprincipal into rdeuda;
	WHILE found LOOP

        IF rdeuda.saldodeuda <> 0 THEN

        RAISE NOTICE 'Voy a procesar (%)',row_to_json(rdeuda);
        respuestajson1 = row_to_json(rdeuda);
        SELECT INTO respuestajson w_asentarpagodeudactacte(respuestajson1);
	--respuestajson = row_to_json(rpago);
	RAISE NOTICE 'TErmine de procesar (%)',respuestajson;
	UPDATE sys_procesa_archivo_mp SET pampprocesado = now(),pamprespuestapago =respuestajson  WHERE external_reference= rdeuda.external_reference;
        ELSE 
             UPDATE sys_procesa_archivo_mp SET pampprocesado = now(),pamprespuestapago = '{"texto":"La deuda esta con saldo cero! "}' WHERE external_reference= rdeuda.external_reference;
        END IF;
fetch cursorprincipal into rdeuda;
END LOOP;
close cursorprincipal;

       return respuestajson;

end;
$function$
