CREATE OR REPLACE FUNCTION ca.f_auxi(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       elbasico DOUBLE PRECISION;
       datomonto record;
       datoporcentaje record;
       porccategoria1 DOUBLE PRECISION;
       porccategoria2 DOUBLE PRECISION;
       porccategoria3 DOUBLE PRECISION;
       porccategoria4 DOUBLE PRECISION;
       porccategoria5 DOUBLE PRECISION;
       porccategoria6 DOUBLE PRECISION;
       porccategoria7 DOUBLE PRECISION;


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
/*porccategoria1=0.015;
porccategoria2=0.02;
porccategoria3=0.025;
porccategoria4=0.03;
porccategoria5=0.035;
porccategoria6=0.04;
porccategoria7=0.05;
*/
porccategoria1=0.06;
porccategoria2=0.07;
porccategoria3=0.08;
porccategoria4=0.11;
porccategoria5=0.14;
porccategoria6=0.23;
porccategoria7=0.27;



select  into elbasico * from ca.f_basicocategoriaxdiastrabajados($1,$2,$3,$4);

if found  then
	SELECT  into elmonto 
	case when  idcategoria=1 then (elbasico *porccategoria1) 
	else case when   idcategoria=2 then (elbasico *porccategoria2) 
        else case when   idcategoria=3 then (elbasico *porccategoria3) 
        else case when   idcategoria=4 then (elbasico *porccategoria4) 
        else case when   idcategoria=5 then (elbasico *porccategoria5) 
        else case when   idcategoria=6 then (elbasico *porccategoria6) 
        else case when   idcategoria=7 then (elbasico *porccategoria7) end 
        end end end  end end end as valor
	from ca.categoriaempleado
        NATURAL JOIN ca.categoriatipoliquidacion
	where  CURRENT_DATE >= cefechainicio and
		(nullvalue(cefechafin) or CURRENT_DATE <=cefechafin )
	and idpersona = $3      and
		idcategoriatipo = 1      and
		idliquidaciontipo=$2   ;  

end if;

    


return elmonto;
END;
$function$
