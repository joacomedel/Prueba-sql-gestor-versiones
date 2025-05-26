CREATE OR REPLACE FUNCTION public.listadocorreosemitidos_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_listadocorreosemitidos_contemporal AS (
  SELECT *, 
 '1-FechaRecepcion#fecharecepcion@2-Nombre#nombrerecepcion@3-Apellido#apellidorecepcion@4-NombreEntrego#nombreentrega@5-ApellidoEntrego#apellidoentrega@6-FechaEntrega#fechaentrega@7-Correo#nombrecorreo@8-Destinatario#destinatario@9-Descripcion#descripcion'::text as mapeocampocolumna  
  FROM(
SELECT  recepcion.fecha as fecharecepcion,recepcion.nombre as nombrerecepcion,recepcion.apellido as apellidorecepcion, 
--idrecepcion,idplanillacorreo,planillacorreo.idcorreo,entrega.identrega,planillacorreo.idcentroregional,recepcion.idcomprobante,
entrega.nombre as nombreentrega, entrega.apellido as apellidoentrega,entrega.fecha as fechaentrega,idtipoentrega,nombrecorreo,destinatario,descripcion, idtiporecepcion  FROM planillacorreo  NATURAL JOIN entrega  NATURAL JOIN correo  JOIN recitemcorreo USING(idplanillacorreo)  JOIN recepcion USING(idrecepcion) 
 WHERE  true  AND correo.idcorreo = rparam.idcorreo
and entrega.fecha>=rparam.fechadesde and entrega.fecha<=rparam.fechahasta
--correo.idcorreo =rparam.idcorreo
    )as tpadron)
order by fechaentrega;
 
   
 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
