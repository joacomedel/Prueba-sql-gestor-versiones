CREATE OR REPLACE FUNCTION ca.f_compextarordene2020(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       elbasico DOUBLE PRECISION;
       datomonto record;
       datoporcentaje record;
       rconcepto record;
       rliquidacion record;
       proporcion DOUBLE PRECISION;


BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_antiguedad(#,&, ?,@)
elmonto=0;

/*
idcategoria 15=Ayudante gestión de Farmacia $4496.09
idcategoria 16=personal en gestión de Farmacia $5500
idcategoria 17=Farmaceutico $6086.08
*/

SELECT INTO rliquidacion *
    FROM ca.liquidacion 
    WHERE 
 idliquidacion= $1;


	SELECT  into elmonto 
	case when  idcategoria=15 then 4496.09
	else case when   idcategoria=16 then 5500
        else case when   idcategoria=17 then 6086.08   end  end end as valor
	from ca.categoriaempleado
        NATURAL JOIN ca.categoriatipoliquidacion
	where 
   ( cefechainicio <=  ((date_trunc('month', concat(rliquidacion.lianio,'-',rliquidacion.limes,'-1')::date) + interval '1 month') - interval
'1 day')::date  and
		(nullvalue(cefechafin) or ( date_trunc('month', concat(rliquidacion.lianio,'-',rliquidacion.limes,'-1')::date) <= cefechafin or nullvalue(cefechafin)) )  )
	and idpersona = $3      and
		idcategoriatipo = 1      and
		idliquidaciontipo=$2   ;
  
if (not found or nullvalue(elmonto))   then elmonto=0;
end if;

    SELECT INTO rconcepto *
    FROM ca.conceptoempleado 
    WHERE idpersona = $3 
          and idliquidacion= $1
          and idconcepto = 1136; -- Horas mensuales 

                  
                IF  (rconcepto.cemonto <> rconcepto.ceporcentaje 
                 and (rconcepto.cemonto/rconcepto.ceporcentaje)<0.75) THEN               
                     elmonto= elmonto/rconcepto.ceporcentaje *rconcepto.cemonto;     
               
                END IF; 

     
      
return elmonto;
END;
$function$
