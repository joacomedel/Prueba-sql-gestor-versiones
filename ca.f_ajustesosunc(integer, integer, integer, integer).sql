CREATE OR REPLACE FUNCTION ca.f_ajustesosunc(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       grupo record;
       laliq record;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/


/*Dani comenta el  22062022 esta formula y deja para que devuelva 0. No se sabe por tiene seteadas consultas para liq especificas.*/


select into grupo * from ca.grupoliquidacionempleado where idpersona=$3 order by glefecha desc limit 1 ;
--and glefecha>=to_date(concat(laliq.lianio,'-',laliq.limes,'-1'),'YYYY-MM-DD');    


/*obtengo la liq del aguinaldo de Junio segun el empleado sea de Farmacia o de la Obra Social*/
if ((found) and grupo.idgrupoliquidaciontipo=1) then
   
    SELECT  INTO laliq *   FROM ca.liquidacion natural join ca.liquidacionempleado  WHERE idliquidacion=727 and idpersona=$3;
    else 
    if (grupo.idgrupoliquidaciontipo=2) then 

               SELECT  INTO laliq *   FROM ca.liquidacion  natural join ca.liquidacionempleado WHERE idliquidacion=728 and idpersona=$3;
    end if;
end if;



--return laliq.leimpbruto;
return 0;
END;

$function$
