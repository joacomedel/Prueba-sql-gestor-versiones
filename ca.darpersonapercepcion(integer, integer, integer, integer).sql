CREATE OR REPLACE FUNCTION ca.darpersonapercepcion(integer, integer, integer, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE

       paralibro  varchar;
       salida varchar;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/



             SELECT INTO paralibro public.text_concatenar (concat(cecomentariolibrosueldo ,' ') )
             FROM ca.conceptoempleado
             NATURAL JOIN ca.concepto
             WHERE idpersona=$3 and idliquidacion =$1 ;

             IF not found THEN
                   salida = '' ;
             ELSE
                   salida = paralibro ;
             END IF;


return salida;
END;
$function$
