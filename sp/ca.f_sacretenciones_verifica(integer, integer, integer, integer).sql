CREATE OR REPLACE FUNCTION ca.f_sacretenciones_verifica(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       rliq record;
       rliq2 record;
unempleado record;
       cursorempleado refcursor;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_bruto(#,&, ?,@)

OPEN cursorempleado  FOR SELECT    DISTINCT idpersona
                         FROM ca.conceptoempleado
                         WHERE idliquidacion = $1 and idpersona=$3;

FETCH cursorempleado INTO unempleado;
WHILE FOUND LOOP
        SELECT INTO rliq * FROM ca.liquidacion
        WHERE idliquidacion = $1;

        SELECT INTO rliq2 * FROM ca.liquidacion
        WHERE limes = rliq.limes
              and lianio = rliq.lianio
              and ((idliquidaciontipo = 1 and rliq.idliquidaciontipo= 3)or(idliquidaciontipo = 2 and rliq.idliquidaciontipo= 4)) ;

        IF FOUND THEN
                 DELETE FROM ca.conceptoempleado
                 WHERE idpersona = unempleado.idpersona
                        and idliquidacion=$1
                        and (idconcepto = 204 or idconcepto =207 or idconcepto =203 or idconcepto =1213);
                      elmonto = rliq2.idliquidacion;
                 INSERT INTO ca.conceptoempleado(cemonto,ceporcentaje,idliquidacion,idpersona,idconcepto,idusuario)
                        (SELECT ca.f_remunerativo($1,$2,unempleado.idpersona,idconcepto),ceporcentaje,$1,idpersona,idconcepto,25
                        FROM ca.conceptoempleado
                        WHERE idpersona =  unempleado.idpersona
                              and idliquidacion = rliq2.idliquidacion
                              and (idconcepto = 204 or idconcepto =207 or idconcepto =203 or idconcepto =1213)
                        );
        END IF;
       FETCH cursorempleado INTO unempleado;
END LOOP;
CLOSE cursorempleado;
return elmonto;
END;
$function$
