CREATE OR REPLACE FUNCTION ca.f_basicocategoriaxdiastrabajados(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       valor1139 DOUBLE PRECISION;
       diaslab DOUBLE PRECISION;
       montobasico DOUBLE PRECISION;
       montosanciondisciplinaria DOUBLE PRECISION;
       datoliq record;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_basicocategoria(#,&, ?,@)
      SELECT INTO elmonto ca.f_basicocategoria($1,$2,$3,$3);
    /*  SELECT INTO diaslab ceporcentaje as diasmes
	  FROM ca.conceptoempleado
	  WHERE idpersona =$3 and 		idliquidacion=$1   and
		idconcepto=1045 ;  --dias laborables mensuales

   */
valor1139 =0;
select into datoliq * from ca.liquidacion where idliquidacion=$1;
 SELECT INTO montobasico ceporcentaje *cemonto
	  FROM ca.conceptoempleado
	  WHERE idpersona =$3 and 		idliquidacion=$1   and
 	idconcepto=1  ;  --dias laborables mensuales


--Dani agrego el 28-06-2018 por pedido de Julieta E. para q se tenga en cuenta de restar el concepto 1186
SELECT INTO montosanciondisciplinaria ceporcentaje *cemonto
	  FROM ca.conceptoempleado
	  WHERE idpersona =$3 and 		idliquidacion=$1   and
		idconcepto=1186 ;  --sancion disciplinaria

if found then 
  montobasico=montobasico+montosanciondisciplinaria;
end if;

if ($4=1217) then --devuelvo basco+ monto concepto 1139
 select  into    valor1139 * from ca.conceptovalor(datoliq.limes,datoliq.lianio,$3,1139);
end if;
montobasico=montobasico+valor1139 ;
return 	round (montobasico::numeric,2);
END;
 
$function$
