CREATE OR REPLACE FUNCTION ca.f_totalbasicos(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
datoliq record;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
SELECT INTO datoliq *  FROM ca.liquidacion WHERE idliquidacion= $1;


     --f_funcion(#,&, ?,@)
     SELECT INTO elmonto  SUM(cemonto * ceporcentaje)
     FROM ca.persona
     NATURAL JOIN ca.categoriaempleado
     NATURAL JOIN ca.categoriatipoliquidacion
     NATURAL JOIN ca.categoriatipo
     NATURAL JOIN ca.conceptoempleado
     NATURAL JOIN ca.concepto
     WHERE idpersona = $3 and idliquidaciontipo=$2 and  to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month' > cefechainicio
           and  (nullvalue(cefechafin) or to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date <=cefechafin )
           and idcategoriatipo = 1 and idconceptotipo =5
           and idcategoria<>21
       --se comenta por pedido de JE y aprobacion de MC segun mail 22032022        
      /* and idconcepto <> 1139  -- 17-12-13  se excluye ajuste Basico
         and not  codescripcion  ilike '%ajuste%' */   -- 17/12/13 se excluye todos los ajuste  
         
  and idliquidacion= $1;

 return elmonto;
END;
$function$
