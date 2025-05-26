CREATE OR REPLACE FUNCTION ca.f_antiguedad(integer, integer, integer, integer)
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

--f_antiguedad(#,&, ?,@)
select into datoliq * from ca.liquidacion where idliquidacion=$1;
SELECT INTO elmonto (SUM(anios) * SUM(monto))
	FROM (
        SELECT CASE   WHEN  extract(YEAR FROM age( to_timestamp(concat(lianio,'-12','-31'),'YYYY-MM-DD'), emfechainicioantiguedad)) >=1
		       THEN extract(YEAR FROM age( to_timestamp(concat(lianio ,'-12','-31'),'YYYY-MM-DD'),  emfechainicioantiguedad) )
        ELSE  0   END as anios, 0 as monto
		FROM ca.empleado
	 JOIN
		(select * from ca.categoriaempleado
			where  to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month' >= cefechainicio and
				(nullvalue(cefechafin) or cefechafin >= to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date )
	)as cat	using(idpersona)
	NATURAL JOIN ca.categoriatipoliquidacion
	NATURAL JOIN ca.liquidacion
	WHERE idpersona = $3      and
		idcategoriatipo = 1      and
		idliquidacion = $1     	and
		idliquidaciontipo=$2
	UNION
		SELECT 0 as anios, SUM(ce.cemonto * ce.ceporcentaje) as monto
		FROM ca.empleado
		JOIN
		(select * from ca.categoriaempleado
		where  to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month'  > cefechainicio 
              and
		(nullvalue(cefechafin) or cefechafin >=to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date)
	)as cat using(idpersona)
	NATURAL JOIN ca.categoriatipoliquidacion
	NATURAL JOIN ca.conceptoempleado as ce
	NATURAL JOIN ca.concepto
	WHERE idpersona = $3      and
		idcategoriatipo = 1      and
		idliquidaciontipo=$2      and
		idliquidacion = $1     	and
		idconceptotipo =5
         --se comenta por pedido de JE y aprobacion de MC segun mail 22032022 
         /*  and idconcepto <>1139 -- 17/12/13 se excluye ajuste basico   
        and (codescripcion not ilike '%ajuste%'  )  */   -- 17/12/13 se excluye todos los ajuste   
 ) as t;

return elmonto;
END;$function$
