CREATE OR REPLACE FUNCTION public.listado_monodrogas(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/**/
DECLARE
    rparam RECORD;
    respuesta character varying;

    

BEGIN
    respuesta = '';
    EXECUTE sys_dar_filtros($1) INTO rparam;
    
    CREATE TEMP TABLE temp_listado_monodrogas AS (

       	
	 select 
     mnroregistro, mcodbarra as "Cod. Barra" , mtroquel as "Troquel",mnombre as "Medicamento", mpresentacion as "Presentación",monnombre as "Monodroga",idmonodroga, afdescripcion as "Acc. Far.",to_char(vmimporte, 'FM9999999999.00') AS "Precio" ,ftvdescripcion as "Tipo Venta" ,LEFT(lnombre,length(lnombre)-1) as "Laboratorio",'1-MNroRegistro#mnroregistro@2-CodigoBarra#Cod. Barra@3-Troquel#Troquel@4-Medicamento#Medicamento@5-Presentacion#Presentación@6-Monodroga#Monodroga@7-AccionFarmacologica#Acc. Far.@8-Precio#Precio@9-TipoVenta#Tipo Venta@10-Laboratorio#Laboratorio'::text as mapeocampocolumna
	
    from  valormedicamento 
    natural join medicamento
    natural join farmtipoventa
    natural join manextra
    left join laboratorio using (idlaboratorio)
    natural join monodroga natural join acciofar
    natural join formas natural join vias
    where nullvalue(vmfechafin)   and vmfechaini >= rparam.fecha 
	order by mnombre, mpresentacion
    ); 
 
return respuesta;
end;

$function$
