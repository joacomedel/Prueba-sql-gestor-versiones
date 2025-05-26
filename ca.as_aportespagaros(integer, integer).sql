CREATE OR REPLACE FUNCTION ca.as_aportespagaros(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a aportes a pagar obra social (tipoasiento=1)
* PRE: el asiento debe estar creado

*/
DECLARE
       
        elmes integer;
	elanio integer;
	respuesta record;
        laformula varchar;
        nuevotope  DOUBLE PRECISION; 
	elmontotope record;
        valor double precision;

BEGIN
   
     SET search_path = ca, pg_catalog;
    elmes = $1;  
     elanio = $2;
     valor=0;

nuevotope  =0;

 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */

          select into elmontotope * FROM ca.conceptotope
                                             WHERE  idconcepto = 200
                                          and nullvalue(ctfechahasta);

          nuevotope  =elmontotope.ctmontomaximo;


          select into respuesta 
            
                 0.0255* sum (case when 
                                     (leimpbruto-leimpnoremunerativo)>nuevotope   then  nuevotope
                                    else( leimpbruto-leimpnoremunerativo)   end ) as calculo
         
              
          from ca.liquidacionempleado
          natural join ca.liquidacion
          natural join ca.liquidacioncabecera
          where (idliquidaciontipo=2 or idliquidaciontipo=4) and lianio=elanio  and limes=elmes;

          valor=respuesta.calculo;
return 	valor;
END;
$function$
