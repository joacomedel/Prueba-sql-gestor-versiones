CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_generaplanilla(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 --select * from convenios_migrarnomencladoryvalores_generaplanilla('{ cual=asociacion}');
--select * from temp_convenios_migrarnomencladoryvalores_generaplanilla_contemporal;
--select * from convenios_migrarnomencladoryvalores_generaplanilla('{ cual=plancobertura, descplan=gene}');
--select * from temp_convenios_migrarnomencladoryvalores_generaplanilla_contemporal

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

IF (rfiltros.cual = 'practicas_asociacion_vinculadas') THEN 
CREATE TEMP TABLE temp_convenios_migrarnomencladoryvalores_generaplanilla_contemporal 
AS (
	select idasocconv as lineaexcel,idasocconv id_siges,acfechaini,acfechafin,text_concatenarsinrepetir(acdecripcion) as nombreasociacion,text_concatenarsinrepetir(asdescripext) as descripcion, text_concatenarsinrepetir(aclocalidad) as localidad, text_concatenarsinrepetir(accontacto_telefono) as contacto_telefono,text_concatenarsinrepetir(accontacto_correo) as contacto_correo, text_concatenarsinrepetir(accuit) as cuit_prestador_vinculado, text_concatenarsinrepetir(acidprestador) as prestador_vinculado,  text_concatenarsinrepetir(acespecialidad) as especialidad, text_concatenarsinrepetir(aclugar_atencion) as lugar_atencion ,  text_concatenarsinrepetir(acgrilla) as grilla, text_concatenarsinrepetir(acresponsable) as responsable ,text_concatenarsinrepetir(case when aconline then 'si' else 'no' end) as sevalidaenlinea , text_concatenarsinrepetir(case when acvalorsindecimal then 'si' else 'no' end) as valorsindecimales,text_concatenarsinrepetir(case when acseusaencoseguro then 'si' else 'no' end) as seusaencoseguro,'SI' as activo, '' as modifica, '' as incorpora
 from asocconvenio 
NATURAL JOIN convenio 
where  acactivo
                    AND (acfechafin >= current_date OR nullvalue(acfechafin))
                    AND (cfinvigencia >= current_date OR nullvalue(cfinvigencia))
group by idasocconv,acfechaini,acfechafin
order by idasocconv


);
     
END IF;


IF (rfiltros.cual = 'asociacion') THEN 
CREATE TEMP TABLE temp_convenios_migrarnomencladoryvalores_generaplanilla_contemporal 
AS (
	select idasocconv as lineaexcel,idasocconv id_siges,acfechaini,acfechafin,text_concatenarsinrepetir(acdecripcion) as nombreasociacion,text_concatenarsinrepetir(asdescripext) as descripcion, text_concatenarsinrepetir(aclocalidad) as localidad, text_concatenarsinrepetir(accontacto_telefono) as contacto_telefono,text_concatenarsinrepetir(accontacto_correo) as contacto_correo, text_concatenarsinrepetir(accuit) as cuit_prestador_vinculado, text_concatenarsinrepetir(acidprestador) as prestador_vinculado,  text_concatenarsinrepetir(acespecialidad) as especialidad, text_concatenarsinrepetir(aclugar_atencion) as lugar_atencion ,  text_concatenarsinrepetir(acgrilla) as grilla, text_concatenarsinrepetir(acresponsable) as responsable ,text_concatenarsinrepetir(case when aconline then 'si' else 'no' end) as sevalidaenlinea , text_concatenarsinrepetir(case when acvalorsindecimal then 'si' else 'no' end) as valorsindecimales,text_concatenarsinrepetir(case when acseusaencoseguro then 'si' else 'no' end) as seusaencoseguro,'SI' as activo, '' as modifica, '' as incorpora
 from asocconvenio 
NATURAL JOIN convenio 
where  acactivo
                    AND (acfechafin >= current_date OR nullvalue(acfechafin))
                    AND (cfinvigencia >= current_date OR nullvalue(cfinvigencia))
group by idasocconv,acfechaini,acfechafin
order by idasocconv


);
     
END IF;

IF (rfiltros.cual = 'plancobertura') THEN 
CREATE TEMP TABLE temp_convenios_migrarnomencladoryvalores_generaplanilla_contemporal 
AS (
	select idplancoberturas,descripcion as descripcionplan
,idnomenclador,idcapitulo,idsubcapitulo,idpractica,ppcperiodo
,case when nullvalue(sinauditoria.cobertura) then 0 ELSE sinauditoria.cobertura END as  coberturasinauditoria
,case when nullvalue(sinauditoria.cantidad) then 0 ELSE sinauditoria.cantidad END as  cantidadsinaudi
,case when nullvalue(sinauditoria.ppcoberturaamuc) then 0 ELSE sinauditoria.ppcoberturaamuc END as  ppcoberturaamucsinaud
,case when nullvalue(sinauditoria.ppcprioridad) then 0 ELSE sinauditoria.ppcprioridad END as  ppcprioridadsinaudi
,case when nullvalue(conauditoria.cobertura) then 0 ELSE conauditoria.cobertura END as  coberturaconauditoria
,case when nullvalue(conauditoria.cantidad) then 0 ELSE conauditoria.cantidad END as  cantidadconaudi
,case when nullvalue(conauditoria.ppcprioridad) then 0 ELSE conauditoria.ppcprioridad END as  ppcprioridadconaudi
,case when nullvalue(conauditoria.ppcoberturaamuc) then 0 ELSE conauditoria.ppcoberturaamuc END as  ppcoberturaamucconaud
--,*
FROM plancobertura
NATURAL JOIN (
SELECT idplancoberturas,idnomenclador,idcapitulo,idsubcapitulo,idpractica,ppcperiodo FROM practicaplan GROUP BY idplancoberturas,idnomenclador,idcapitulo,idsubcapitulo,idpractica,ppcperiodo
) as practicaplan
JOIN practica using(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
LEFT JOIN (
select idplancoberturas,idnomenclador,idcapitulo,idsubcapitulo,idpractica,cobertura,ppccantpractica as cantidad,ppcperiodo,ppcprioridad,serepite,ppcoberturaamuc FROM practicaplan  
WHERE not auditoria
) as sinauditoria USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancoberturas,ppcperiodo)
LEFT JOIN (
select idplancoberturas,idnomenclador,idcapitulo,idsubcapitulo,idpractica,cobertura, ppccantpractica as cantidad,ppcperiodo,ppcprioridad,serepite,ppcoberturaamuc
FROM practicaplan  
WHERE auditoria 
) as conauditoria USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancoberturas,ppcperiodo)
where descripcion ilike concat('%',rfiltros.descplan,'%') AND practica.activo
ORDER BY idplancoberturas,idnomenclador,idcapitulo,idsubcapitulo,idpractica


);
     
END IF;


return true;
END;
$function$
