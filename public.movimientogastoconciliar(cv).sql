CREATE OR REPLACE FUNCTION public.movimientogastoconciliar(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/****/
DECLARE

    rusuario RECORD;
    cbancamov CURSOR FOR SELECT * FROM  temp_bancamovimiento; -- temporal con los movimientos de la banca que se desean conciliar
    rmovimientobanco  record;

BEGIN

     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;
     OPEN cbancamov;
     FETCH  cbancamov INTO rmovimientobanco;
     WHILE FOUND LOOP
                     -- Ingreso el moimiento del banco correspondiente a un gasto como parte de la conciliacion
                     INSERT INTO conciliacionbancariaitem(idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario)
                     VALUES(rmovimientobanco.idconciliacionbancaria,rmovimientobanco.idcentroconciliacionbancaria,rmovimientobanco.idbancamovimiento,rusuario.idusuario);

     FETCH  cbancamov INTO rmovimientobanco;
     END LOOP;
     CLOSE cbancamov;
return true;
END;

$function$
