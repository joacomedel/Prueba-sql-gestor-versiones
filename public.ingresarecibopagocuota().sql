CREATE OR REPLACE FUNCTION public.ingresarecibopagocuota()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Aienta el nro de recibo en las cuotas que se pagaron con el recibo */
DECLARE
    cursormovimientos CURSOR FOR SELECT * FROM pagocuentacorriente WHERE not nullvalue(pagocuentacorriente.idmovimiento);
    unmovimiento RECORD;
    elpago RECORD;
BEGIN

     SELECT INTO elpago * FROM temppagoctacte;
/*Busco los movimientos que se cancelan, para saber cuales son las cuotas que se pagan con ese recibo*/
     OPEN cursormovimientos;
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
            UPDATE prestamocuotas SET idrecibo = elpago.idrecibo
                                      ,centro = elpago.centro
            WHERE prestamocuotas.idprestamocuotas = unmovimiento.idcomprobante;
     FETCH cursormovimientos into unmovimiento;
     END LOOP;
     close cursormovimientos;

RETURN TRUE;
END;
$function$
