CREATE OR REPLACE FUNCTION ca.as_art(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a art (tipoasiento=2)
* PRE: el asiento debe estar creado
* (Rem)*0.0143+0.6*CE
*--tope de 31167.56
*/
DECLARE
      centrocosto integer;
      valor  double precision ;
      elmes integer;
      elanio integer;
      laformula varchar;
      laformula1 varchar;
      condicioncentro varchar;
      caso1 varchar;
      caso2 varchar;
      condiciontope varchar;
      respuesta record;
      respuesta1 record;
      cantempleados double precision;
      tope double precision;
      alicuota double precision;
      porcentaje double precision;
      rtopes record;
      fechatope date;
      licenciamater double precision;
      valor_maternidad double precision;
      valor_maternidad_retroactivo double precision;
      valoraux record;
      valorlicenciamaterretroactivo varchar;
      valorlicenciamater varchar;
      valorconceptosindem varchar;
      rtalicmaternidadretroactivo record;
      rtalicmaternidad record;
      rtaconceptosindem record;
      liqcomple record;
      cempleados  double precision;
      conceptosnoremnosuman double precision;
BEGIN

     SET search_path = ca, pg_catalog;
     elmes = $1;
     elanio=$2;
     centrocosto=$3;
     valor=0;
conceptosnoremnosuman=0;

-----------------------------
-- Recupero los topes para el periodo correspondiente
-----------------------------
      if (elmes=12) then 
           fechatope =    concat(elanio+1,'-',1,'-01')::date - integer '1' ;
      else
           fechatope =    concat(elanio,'-',elmes+1,'-01')::date - integer '1' ;
      end if;
   RAISE NOTICE 'fechatope (%)',fechatope;
                 
     SELECT INTO rtopes *
     FROM ca.formulatope
     WHERE idformula =104 and fechatope >= astcctfechadesde   and   (fechatope <= astcctfechahasta or nullvalue(astcctfechahasta));

     tope = rtopes.astcctmonto;
     alicuota = rtopes.astcctmontoalicuota;
     porcentaje = rtopes.astporcentaje;
    RAISE NOTICE 'porcentaje (%)',porcentaje;
  
-------------------------------------
---  en farmacia el monto es los conceptos remunerarivos + los no remunerativos * 0.013
 
    --Dani comento el 04062024 por pedido de JE segun mail del 04062024
    --Se deja esta formula con el mismo comportamiento que Seguro de Vida
     
    -- SELECT INTO cempleados  * FROM  ca.cantempleados(elmes,elanio,centrocosto);
    --     RAISE NOTICE 'cantidad empleados  (%)',cempleados;

     SELECT  INTO cempleados
                    SUM(eccporcentual)
     FROM ca.afip_situacionrevistaempleado
     natural join 
     (select  	idpersona,max(asrafechadesde)as asrafechadesde
     from ca.afip_situacionrevistaempleado
     where ( asrefechahasta>=to_timestamp(concat(elanio,'-',elmes  ,'-01') ,'YYYY-MM-DD')::date or nullvalue(asrefechahasta) )
 
       and asrafechadesde<to_timestamp(concat(elanio,'-',elmes  ,'-01') ,'YYYY-MM-DD')::date + interval '1 month'
       group by idpersona
     ) as t
     natural join ca.empleadocentrocosto
     WHERE            
         idcentrocosto =centrocosto and ( asrefechahasta>=to_timestamp(concat(elanio,'-',elmes  ,'-01') ,'YYYY-MM-DD')::date or nullvalue(asrefechahasta) );



      

     -- Calculo el valor del concepto licencia por maternidad liquidada
     SELECT INTO valorlicenciamater CASE  WHEN nullvalue( d.licmat ) THEN 0 ELSE d.licmat END
     FROM (SELECT  SUM(cemontofinal* split_part(idcentrocosto, '|', 2):: double precision)  as licmat
           FROM ca.conceptoempleado
           NATURAL JOIN ca.liquidacion
		   NATURAL JOIN (  	   SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto, 
                                        to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)
                                        as idcentrocosto
		                       FROM ca.liquidacioncabecera
		                       NATURAL JOIN ca.liquidacion 
		                       WHERE limes = elmes and lianio = elanio
	       ) as t_emp_cc 
		   
           WHERE idconcepto=1105 and limes =elmes  and lianio =elanio
           and (idliquidaciontipo=1 or idliquidaciontipo=2)
 	   and split_part(idcentrocosto, '|', 1) =  centrocosto
 
           GROUP BY idliquidaciontipo
           UNION
           SELECT 0 as licmat
       ) as d;
      RAISE NOTICE 'valorlicenciamater 1  (%)',valorlicenciamater;
   

      SELECT INTO liqcomple *
       FROM ca.liquidacion
       WHERE extract (month from (lifecha))=elmes and extract (year from (lifecha))=elanio and  idliquidaciontipo=6 and centrocosto=1;

     IF found THEN
                  SELECT INTO  valor_maternidad_retroactivo  case when nullvalue(licenciamater_rec) THEN 0 ELSE  licenciamater_rec END
                  FROM (
                        SELECT  sum(cemontofinal * split_part(idcentrocosto, '|', 2):: double precision )  as licenciamater_rec
                        FROM ca.conceptoempleado
                        NATURAL JOIN ca.liquidacion
					    NATURAL JOIN ( SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,   
                                                           to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)
                                                           as idcentrocosto
		                                           FROM ca.liquidacioncabecera
		                                           NATURAL JOIN ca.liquidacion 
		                                           WHERE limes = elmes and lianio = elanio
	                                     ) as t_emp_cc
                        WHERE idconcepto=1105 AND idliquidaciontipo=6
                         and (idliquidaciontipo=1 or idliquidaciontipo=2)
                         AND extract (month from (lifecha))=elmes and extract (year from (lifecha))=elanio
                         AND split_part(idcentrocosto, '|', 1) =  centrocosto                                
                        GROUP BY idliquidaciontipo
                        UNION
                        SELECT 0 as licenciamater_rec
                        ) as d;

     ELSE
             valor_maternidad_retroactivo = 0 ;

     END IF;

     SELECT INTO  valor_maternidad  case when nullvalue(SUM(d.licenciamater)) then 0 else SUM(d.licenciamater) end
     FROM (
            SELECT  sum(cemontofinal * split_part(idcentrocosto, '|', 2):: double precision)  as licenciamater
            FROM ca.conceptoempleado
            NATURAL JOIN ca.liquidacion
		    NATURAL JOIN (     SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,
                                       to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)
                                        as idcentrocosto
		                       FROM ca.liquidacioncabecera
		                       NATURAL JOIN ca.liquidacion 
		                       WHERE limes = elmes and lianio = elanio
	                         ) as t_emp_cc
            WHERE idconcepto=1105    AND limes =elmes and lianio =elanio
            and (idliquidaciontipo=1 or idliquidaciontipo=2)
            AND split_part(idcentrocosto, '|', 1) =  centrocosto 
            GROUP BY idliquidaciontipo
            UNION
            SELECT 0 as licenciamater
      ) as d;

   RAISE NOTICE 'valorlicenciamater 2 (%)',valorlicenciamater;
  
      SELECT INTO rtaconceptosindem  case when nullvalue(sum(d.valor)) then 0 else  sum(d.valor) end as valorconcepto
      FROM (
            SELECT   sum(cemontofinal * split_part(idcentrocosto, '|', 2):: double precision )  as valor 
            FROM ca.conceptoempleado
            NATURAL JOIN ca.liquidacion
	    NATURAL JOIN (     SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,
                                       to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)
                                       as idcentrocosto
		                       FROM ca.liquidacioncabecera
		                       NATURAL JOIN ca.liquidacion 
		                       WHERE limes = elmes and lianio = elanio
                                        and (idliquidaciontipo=1 or idliquidaciontipo=2)

	                               ) as t_emp_cc
            WHERE idpersona<>413 and
                   (idconcepto=1198 or idconcepto=1197 or idconcepto=1068  or idconcepto=1069  )
                     AND limes =elmes and lianio = elanio   and (idliquidaciontipo=1 or idliquidaciontipo=2)
                     AND split_part(idcentrocosto, '|', 1) =  centrocosto 
            GROUP BY  idliquidaciontipo
            UNION
            SELECT 0 as valor
            ) as d;

 RAISE NOTICE 'rtaconceptosindem   (%)',rtaconceptosindem;
 
     SELECT INTO liqcomple *
     FROM ca.liquidacion
     WHERE extract (month FROM (lifecha))=elmes and extract (year FROM (lifecha))=elanio and idliquidaciontipo=6  and centrocosto=1;
  


