CREATE OR REPLACE FUNCTION public.ordenpagoconfiltros_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros record;
BEGIN
 
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_ordenpagoconfiltros_contemporal 
AS (
  SELECT ordenpago.asiento        
	,ordenpago.beneficiario        
	,ordenpago.concepto        
	,ordenpago.fechaingreso        
	,ordenpago.nroordenpago        
	,concat(ordenpago.nroordenpago , ' - ',ordenpago.idcentroordenpago) as nroordenpagocentro       
	,ordenpago.importetotal        
	,ordenpago.idcentroordenpago        
	,concat(ordenpagoimputacion.codigo,' ',cuentascontables.desccuenta) as codigo        
	,ordenpagoimputacion.debe        
	,ordenpagoimputacion.haber        
	,tipoestadoordenpago.nombreestado 
	,t.nroregistroanio      
	,login  
	,'1-Asiento#asiento@2-Beneficiario#beneficiario@3-Concepto#concepto@4-Fecha Ingreso#fechaingreso@5-Nro.Orden Pago
	#nroordenpagocentro@6-Importe#importetotal@7-Descripcion#codigo@8-Debe#debe@9-Haber#haber@11-Estado#nombreestado@10-Nro.Registro#nroregistroanio@12-Usu.Genero#login'::text 
	as mapeocampocolumna
	  FROM ordenpago  
	NATURAL JOIN ordenpagoimputacion
	NATURAL JOIN cambioestadoordenpago  
	NATURAL JOIN tipoestadoordenpago  
	NATURAL JOIN (SELECT DISTINCT factura.idcentroordenpago,factura.nroordenpago,text_concatenar(concat(nroregistro , ' - ',anio,' # ')) as nroregistroanio
			FROM factura 
			GROUP BY nroordenpago,idcentroordenpago
			) as t  
	
	JOIN cuentascontables ON cuentascontables.nrocuentac = ordenpagoimputacion.nrocuentac  
	left join usuario using(idusuario)  
	WHERE nullvalue(ceopfechafin)  
		AND true  
		--AND  fechaingreso >= '2018-03-09'   AND fechaingreso <= '2018-04-14'
		AND  fechaingreso >= rfiltros.fechadesde   AND fechaingreso <= rfiltros.fechahasta
		AND ( idtipoestadoordenpago = 3 OR  idtipoestadoordenpago = 1 OR  idtipoestadoordenpago = 2 )  
	ORDER BY ordenpago.nroordenpago 
DESC
				
);
     

return true;
END;
$function$
