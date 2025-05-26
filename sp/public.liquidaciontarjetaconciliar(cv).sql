CREATE OR REPLACE FUNCTION public.liquidaciontarjetaconciliar(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/****/
DECLARE

    rusuario RECORD;
    cliqtarj refcursor;
    rliqtarjeta  record;
    rparam  record;
    losparam  varchar;
    clavecomp varchar;
    sqllaclave varchar;
    elidconitem bigint;


BEGIN

     losparam = split_part($1, '@', 1);
     clavecomp = split_part($1, '@', 2);
     EXECUTE sys_dar_filtros(losparam) INTO rparam;
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;
     -- Obtengo el sql para buscar el pago a partir de la clave
     SELECT INTO sqllaclave  replace (clavecomp,'|',' AND ');

     OPEN cliqtarj FOR EXECUTE concat('SELECT  * FROM liquidaciontarjeta WHERE ',sqllaclave);
     RAISE NOTICE 'info(%)',concat('SELECT  * FROM liquidaciontarjeta WHERE ',sqllaclave);
    
     FETCH  cliqtarj INTO rliqtarjeta;
     WHILE FOUND LOOP
            INSERT INTO conciliacionbancariaitem(idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica)
            VALUES(rmovimientobanco.idconciliacionbancaria,rmovimientobanco.idcentroconciliacionbancaria,rmovimientobanco.idbancamovimiento,rusuario.idusuario,not rparam.manual);
            elidconitem = currval('conciliacionbancariaitem_idconciliacionbancariaitem_seq');

            INSERT INTO conciliacionbancariaitemliquidaciontarjeta(
           idconciliacionbancariaitem,idcentroconciliacionbancariaitem,idliquidaciontarjeta,idcentroliquidaciontarjeta)VALUES
           (elidconitem,centro(),rpagoopc.idliquidaciontarjeta,rpagoopc.idcentroliquidaciontarjeta);

     
           FETCH  cliqtarj INTO rliqtarjeta;
     END LOOP;
     CLOSE cliqtarj;
return true;
END;
$function$
