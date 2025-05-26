CREATE OR REPLACE FUNCTION public.conciliacionbancaria_auto(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE
       cantidad integer;
       cantreint integer;
       cantliqt integer;
       cantrecibos integer;
       cantfacturas integer;
       cantminutas integer;
       rparam record;

BEGIN

    EXECUTE sys_dar_filtros($1) INTO rparam;

    /* Por el moment solo se implemento la conciliacion automatica para ordenes de pago contable*/
       cantidad = 0;
       cantreint = 0;
       cantliqt = 0;
       cantrecibos = 0;
       cantfacturas = 0;
       cantminutas = 0;

           SELECT conciliacionbancaria_auto_pagoordenpagocontable($1) INTO cantidad;
           SELECT conciliacionbancaria_auto_pagoordenpagocontablereintegros ($1) INTO cantreint;
           SELECT conciliacionbancaria_auto_liquidaciontarjetas ($1) INTO cantliqt; 
           SELECT conciliacionbancaria_auto_recibos ($1) INTO cantrecibos ;
           SELECT conciliacionbancaria_auto_facturas ($1) INTO cantfacturas ;


           IF (rparam.idbanco=41)  THEN
                --RAISE NOTICE 'ENTRANDO POR MINUTA :  (%)',$1;
                SELECT conciliacionbancaria_auto_mp_minuta ($1) INTO cantminutas ;

           END IF;

    cantidad = cantidad + cantreint + cantliqt + cantrecibos +   cantfacturas  +  cantminutas;
    return cantidad;
END;
$function$
