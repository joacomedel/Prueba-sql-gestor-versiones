CREATE OR REPLACE FUNCTION public.cambiarestadoordenpagocontable(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    
--  $1 idordenpagocontable $2 idcentroordenpago  $3 idestado $4 comentario
   rusuario record;


BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

            IF $3 <> 8 THEN  --Malapi 20/09/2017 Si el estado es Sincronizada, no inserto una tupla, solo marco el cambio en la cabecera de la orden   

            -- Cambio el estado del informe de facturacion al que pasa por parametro $3
             UPDATE ordenpagocontableestado
             SET opcfechafin=NOW() ,opcdescripcion =$4
             WHERE idordenpagocontable=$1 and idcentroordenpagocontable=$2 and nullvalue(opcfechafin);
               -- ingreso el nuevo estado de OPC
             INSERT INTO  ordenpagocontableestado(opcefechaini,idordenpagocontableestadotipo,idordenpagocontable,idcentroordenpagocontable,opceidusuario)
             VALUES(now(), $3,$1,$2,rusuario.idusuario);
-------------------------------------------------------------
-- CS 2018-03-13 esto es para revertir el estado Sincronizado y que no quede marcado
             UPDATE ordenpagocontable 
                          SET opcfechaenviomultivac = NULL,opcidusuarioenviomultivac =  NULL
                           WHERE idordenpagocontable= $1 
                           AND idcentroordenpagocontable= $2;
-------------------------------------------------------------

           ELSE 
             UPDATE ordenpagocontable 
                          SET opcfechaenviomultivac = NOW()
                             , opcidusuarioenviomultivac =  rusuario.idusuario
                           WHERE idordenpagocontable=$1 
                           AND idcentroordenpagocontable=$2;
           END IF;

return true;
END;
$function$
