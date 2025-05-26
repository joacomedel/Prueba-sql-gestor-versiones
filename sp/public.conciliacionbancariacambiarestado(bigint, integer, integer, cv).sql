CREATE OR REPLACE FUNCTION public.conciliacionbancariacambiarestado(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/****/
DECLARE
    rliq RECORD;
    rusuario RECORD;

BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;

             -- Cambio el estado 
             UPDATE conciliacionbancariaestado
             SET cbcefechafin=NOW()
             WHERE idconciliacionbancaria=$1 and idcentroconciliacionbancaria=$2 and nullvalue(cbcefechafin);

               -- ingreso el nuevo estado  
             INSERT INTO  conciliacionbancariaestado(cbcefechaini,cbcedescripcion,idconciliacionbancaria,idcentroconciliacionbancaria,idusuario,idconciliacionbancariaestadotipo)
             VALUES(now(), $4,$1,$2,rusuario.idusuario,$3);

return true;
END;
$function$
