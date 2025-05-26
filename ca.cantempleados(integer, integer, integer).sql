CREATE OR REPLACE FUNCTION ca.cantempleados(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
 centrocosto integer;
      valor  double precision ;
      elmes integer;
      elanio integer;
      laformula varchar;
     
      respuesta record;
      cantempleados double precision;
      laformula1 varchar;   
      respuesta1 record;
      condicioncentro varchar;
      unaliq record;
     
BEGIN
 SET search_path = ca, pg_catalog;
     elmes = $1;
     elanio=$2;
     centrocosto=$3;
     cantempleados=0;


SELECT INTO unaliq *
     FROM ca.liquidacion
     WHERE limes=elmes and lianio=elanio limit 1 ;
  

     SELECT INTO cantempleados SUM(porc_asig_cc)
     FROM(
     	SELECT DISTINCT idpersona, split_part(idcentrocosto, '|', 2)::double precision   as porc_asig_cc 
     	FROM ca.liquidacioncabecera
     	NATURAL JOIN  ca.liquidacion
		NATURAL JOIN (   SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,
--concat(elanio,elmes,'01')::date) 
to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)
as idcentrocosto
		                 FROM ca.liquidacioncabecera
		                 NATURAL JOIN ca.liquidacion 
		                 WHERE limes = elmes and lianio = elanio
	    ) as t_emp_cc 
        WHERE limes = elmes  and lianio =elanio
       UNION
       SELECT DISTINCT idpersona, split_part(idcentrocosto, '|', 2)::double precision   as porc_asig_cc 
       FROM  ca.afip_situacionrevistaempleado
       NATURAL JOIN ca.grupoliquidacionempleado
       NATURAL JOIN ca.grupoliquidaciontipo 
	  left JOIN (   SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,

to_timestamp(concat(elanio,'-',elmes  ,'-01') ,'YYYY-MM-DD')::date)

as idcentrocosto
		                /* FROM ca.liquidacioncabecera
		                 NATURAL JOIN ca.liquidacion 
		                 WHERE limes = elmes and lianio = elanio*/
                     FROM  ca.afip_situacionrevistaempleado
	    ) as tt_emp_cc using(idpersona)
/*Dani modifico el 03/04/2019 el <> por =13*/
       WHERE  (idafip_situacionrevista = 13  -- si esta con lic. Sin GHaberes
              or idafip_situacionrevista = 5 -- si esta con Licencia por Maternidad
               or idafip_situacionrevista = 10)  -- si esta con Licencia Excedencia
              and ( asrefechahasta>=to_timestamp(concat(elanio,'-',elmes,'-1') ,'YYYY-MM-DD')::date or nullvalue(asrefechahasta) ) 
           --   and split_part(idcentrocosto, '|', 1) =  centrocosto
      )as h;


RETURN cantempleados;
END;
$function$
