CREATE OR REPLACE FUNCTION ca.as_contribucionessatf(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/*
* Inicializa el asiento correspondiente a aquellos en los cuales solo se debe calcular contribuciones de sindicato
* PRE: el asiento debe estar creado
*/
/*
 A + B + C 
Donde A = SUM(BASICOS * 0,01) establecido por articulo 46 y se debe calcular hasta la liquidación <febrero2014 
Donde B = SUM(BASICOS * 0,01) 
Donde C = (CantidadEmpleados * 150)  y  150 es una suma 
fija establecida por convenio de farmacia  <abril 2013 
se calcula solo para farmacia
*/
DECLARE
            A varchar;
            B varchar;
            C varchar;
      elmes integer;
      elanio integer;
      respuestaA record;
       respuestaB record;
        respuestaC record;
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio=$2;

 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */

   A=concat(' select
	case when nullvalue(sum(ceporcentaje* cemonto)) then 0 else
 sum(ceporcentaje* cemonto*0.01) end as calculo
from ca.conceptoempleado 
	natural join ca.liquidacion
		where 
		
		idliquidaciontipo=2 and  idconcepto=',1028,' and limes=',elmes,'  and  lianio=',elanio, 'and ((limes<2 and lianio<=2014)or lianio<=2014 )');

EXECUTE A INTO respuestaA;

  B=concat(' select
	case when nullvalue(sum(ceporcentaje* cemonto)) then 0 else
 sum(ceporcentaje* cemonto*0.01) end as calculo
from ca.conceptoempleado 
	natural join ca.liquidacion
		where 
		
		idconcepto=',1028,' and idliquidaciontipo=2 and limes=',elmes,'  lianio=',elanio);


EXECUTE B INTO respuestaB;


  C=concat(' select
	count(*)*150 from  ca.liquidacion natural join ca.liquidacionempleado
		where 
		
		idliquidaciontipo=2 and limes=',elmes,' and  lianio=',elanio, ' ((and limes<4 and lianio<=2013)or lianio<=2013)');




EXECUTE C INTO respuestaC;

return respuestaA.calculo+respuestaB.calculo+respuestaC.calculo;
END;
$function$
