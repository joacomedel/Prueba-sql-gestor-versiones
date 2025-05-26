CREATE OR REPLACE FUNCTION public.far_cantidadarticuloactivos(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD 
rfiltros VARCHAR;
--VARCHAR
pcantidad INTEGER;

BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--busco la cantidad de articulos activos de la farma
SELECT INTO pcantidad COUNT(*) 
FROM far_lote  NATURAL JOIN far_articulo
WHERE aactivo AND idcentrolote = centro() 
/*AND  (CASE WHEN nullvalue(rfiltros.fechadesde) THEN nullvalue(rfiltros.fechadesde) ELSE lfechamofificacion >=rfiltros.fechadesde::date END)
AND 
(CASE WHEN nullvalue(rfiltros.fechahasta) THEN nullvalue(rfiltros.fechahasta) ELSE lfechamofificacion <=rfiltros.fechahasta::date END)
*/
and lstock <>0
;


RETURN  pcantidad::varchar;
END;
$function$