if(centrocosto<>2) then
--Es la suma de Rem +No rem  y sin tener en cuenta vacaciones no goz y sac sobre esas vacaciones  
 
 
    /*SELECT  into respuesta
    (  (sum(leimpbruto * split_part(idcentrocosto, '|', 2):: double precision )- 
      sum(leimpnoremunerativo * split_part(idcentrocosto, '|', 2):: double precision )   )+
      (sum(leimpnoremunerativo * split_part(idcentrocosto, '|', 2):: double precision ) -
      sum(ca.conceptovalor(elmes,elanio,idpersona,1068)+ca.conceptovalor(elmes,elanio,idpersona,1069)))) as  valor                
*/
     

    select into respuesta  sum(h.valoraux)  as valor from 
        (
          select   sum(leimpbruto * split_part(idcentrocosto, '|', 2):: double precision ) -
            sum(leimpnoremunerativo * split_part(idcentrocosto, '|', 2):: double precision )  +

         (    case when (idliquidaciontipo=1 /*or idliquidaciontipo=6*/)then 
             (sum(leimpnoremunerativo * split_part(idcentrocosto, '|', 2):: double precision )  -
             sum(ca.conceptovalor(elmes,elanio,idpersona,1068)+ca.conceptovalor(elmes,elanio,idpersona,1069)
                  ))
         else 0 end  ) 
  
       as valoraux                  
 

      FROM ca.liquidacionempleado
      JOIN ca.liquidacioncabecera using(idpersona,idliquidacion)
      natural jOIN ca.liquidacion
      JOIN (     SELECT distinct idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,
                                       to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)  as idcentrocosto
		                       FROM ca.liquidacioncabecera
                                       NATURAL JOIN ca.categoriaempleado
		                       NATURAL JOIN ca.liquidacion 
--Dani comento pq se debe tener en cuenta liq extraordinarias con (mes)fecha pago = (mes)fecha pago actual liq
		                     
                                     -- WHERE limes = elmes and lianio = elanio
                                       WHERE extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio
                                      and (idliquidaciontipo=1   /*or idliquidaciontipo=3   or idliquidaciontipo=6*/)
                                       and((idcategoriatipo=4 or idcategoriatipo=1)  
                                       and (nullvalue(cefechafin) or cefechafin >=to_timestamp(concat(elanio,'-',elmes,'-1') ,'YYYY-MM-DD')::date))      
	                     )   as t_emp_cc using(idpersona)
        --Dani comento pq se debe tener en cuenta liq extraordinarias con (mes)fecha pago = (mes)fecha pago actual liq

        -- WHERE    lianio = elanio AND limes = elmes     AND split_part(idcentrocosto, '|', 1) =  centrocosto 
  WHERE extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio  AND split_part(idcentrocosto, '|', 1) =  centrocosto 
