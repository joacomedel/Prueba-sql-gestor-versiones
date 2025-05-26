CREATE OR REPLACE FUNCTION public.conciliacionbancaria_compgasto_generaropc(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/****/
DECLARE
    laopc varchar;
    elidpagoordenpagocontable bigint;
    elidcentropagoordenpagocontable integer;
    elidconitem bigint;
    rfiltros record;

BEGIN

     /* Se genera la orden de pago contable correspondiente al comprobante de gasto generado para una conciliacion bancaria */
     -- 1 Genero la OPC
RAISE NOTICE '>>>>>>>>Llamada al conciliacionbancaria_generaropc( )%',$1;
   
     SELECT INTO laopc conciliacionbancaria_generaropc($1);
RAISE NOTICE '>>>>>>>>laopc  ( )%',laopc;
 
     elidpagoordenpagocontable = split_part(laopc, '|', 1);
     elidcentropagoordenpagocontable = split_part(laopc, '|', 2);

     -- 2 actualizo la temporal con los movimientos a conciliar de siges para conciliar la OPC xon los mov de la banca
     UPDATE temp_movsiges SET tablacomp =  'pagoordenpagocontable';
     UPDATE temp_movsiges SET clavecomp = concat('idpagoordenpagocontable=',elidpagoordenpagocontable,'|idcentropagoordenpagocontable=',elidcentropagoordenpagocontable);


return true;
END;
$function$
