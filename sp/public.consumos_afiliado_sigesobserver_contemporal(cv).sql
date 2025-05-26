CREATE OR REPLACE FUNCTION public.consumos_afiliado_sigesobserver_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN
     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_consumos_afiliado_sigesobserver_contemporal AS (

            SELECT
*
FROM 
(
SELECT
count(*) as cantidad
,roopf
,roidfarmacia
,rofarmacia
,rofechaprescripcion
,rofechaventa
,rofechasolicitud
,rofechaanulacion
,roautorizada
,ronroreceta
,ronroafiliado
,rotipomatricula
,romatricula
,roimportereceta
,roimporteos
,roimporteafiliado
,rocodigorechazo
,romotivorechazo
,rorenglon
,rocodigoalfabeta
,rotroquel
,rocodbarras
,rocantidad

FROM recetaobserver
WHERE roautorizada='S' OR NOT nullvalue(rofechaanulacion)
GROUP BY roopf
,roidfarmacia
,rofarmacia
,rofechaprescripcion
,rofechaventa
,rofechasolicitud
,rofechaanulacion
,roautorizada
,ronroreceta
,ronroafiliado
,rotipomatricula
,romatricula
,roimportereceta
,roimporteos
,roimporteafiliado
,rocodigorechazo
,romotivorechazo
,rorenglon
,rocodigoalfabeta
,rotroquel
,rocodbarras
,rocantidad
) as filtrado
--WHERE
 -- rofechaventa>= '2022-01-01'   AND   rofechaventa<= '2022-08-30'


       );
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
