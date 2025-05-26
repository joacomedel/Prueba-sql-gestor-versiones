CREATE OR REPLACE FUNCTION ca.as_contribucionesos(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  obra social 
* PRE: el asiento debe estar creado

*/
DECLARE
     
    
      centrocosto integer;
      elmes integer;
      elanio integer;
      rconf record;
      monto  double precision;
	
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio = $2;     
     centrocosto=$3;
     
 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */

 
		    SELECT INTO monto SUM( split_part(idcentrocosto, '|', 2)::double precision   -- % asignado el empleado al centro de costo
	       						     * (leimpbruto-leimpnoremunerativo -leimpasignacionfam)
								   )   	
			FROM  ca.liquidacion
			NATURAL JOIN  ca.liquidacionempleado
			NATURAL JOIN (   SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,
--concat(elanio,elmes,'01')::date)
to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)
 as idcentrocosto
		                 FROM ca.liquidacioncabecera
		                 NATURAL JOIN ca.liquidacion 
		                 WHERE limes = elmes and lianio = elanio
and (  idliquidaciontipo=2)
	  	    ) as tt_emp_cc -- busco la configuracion del empleado al centro de costo
			WHERE 	limes=elmes and lianio=elanio

; --  and split_part(idcentrocosto, '|', 1) =  centrocosto;
  
			IF  nullvalue(monto) THEN monto=0; END IF;
		
      		-- Busco la configuracion de los porcentajes por centro de costo a ser aplicado en cada cetro regional
	  		-- Particularmente nos interesa el del idcentrocos = centrocosto
      		SELECT INTO rconf * FROM config_centrocosto WHERE idformula = 106 and idcentrocosto = centrocosto;

      	
			monto = monto * rconf.cccvalor;
			 
   
return round(monto::numeric,2);
END;
$function$
