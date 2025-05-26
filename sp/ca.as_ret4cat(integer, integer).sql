CREATE OR REPLACE FUNCTION ca.as_ret4cat(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a retenciones de 4 categoria
* PRE: el asiento debe estar creado

*/
DECLARE
            laformula varchar;
      elmes integer;
      elanio integer;

      respuesta record;
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

    SELECT  INTO respuesta 	case when nullvalue(sum(ceporcentaje* cemonto)) then 0 else  sum(ceporcentaje* cemonto) end as calculo
    FROM  ca.conceptoempleado
	NATURAL JOIN ca.liquidacion
	WHERE (idconcepto=989 or idconcepto=1129 or idconcepto=1130 or idconcepto=1170
      or idconcepto=1190 or idconcepto=1193 or idconcepto=1196  or idconcepto=1201
or idconcepto=1154  or idconcepto=1202 or idconcepto=1264
or idconcepto=1196 or idconcepto=1209 or idconcepto=1221 or idconcepto=1238 or idconcepto=1247 or idconcepto=1255 or idconcepto=1277 or idconcepto=1281 or idconcepto=1287 or idconcepto=1292) and limes=elmes and lianio=elanio and(idliquidaciontipo=1 or idliquidaciontipo=2);

-- Agrego vas 11-03
if (respuesta.calculo>=0) THEN
-- El asiento debe afectar haber
     UPDATE  ca.asientosueldotipoctactble SET ascactivo = true
     WHERE nrocuentac=20712 and asvigente;
ELSE
-- El asiento debe afectar al debe
     UPDATE  ca.asientosueldotipoctactble SET ascactivo = false
     WHERE nrocuentac=20712 and asvigente;
END IF;
return abs(respuesta.calculo);

END;
$function$
