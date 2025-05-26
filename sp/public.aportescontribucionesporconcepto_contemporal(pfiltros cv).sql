CREATE OR REPLACE FUNCTION public.aportescontribucionesporconcepto_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

if (rfiltros.idtipo='DH21')
then
CREATE TEMP TABLE temp_aportescontribucionesporconcepto_contemporal
AS (
	
select   nroconcepto,importe::numeric,mesingreso,anioingreso,nrodoc,apellido,nombres,legajosiu,nrocargo,
	'1-nroconcepto#nroconcepto@2-importe#importe@3-mesingreso#mesingreso@4-anioingreso#anioingreso@5-nrodoc#nrodoc@6-apellido#apellido@7-nombres#nombres@8-legajosiu#legajosiu@9-nrocargo#nrocargo@10-importe#importe@11-unidadacademica#unidadacademica@12-mesretroactivo#mesretroactivo@13-anioretroactivo#anioretroactivo'::text as mapeocampocolumna 


from 
dh21
join cargo
on( nrocargo=idcargo)
join persona using(nrodoc,tipodoc)
where 
( nullvalue(rfiltros.mesingreso) or mesingreso=rfiltros.mesingreso)
and (   anioingreso=rfiltros.anioingreso)
and (nullvalue(rfiltros.nrodoc) or nrodoc=rfiltros.nrodoc)

and (nullvalue(rfiltros.nroconcepto) or nroconcepto=rfiltros.nroconcepto)
order by anioingreso,mesingreso,nrodoc,nroconcepto

  );


else 
CREATE TEMP TABLE temp_aportescontribucionesporconcepto_contemporal
AS (

/*
importe
unidadacademica 	
mesretroactivo 
anioretroactivo

*/

select   mesingreso,anioingreso,nrodoc,apellido,nombres,apellidoynombre,categoria,unidadacademica,legajosiu,nrocargo,nroliquidacion,fechaalta,fechabaja,importebruto::numeric,
	'1-mesingreso#mesingreso@2-anioingreso#anioingreso@3-nrodoc#nrodoc@4-apellido#apellido@5-nombres#nombres@6-apellidoynombre#apellidoynombre@7-categoria#categoria@8-unidadacademica#unidadacademica@9-legajosiu#legajosiu@10-nrocargo#nrocargo@11-nroliquidacion#nroliquidacion@12-fechaalta#fechaalta@13-nroliquidacion#nroliquidacion@14-fechabaja#fechabaja@15-importebruto#importebruto'::text as mapeocampocolumna 
 
from 
dh49
join cargo
on( nrocargo=idcargo)
join persona using(nrodoc,tipodoc)
where 
( nullvalue(rfiltros.mesingreso) or  mesingreso=rfiltros.mesingreso)
and ( anioingreso=rfiltros.anioingreso)
and (nullvalue(rfiltros.nrodoc) or nrodoc=rfiltros.nrodoc)

order by anioingreso,mesingreso,nrodoc,nroliquidacion 

  );
end if;
return true;
END;
$function$
