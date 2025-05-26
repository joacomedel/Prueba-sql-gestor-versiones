CREATE OR REPLACE FUNCTION ca.as_sueldosjornales(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
	* Inicializa el asiento correspondiente a sueldos y jornales 
	* PRE: el asiento debe estar creado
	* (rem+ no rem+ asig)
	*/

	
	DECLARE
	        centrocosto integer;
		    elmes integer;
		    elanio integer;
		    respuesta record;
		    monto double precision;
            liqcomple record;

	BEGIN
	   
	     SET search_path = ca, pg_catalog;
             elmes=$1;
	     	 elanio=$2;
	     	 centrocosto = $3;
	          monto=0;
	 /* reemplazarparametrosasiento
	     '#', mes
	     '&',anio
	     '@', idcentrocosto
	     '$', nroctacble

	  */
	     SELECT INTO monto SUM(  (leimpbruto - (leimpnoremunerativo - leimpasignacionfam) + leimpnoremunerativo)
		                      * split_part(idcentrocosto, '|', 2)  ::double precision
							  ) 
	  --   (sum(leimpbruto)-(sum(leimpnoremunerativo)-sum(leimpasignacionfam)) + sum(leimpnoremunerativo) )*(split_part(idcentrocosto, '|', 2)  ::double precision) as calculo
	     FROM ca.liquidacioncabecera
	     NATURAL JOIN ca.liquidacionempleado
	     NATURAL JOIN ca.liquidacion
	     NATURAL JOIN ( 
		   		SELECT distinct idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,
--concat(lianio,limes,'01')::date)
to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)
 as idcentrocosto
		   		FROM ca.liquidacioncabecera
		   		NATURAL JOIN ca.liquidacion 
		   		WHERE limes = elmes and lianio = elanio
and (  idliquidaciontipo=1  or  idliquidaciontipo=2 or  idliquidaciontipo=3)
	     )as t
	     WHERE  --limes = elmes  and lianio = elanio  ;
		  --and split_part(idcentrocosto, '|', 1) =  centrocosto;
                           extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio ; 
	
	          
         IF nullvalue(monto) THEN
                  monto = 0;
          END IF;
          return monto;
       
END;
$function$
