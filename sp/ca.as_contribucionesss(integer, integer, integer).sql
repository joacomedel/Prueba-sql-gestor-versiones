CREATE OR REPLACE FUNCTION ca.as_contribucionesss(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  seguridad social 
* PRE: el asiento debe estar creado

*/
DECLARE
 
 
     
       centrocosto integer;
       elmes integer;
       elanio integer;
       monto  double precision;
       montovalorlsgh  double precision;
       montonuevo double precision;
    valor_maternidad   double precision;
       rconf record;
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio = $2;
     centrocosto=$3;
     monto=0;
     montovalorlsgh=0;
     montonuevo=0;


 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */
-- Busco la configuracion de los porcentajes por centro de costo a ser aplicado en cada cetro regional
-- Particularmente nos interesa el del idcentrocos = centrocosto
   

valor_maternidad=0;
      	

SELECT INTO rconf * FROM config_centrocosto WHERE idformula = 105 and idcentrocosto = centrocosto;


SELECT INTO monto rconf.cccvalor*SUM( split_part(idcentrocosto, '|', 2)::double precision   -- % asignado el empleado al centro de costo
	       						* (leimpbruto-leimpnoremunerativo -leimpasignacionfam)
                             -ca.conceptovalorempleado(ca.liquidacion.idliquidacion,idpersona,1232,'mf'))              
	FROM  ca.liquidacion
     	NATURAL JOIN   ca.liquidacionempleado
     	NATURAL  JOIN ca.liquidacioncabecera
	JOIN (   SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,

                          to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date) as idcentrocosto
                         FROM ca.liquidacioncabecera
                          JOIN 
                         (
                              select idpersona,ca.liquidacion.idliquidacion,max(cefechainicio) from 
                              ca.categoriaempleado	
                              NATURAL JOIN ca.liquidacioncabecera
                              NATURAL JOIN ca.liquidacion 
                               where
                                  idcategoria<>21 and
                                   ( cefechafin>=concat(lianio,'-',limes,'-','01')::date or nullvalue(cefechafin) )
                                    and limes=elmes  and lianio=elanio
                                
                                     and (idliquidaciontipo=1 or idliquidaciontipo=2 or idliquidaciontipo=6  )
                                    group by idpersona,ca.liquidacion.idliquidacion
		                 
                         )as g using(idpersona,idliquidacion)
                       JOIN ca.liquidacion    on( ca.liquidacion.idliquidacion=g.idliquidacion)
                      --WHERE limes = elmes and lianio = elanio
    WHERE extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio
              --la sig linea estaba comentada y JE en mail del 03012025 pide que se revise y por tal motivo se descomenta ya que no debe tener en cuenta la liq extraordinaria de 1272024                    
                          and (idliquidaciontipo=1 or idliquidaciontipo=2  )
                   ) as tt_emp_cc -- busco la configuracion del empleado al centro de costo      	
using(idpersona)
--WHERE limes= elmes and lianio=elanio  
    WHERE extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio;


SELECT  into montovalorlsgh
case when nullvalue(

SUM( split_part(idcentrocosto, '|', 2)::double precision   -- % asignado el empleado al centro de costo
	       						* (leimpbruto-leimpnoremunerativo -leimpasignacionfam)
    )   
    )  then 0 else     
    rconf.cccvalor* SUM( split_part(idcentrocosto, '|', 2)::double precision   -- % asignado el empleado al centro de costo
	       						* (leimpbruto-leimpnoremunerativo -leimpasignacionfam)
                             ) end as valor   


	 	FROM  ca.liquidacion
     	        NATURAL JOIN   ca.liquidacionempleado
     	        NATURAL JOIN ca.liquidacioncabecera
                NATURAL JOIN (   SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)
                as idcentrocosto
		                 FROM ca.liquidacioncabecera
                                 NATURAL JOIN ca.afip_situacionrevistaempleado
                                 NATURAL JOIN ca.liquidacion 
                                 WHERE limes = elmes AND lianio = elanio
                                        AND idliquidaciontipo=3  
                                        AND idafip_situacionrevista=13  -- situacionrevista LSG
                                        AND (asrafechadesde <= concat(lianio,'-',limes,'-','01')::date 
                                                    AND (asrefechahasta >= concat(lianio,'-',limes,'-','01')::date OR nullvalue(asrefechahasta) )) 



                ) as tt_emp_cc 
      	
WHERE limes= elmes and lianio=elanio;

 


 SELECT  into valor_maternidad  case when nullvalue(

SUM( split_part(ca.dar_empleadocentrocosto(idpersona,centrocosto,
to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date), '|', 2)::double precision   -- % asignado el empleado al centro de costo
	       						* (leimpbruto-leimpnoremunerativo -leimpasignacionfam)
    )   
    )  then 0 else     
    rconf.cccvalor* SUM( split_part(ca.dar_empleadocentrocosto(idpersona,centrocosto,
to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date), '|', 2)::double precision   -- % asignado el empleado al centro de costo
	       						* (leimpbruto-leimpnoremunerativo -leimpasignacionfam)
                             ) end as valor_maternidad  
            FROM ca.liquidacionempleado
                 natural join ca.liquidacion
                 NATURAL JOIN ca.afip_situacionrevistaempleado
                 WHERE limes =elmes and lianio =elanio
--and      (idliquidaciontipo=3  )
and  	idafip_situacionrevista=5 and (nullvalue(asrefechahasta) or asrefechahasta::date>=  to_timestamp(concat(elanio,'-',elmes ,'-01') ,'YYYY-MM-DD')::date   
and asrafechadesde::date<=  to_timestamp(concat(2023,'-',7 ,'-30') ,'YYYY-MM-DD')::date   

);

  


montonuevo =monto+montovalorlsgh+valor_maternidad ;

 	

IF  nullvalue(montonuevo ) THEN montonuevo =0; END IF;	
        
	   
return 	montonuevo ;

END;
$function$
