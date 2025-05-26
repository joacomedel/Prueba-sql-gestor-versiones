CREATE OR REPLACE FUNCTION public.afiliaciones_subsidiofalle_darindicadores(pfiltros character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/* Recupera la informacion cargada desde SigesWeb, sobre subsidios por fallecimiento */

DECLARE
	rfiltros record;
	rusuario RECORD;
	resultado TEXT;
	vfila TEXT;
	rcargadas RECORD;
	rprocesadas RECORD;
	--rweb RECORD;
	--vnocambio boolean;
	--vnofilacambio boolean;
	vcolor TEXT;
    vbgcolor TEXT;

BEGIN
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

--vnocambio= true;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
vcolor ='#ca9f5e';
vbgcolor = '';

select INTO rcargadas count(nrodoctitu) as cantidad 
FROM (
select 1 as id,nrodoctitu,tipodoctitu 
from w_afiliacion_declara_subsidio as ad 
LEFT JOIN w_afiliacion_declara_subsidio_procesado USING(idafiliaciondeclarasubsidio) 
WHERE nullvalue(adsfechafinvigencia) AND nullvalue(adspfechaproceso)  
GROUP BY nrodoctitu,tipodoctitu
) as cargadas; 

select INTO rprocesadas count(nrodoctituprocesadas) as cantidad
FROM (
select 1 as id, nrodoctitu as nrodoctituprocesadas 
from w_afiliacion_declara_subsidio as ad 
JOIN w_afiliacion_declara_subsidio_procesado USING(idafiliaciondeclarasubsidio) 
WHERE nullvalue(adsfechafinvigencia) AND not nullvalue(adspfechaproceso)  
GROUP BY nrodoctitu,tipodoctitu
) as cargadasprocesadas;

resultado = concat('<div><span><b>Indicadores en los cambios en la Declaracion Jurada  .</b></span>');
resultado = concat(resultado,'<table border="1" style="border-collapse:collapse;border-color:#ddd;" ><tr><th>Cargadas</th><th>Procesadas</th><th>Total</th></tr>');
resultado = concat(resultado,'<tr><td>',rcargadas.cantidad,'</td><td>',rprocesadas.cantidad,'</td><td>',rprocesadas.cantidad + rcargadas.cantidad,'</td></tr>');



--RAISE NOTICE 'Lala (%),(%),(%)',rfiltros.nrodoc,rfiltros.tipodoc,rpersona;
    
resultado = concat(resultado,'</table> </div>'::text);
return resultado;
END;
$function$
