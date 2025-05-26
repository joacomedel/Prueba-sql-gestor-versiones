CREATE OR REPLACE FUNCTION ca.as_contribucionessindicato(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a aquellos en los cuales solo se debe calcular contribuciones de sindicato
* PRE: el asiento debe estar creado
*/
/*
 A + B + C 
Donde A = SUM(BASICOS * 0,01) establecido por articulo 46 
Donde B = SUM(BASICOS * 0,01)  teniendo en cuenta el basico con escala es decir el basico q se tiene en cuenta cuando hay casos de q el empleado trbajo menos dias q los acordados por basico.Por ej cuando se descuentan dias por alguna razon...
Donde C = (CantidadEmpleados * valor fijo) 
Valor fijo =125 entre enero y agosto 2014
Valor fijo =175 para agosto 2014
Valor fijo =160 a partir de septiembre 2014
Valor fijo =235 a partir de Mayo 2016
Valor fijo =250 a partir de Abril 2017
Valor fijo =720 a partir de Mayo 2019
Valor fijo =950 a partir de Octubre 2019
Valor fijo =490 a partir de Julio 2020
Valor fijo =630 a partir de Octubre 2020
se calcula solo para farmacia
*/
DECLARE
            
        A varchar;
        B varchar;
        C varchar;
           
        elmes integer;
        elanio integer;
        centrocosto integer;
        respuesta record;
        montofijo integer;
        cantmult double precision;
        cant integer;
        total_basicos double precision;
        resultado double precision;

       
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio=$2;
     centrocosto = $3;  
    -- montofijo=1050;
   --  montofijo=4170;
--  montofijo=6000; po rpedido de JE cambia el 03122024
-- montofijo=7000;
montofijo=7500;

 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */
/*Dani cambio por pedido de Julieta E. el 23-11-2015 para q calcule en base al basico de categoria*/

  
/*Dani cambio el 28-12-2015 liquidacionempleado por liquidacioncabecera pq diciembre se coloco or error de Sector Personal que Cinthia trabajo un dia en diciembre lo cual genero una liquidacion especial por un dia...
*/
-- VAS 01032016 depuro y reimplemento sacando los concat
     

--Dani agrego 031022 las lic por maternidad por pedido de JE

SELECT  into total_basicos  sum(lcbasico) * 0.01
from
(

    SELECT    sum(lcbasico)  as lcbasico 
      FROM ca.liquidacion
      NATURAL JOIN  ca.liquidacioncabecera  
      WHERE     idliquidaciontipo=2 
	        and limes=elmes and  lianio=elanio  
 union

   SELECT camonto   as lcbasico       
    FROM ca.categoriaempleado
    natural JOIN ca.categoriatipoliquidacion
    natural JOIN  ca.afip_situacionrevistaempleado natural join ca.afip_situacionrevista          
    --Dani agrego 01062023 para q esta parte no encuentre legajos encontrados en la primer parte
    left JOIN  ca.liquidacioncabecera      using(idpersona)
    left JOIN  ca.liquidacion using(idliquidacion)
  
    WHERE   idcategoriatipo = 1  
          and (nullvalue(cefechafin)or cefechafin >=to_timestamp(concat(elanio,'-',elmes,'-1') ,'YYYY-MM-DD')::date )
          and   (idafip_situacionrevista=5 or idafip_situacionrevista=10)and  ( asrefechahasta>=to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date or nullvalue(asrefechahasta) )
          and  ca.liquidacion.idliquidaciontipo=2 
and nullvalue(ca.liquidacioncabecera.idliquidacion)
and limes=elmes and lianio=elanio
   
) as g; 

  

  -- SELECT INTO  cantmult  sum(t.cant)  *  montofijo
select INTO  cantmult count(*)*montofijo
 from
( 
    
      SELECT   idpersona  --count(*) as cant
      FROM ca.liquidacion 
      NATURAL JOIN ca.liquidacioncabecera
      WHERE  ca.liquidacion.idliquidaciontipo=2 and limes=elmes and lianio=elanio 
UNION
    SELECT idpersona  -- count(*)  as cant
    FROM ca.categoriaempleado
    natural JOIN ca.categoriatipoliquidacion
    natural JOIN  ca.afip_situacionrevistaempleado natural join ca.afip_situacionrevista            
    WHERE   idcategoriatipo = 1  
          and (nullvalue(cefechafin)or cefechafin >=to_timestamp(concat(elanio,'-',elmes,'-1') ,'YYYY-MM-DD')::date )
          and   (idafip_situacionrevista=5  or idafip_situacionrevista=10) and  ( asrefechahasta>=to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date or nullvalue(asrefechahasta) )
          and  idliquidaciontipo=2 
 
) as t;

 



      resultado = 2 * total_basicos + cantmult;
      IF nullvalue(resultado) THEN
		resultado = 0;
      END IF;

return resultado;



END;
$function$