group by idliquidaciontipo
 )as h;
 
else
 

       SELECT INTO respuesta 
  
       (sum(leimpbruto  * split_part(idcentrocosto, '|', 2):: double precision )
                                          - sum(leimpnoremunerativo  * split_part(idcentrocosto, '|', 2):: double precision )
                                          + sum(leimpasignacionfam  * split_part(idcentrocosto, '|', 2):: double precision)
                                          + sum(leimpnoremunerativo  * split_part(idcentrocosto, '|', 2):: double precision)
                                          - sum(leimpasignacionfam  * split_part(idcentrocosto, '|', 2):: double precision) )
        -rtaconceptosindem.valorconcepto   as valor
                   FROM ca.liquidacionempleado
                        JOIN ca.liquidacioncabecera using(idpersona,idliquidacion)
                        JOIN  ca.liquidacion using(idliquidacion)
                        JOIN    ca.empleado using(idpersona)
		        JOIN (     SELECT distinct idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,
                                       to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)  as idcentrocosto
		                       FROM ca.liquidacioncabecera
                                       NATURAL JOIN ca.categoriaempleado
		                       NATURAL JOIN ca.liquidacion 
		                       WHERE limes = elmes and lianio = elanio
                                        and (idliquidaciontipo=2    or idliquidaciontipo=4)
                                       and((idcategoriatipo=4 or idcategoriatipo=1)  
                                       and (nullvalue(cefechafin) or cefechafin >=to_timestamp(concat(elanio,'-',elmes,'-1') ,'YYYY-MM-DD')::date))      
	                     )   as t_emp_cc using(idpersona)
                    WHERE    
		    lianio = elanio AND limes = elmes   AND split_part(idcentrocosto, '|', 1) =  centrocosto /*group by idliquidaciontipo*/; 

RAISE NOTICE 'respuesta.valor   (%)',respuesta.valor;
 

end if;

RAISE NOTICE 'VALOR FINAL ANTES DE COLOCAR EL ALICUOTA Y PORCENTAJE (%)',respuesta.valor;
--Dani 31032023 Cambio el redondeo de 3 a 2 decimales por pedido de JE
valor=round ((  ((respuesta.valor   )*alicuota) + (porcentaje *cempleados))::numeric , 2 );

 
RAISE NOTICE 'VALOR FINAL  (%)',valor;
 
 RETURN valor;

    END;$function$
