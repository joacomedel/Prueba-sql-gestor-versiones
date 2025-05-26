CREATE OR REPLACE FUNCTION public.far_cargarhistoricocodigobarra(pparametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$ 
DECLARE

--RECORD 
   relarticulo RECORD;
   rfiltros RECORD;
   rhistoricoarticulo RECORD;
--VARIABLES 
 
BEGIN
    

   EXECUTE sys_dar_filtros(pparametro) INTO rfiltros;
   rfiltros.acodigobarra = replace(rfiltros.acodigobarra,'::varchar','');
 
  
   SELECT INTO relarticulo * 
   FROM far_articulo 
   LEFT JOIN far_medicamento USING(idarticulo, idcentroarticulo) 
   WHERE 
         (idarticulo = rfiltros.idarticulo  OR nullvalue(rfiltros.idarticulo)) AND
         (idcentroarticulo = rfiltros.idcentroarticulo  OR nullvalue(rfiltros.idcentroarticulo)) AND
         (acodigobarra = rfiltros.acodigobarra  OR nullvalue(rfiltros.acodigobarra)) AND
         (mnroregistro = rfiltros.mnroregistro  OR nullvalue(rfiltros.mnroregistro));

  
   IF FOUND THEN 
      SELECT INTO rhistoricoarticulo * FROM far_articulocodigobarra WHERE acbcodigobarra = relarticulo.acodigobarra;
      
      IF NOT FOUND THEN 
         UPDATE far_articulocodigobarra SET acbfechafin = NOW() WHERE idarticulo = relarticulo.idarticulo AND idcentroarticulo = relarticulo.idcentroarticulo AND nullvalue(acbfechafin);
         
         INSERT INTO far_articulocodigobarra(acbcodigobarra,acbmnroregistro,acbidusuario,idarticulo,idcentroarticulo)
         VALUES (relarticulo.acodigobarra, relarticulo.mnroregistro,sys_dar_usuarioactual(),relarticulo.idarticulo,relarticulo.idcentroarticulo);
      
      ELSE 
         UPDATE far_articulocodigobarra SET acbfechacobbarrareuso = NOW() WHERE idarticulo = relarticulo.idarticulo AND idcentroarticulo = relarticulo.idcentroarticulo; 
      END IF;
   ELSE
          RAISE NOTICE 'Error raro (%)',pparametro;
   END IF;

   return pparametro;
 
END;
$function$
