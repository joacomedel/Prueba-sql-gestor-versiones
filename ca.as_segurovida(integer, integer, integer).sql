CREATE OR REPLACE FUNCTION ca.as_segurovida(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a seguro de vida (tipoasiento=1)
* PRE: el asiento debe estar creado
* centro costo --liquidacion
	Obra social--1 /3
	Farmacia---2/4
	teatro--1 /3
*
* 4.1 * CE vigente a partir de septiembre del 2014
*/
DECLARE
      codasiento integer;
      rasientotipo record;
      regformula record;
      centrocosto integer;
      laformula varchar;
      elasiento integer;
      elmes integer;
      elanio integer;
      condicioncentro varchar;
      respuesta record;
      alicuota double precision;
      primer_dia_liq date;
      rtopes record;
      cempleados double precision;

BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1; 
     elanio=$2;
     centrocosto =$3;
     cempleados = 0;
 
 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble
      

  */
  
  -----------------------------
-- Recupero los topes para el periodo correspondiente
-----------------------------
   primer_dia_liq =  concat(elanio,'-',elmes,'-01');


 
   SELECT INTO rtopes *
   FROM ca.formulatope
   WHERE idformula =103 and primer_dia_liq >= astcctfechadesde   
         and   (primer_dia_liq <= astcctfechahasta or nullvalue(astcctfechahasta));
   alicuota = rtopes.astcctmontoalicuota;

   -------------------------------------
   --SELECT INTO cempleados  * FROM  ca.cantempleados(elmes,elanio,centrocosto);
   
  
	


 
SELECT  INTO cempleados
    SUM(eccporcentual)
FROM ca.afip_situacionrevistaempleado
 natural join 
(select  	idpersona,max(asrafechadesde)as asrafechadesde
from ca.afip_situacionrevistaempleado
where ( asrefechahasta>=to_timestamp(concat(elanio,'-',elmes  ,'-01') ,'YYYY-MM-DD')::date or nullvalue(asrefechahasta) )
--Dani agrega 02102023
and asrafechadesde<to_timestamp(concat(elanio,'-',elmes  ,'-01') ,'YYYY-MM-DD')::date + interval '1 month'
group by idpersona
) as t
natural join ca.empleadocentrocosto
WHERE            
idcentrocosto = centrocosto         and     
( asrefechahasta>=to_timestamp(concat(elanio,'-',elmes  ,'-01') ,'YYYY-MM-DD')::date or nullvalue(asrefechahasta) );



 RAISE NOTICE ' alicuouta * cempleados (%)(%)',alicuota,cempleados;
               
return alicuota * cempleados ;
 

END;$function$
