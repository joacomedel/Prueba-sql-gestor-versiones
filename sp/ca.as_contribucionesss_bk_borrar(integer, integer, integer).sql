CREATE OR REPLACE FUNCTION ca.as_contribucionesss_bk_borrar(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  seguridad social 
* PRE: el asiento debe estar creado

*/
DECLARE
      codasiento integer;
      regformula record;
      laformula1 varchar;
      laformula1aux varchar;
      laformula2 varchar;
      laformula3 varchar;
      centrocosto integer;
      elmes integer;
      elanio integer;

      valor3  double precision;
      condicioncentro varchar;
      respuesta1 record;
      respuesta1aux record;
      respuesta2 record;
      respuesta3 record;
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio = $2;
     centrocosto=$3;
     valor3=0;


 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */


 if (centrocosto=1) then
	 condicioncentro='(idliquidaciontipo=1 or idliquidaciontipo=3)';
	 else
	  	if (centrocosto=2)then
			 condicioncentro='(idliquidaciontipo=2 or idliquidaciontipo=4)';
		else
			  condicioncentro='(idliquidaciontipo=1 and idpersona=141)';
		end if ;
 end if;
if(centrocosto=2) then
/*
              select into respuesta1 	0.27*(sum(leimpbruto)-(sum(leimpnoremunerativo)-sum(leimpasignacionfam)))as calculo1
	                from ca.liquidacionempleado
                    natural join ca.liquidacioncabecera
	                natural join  ca.liquidacion
		            where limes= elmes  and lianio= elanio  and condicioncentro;


             
		

              select into respuesta2 0.009*(sum(leimpbruto)-(sum(leimpnoremunerativo)-sum(leimpasignacionfam)))  as calculo2
	                from  ca.liquidacion
                    natural join ca.liquidacionempleado
                    natural join ca.liquidacioncabecera
	                where limes= elmes and lianio=elanio and condicioncentro;
*/
              select into respuesta2 0.279*(split_part(idcentrocosto, '|', 2)::double precision  * (sum(leimpbruto)-(sum(leimpnoremunerativo)-sum(leimpasignacionfam))))  as calculo2
	                from  ca.liquidacion
                    natural join ca.liquidacionempleado
                    natural join ca.liquidacioncabecera
					NATURAL JOIN (   SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,concat(elanio,elmes,'01')::date) as idcentrocosto
		                 FROM ca.liquidacioncabecera
		                 NATURAL JOIN ca.liquidacion 
		                 WHERE limes = elmes and lianio = elanio
	                ) as tt_emp_cc 
                   WHERE limes= elmes and lianio=elanio    and split_part(idcentrocosto, '|', 1) =  centrocosto;
            
		
             	select INTO respuesta3  case when nullvalue(0.009*(sum(ceporcentaje*cemonto)))then 0
                             else   0.009*(sum(ceporcentaje*cemonto)) end as calculo3
                    from ca.conceptoempleado  natural join ca.concepto
	                natural join ca.liquidacion natural join ca.liquidacionempleado
                    natural join ca.liquidacioncabecera
		            where 	( idconcepto=1052   or idconcepto=1053  or idconcepto=1054  or idconcepto=1042)
		                   and limes=elmes and lianio=elanio and condicioncentro;
             
			 
              valor3=respuesta1.calculo1+respuesta2.calculo2+respuesta3.calculo3;
end if;

if(centrocosto=1) then
    select into  respuesta1  0.18*(sum(leimpbruto)-(sum(leimpnoremunerativo)-sum(leimpasignacionfam))) as calculo1
              from  ca.liquidacionempleado
              join ca.categoriaempleado using(idpersona)
              natural join ca.liquidacioncabecera
              natural join ca.liquidacion 
              where (limes=elmes and lianio=elanio and (idliquidaciontipo=1 or idliquidaciontipo=3) )
                    and (idcategoria<>21)
                    and (idcategoriatipo=1)
                    and ( ( cefechainicio  <= to_timestamp(concat(elanio,'-',elmes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month' - interval '1 day')
                          and  (  cefechafin   >= to_timestamp(concat(elanio,'-',elmes,'-1') ,'YYYY-MM-DD')::date or nullvalue(cefechafin)));
              valor3=respuesta1.calculo1;
end if;


 
  if(centrocosto=3) then

             select INTO respuesta1	0.18*(sum(leimpbruto)-(sum(leimpnoremunerativo)-sum(leimpasignacionfam)))  as calculo1
                                 	from ca.liquidacionempleado
                                    natural join ca.liquidacioncabecera
	                                natural join ca.liquidacion
		                            where limes=elmes  and lianio=elanio and condicioncentro;
	
             
             valor3=respuesta1.calculo1;
   end if;





return 	valor3;



END;
$function$
