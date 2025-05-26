CREATE OR REPLACE FUNCTION public.recibocuponconciliar(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/****/
DECLARE

    rusuario RECORD;
    cmovsiges refcursor;
    rmovsiges  record;
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

     OPEN cmovsiges FOR EXECUTE concat('SELECT  * FROM recibocupon WHERE ',sqllaclave);
     RAISE NOTICE 'info(%)',concat('SELECT  * FROM recibocupon WHERE ',sqllaclave);
    
     FETCH  cmovsiges INTO rmovsiges;
     WHILE FOUND LOOP
            INSERT INTO conciliacionbancariaitem(idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica)
            VALUES(rmovimientobanco.idconciliacionbancaria,rmovimientobanco.idcentroconciliacionbancaria,rmovimientobanco.idbancamovimiento,rusuario.idusuario,not rparam.manual);
            elidconitem = currval('conciliacionbancariaitem_idconciliacionbancariaitem_seq');

            INSERT INTO conciliacionbancariaitemrecibocupon(
           idrecibocupon,idcentrorecibocupon,idconciliacionbancariaitem,idcentroconciliacionbancariaitem
           )VALUES(rmovsiges.idrecibocupon,rmovsiges.idcentrorecibocupon ,elidconitem,centro());

     
              FETCH  cmovsiges INTO rmovsiges;
     END LOOP;
     CLOSE cmovsiges;
return true;
END;
$function$
