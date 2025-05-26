CREATE OR REPLACE FUNCTION public.listado_monodrogas()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/**/
DECLARE
    rparam RECORD;
    respuesta character varying;

    rcontrolcaja record; 

    idcajero integer;
    elidcontrolcaja  BIGINT;
    elcentroiddcontrolcaja  integer;

BEGIN
    respuesta = '';
   -- EXECUTE sys_dar_filtros($1) INTO rparam;
    
    CREATE TEMP TABLE temp_listado_monodrogas AS (

       	
	 select 
     mnroregistro, mcodbarra , mtroquel ,mnombre , mpresentacion ,monnombre , idmonodroga, afdescripcion ,to_char(vmimporte, 'FM9999999999.00') AS Precio ,ftvdescripcion ,LEFT(lnombre, length(lnombre)-1) as "Laboratorio",'1-MNroRegistro#mnroregistro@2-CodBarra#mcodbarra@3-Troquel#mtroquel@4-Medicamento#mnombre@5-Presentacion#mpresentacion@6-Monodroga#monnombre@7-IdMonodroga#idmonodroga@8-Descripcion#afdescripcion@9-Precio#Precio@10-TipoVenta#ftvdescripcion'::text as mapeocampocolumna
	
    from  valormedicamento 
    natural join medicamento
    natural join farmtipoventa
    natural join manextra
    left join laboratorio using (idlaboratorio)
    natural join monodroga natural join acciofar
    natural join formas natural join vias
    where nullvalue(vmfechafin)   and vmfechaini >= '2022-01-01'	 
	order by mnombre, mpresentacion
    ); 
 
return respuesta;
end;

$function$
