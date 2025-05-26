CREATE OR REPLACE FUNCTION public.cambiarestadocheque(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--select  * from cambiarestadocheque($1,$2,$3,$4)
--  $1 idcheque $2 idcentrocheque  $3 idchequeestado $4 comentario
   rusuario record;
    datocheque record;

BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;

--Controlo q el cheque no tenga una OPC o bien que tenga pero q no este anulada
 /* comento vAS 13/08/18  SELECT into datocheque  from 	

            cheque
            left join   pagoordenpagocontable       
            using(idcheque,idcentrocheque)    left join   ordenpagocontable    
            using   (idordenpagocontable,idcentroordenpagocontable) 
            left join   ordenpagocontableestado    using
            (idordenpagocontable,idcentroordenpagocontable)
             WHERE idcheque=$1        AND idcentrocheque=$2 and
              (
                      (nullvalue(opcfechafin) and idordenpagocontableestadotipo=6) 
                      or   nullvalue(idordenpagocontable)
               );

IF  FOUND THEN comento vAS 13/08/18  */ 


         UPDATE chequeestado
         SET  cefechafin = NOW()
              ,cecomentario = 'Modificado desde sp cambiarestadocheque'
              , idusuario =  rusuario.idusuario
         WHERE idcheque=$1
               AND idcentrocheque=$2 and nullvalue(cefechafin);
                
          -- ingreso el nuevo estado del
         INSERT INTO  chequeestado(cefechaini,idchequeestadotipo,idcheque,idcentrocheque,idusuario,cecomentario)
         VALUES(now(), $3,$1,$2,rusuario.idusuario,$4);
---  comento vAS 13/08/18  END IF;


return true;
END;
$function$
