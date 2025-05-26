CREATE OR REPLACE FUNCTION public.conciliacionbancariaingresarmovimiento()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/****/
DECLARE
    rliq RECORD;
    rusuario RECORD;
   	cconitem CURSOR FOR SELECT * FROM temp_conciliacionbancariaitem;
    rconitem record;
    elidconciliacionbancariaitem bigint;
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;

     OPEN cconitem;
     FETCH cconitem INTO rconitem;
     WHILE found LOOP
  
            IF (nullvalue(rconitem.idconciliacionbancariaitem)) THEN  --Inserta
                         INSERT INTO conciliacionbancariaitem (idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idrenglon,idusuario)
                         VALUES(rconitem.idconciliacionbancaria,rconitem.idcentroconciliacionbancaria,rconitem.idbancamovimiento,
                         rconitem.idrenglon,rusuario.idusuario);
                         elidconciliacionbancariaitem = currval('conciliacionbancariaitem_idconciliacionbancariaitem_seq');

            ELSE --Actualiza
                         UPDATE conciliacionbancariaitem
                         SET 	idconciliacionbancaria = rconitem.idconciliacionbancaria,
                                idcentroconciliacionbancaria =  rconitem.idcentroconciliacionbancaria,
                                idbancamovimiento = rconitem.idbancamovimiento,
                                idrenglon = rconitem.idrenglon,
                                idusuario =  rusuario.idusuario
                        WHERE idconciliacionbancariaitem = rconitem.idconciliacionbancariaitem
                               AND idcentroconciliacionbancariaitem = rconitem.idcentroconciliacionbancariaitem;
   	         END IF;
	 FETCH cconitem INTO rconitem;
     END LOOP;
     CLOSE cconitem;
     RETURN elidconciliacionbancariaitem;

return true;
END;
$function$
