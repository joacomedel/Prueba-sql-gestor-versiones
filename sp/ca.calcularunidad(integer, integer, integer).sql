CREATE OR REPLACE FUNCTION ca.calcularunidad(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elidpersona INTEGER;
       elidconcepto  INTEGER;
       elidliquidacion INTEGER;
       datosliq record;
       valor integer;
      
BEGIN
/*  PRE: el idliquidacion es un id valido idem elidpersona*/

    elidliquidacion =$3;
    elidpersona = $2;
    elidconcepto = $1;
   
   

  select into datosliq * from ca.liquidacion
	 WHERE idliquidacion = elidliquidacion ;

   select into  valor * from  ca.antiguedadlaboral(elidpersona, 

--to_date( concat(datosliq.lianio , '-' , datosliq.limes , '-31'), 'YYYY-MM-DD')
 (( date_trunc('month', concat(datosliq.lianio,'-',datosliq.limes,'-1')::date) + interval '1 month') - interval
'1 day')::date 

,elidliquidacion) ;


/*si es el concepto Antiguedad en unidad  se colca 0.01*cant años antiguedad*/
if (elidconcepto=2) then
	update  ca.conceptoempleado set ceunidad=valor*0.01
	 WHERE idliquidacion = elidliquidacion
	and idpersona=elidpersona and idconcepto=elidconcepto;

	end if;



	
	
       

return true;
END;
$function$
