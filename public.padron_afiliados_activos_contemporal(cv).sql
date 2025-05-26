CREATE OR REPLACE FUNCTION public.padron_afiliados_activos_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_padron_afiliados_activos_contemporal AS (
  SELECT *, 
 '1-titular#titular@2-nroafiliado#nroafiliado@3-barra#barra@4-nombres#nombres@5-apellido#apellido@6-email#email@7-telefono#telefono@8-tipodoc#tipodoc@9-nrodoc#nrodoc@10-sexo#sexo@10-fechanac#fechanac@11-edad#edad@12-fechainios#fechainios@13-condicionafiliado#condicionafiliado@14-codpostal#codpostal@15-barra#barra@16-grupofamiliar#grupofamiliar@17-barragrupofamiliar#barragrupofamiliar@18-LocalidadPersona#localidad_persona@19-osexterna#osexterna@20-localidadCargo#localidad_cargo'::text as mapeocampocolumna  FROM(
/*
       SELECT 
           CASE when nullvalue(nrodoctitular) THEN 'TITULAR' ELSE 'BENEFICIARIO' END as titular
           ,CONCAT(nrodoc,persona.barra) as nroafiliado
           ,persona.barra
           ,nombres
           ,apellido
           ,email
           ,telefono
           ,tiposdoc.descrip as tipodoc
           ,lpad(nrodoc,8,'0') as nrodoc 
           ,persona.sexo
           ,to_char(fechanac,'YYYYMMDD') as fechanac
           , date_part('year',age(fechanac))::text  as edad
           ,to_char(fechainios,'YYYYMMDD') as fechainios
           ,CASE WHEN (persona.barra = 35 OR persona.barra = 36 OR barratitular.barra = 35 OR barratitular.barra = 36) THEN 'J' ELSE 'O' END as condicionafiliado
           ,rpad(CASE WHEN nullvalue(codpostal) THEN '0000' ELSE codpostal END,4,'0')::numeric as codpostal
           
           ,CASE when nullvalue(nrodoctitular) THEN concat(persona.barra,'-',persona.nrodoc) ELSE nrodoctitular END as grupofamiliar
           ,CASE when nullvalue(nrodoctitular) THEN persona.barra::text ELSE substring(nrodoctitular FROM '^([^\\-]*)')  END as barragrupofamiliar
           ,CASE when nullvalue(idlocalidad) THEN '' ELSE localidad.descrip END as localidad
           ,CASE when (nullvalue(nrodoctitular)) THEN (case when (afilsosunc.idosexterna <> 0) Then osexterna.abreviatura else '' end  )   ELSE ( case when (nullvalue(osexterna) or barratitular.idosexterna = 0 ) then '' else osexterna end)  END as osexterna
        FROM persona
        join tiposdoc using(tipodoc)
        LEFT JOIN direccion USING(iddireccion,idcentrodireccion)
        LEFT JOIN localidad USING(idlocalidad)
        LEFT JOIN (
              SELECT   
                 personatitular.barra 
                 ,persona.nrodoc
                 ,persona.tipodoc
                 ,concat(personatitular.barra,'-:',personatitular.nrodoc) as nrodoctitular 
                 ,osexterna.idosexterna 
                 ,abreviatura as osexterna
              FROM persona 
              NATURAL JOIN benefsosunc
              JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
              left join osexterna using (idosexterna)
              WHERE persona.barra < 30 AND persona.tipodoc = 1
               
              ) as barratitular USING(nrodoc,tipodoc) 
        LEFT join afilsosunc using(nrodoc,tipodoc )
        left join osexterna on (afilsosunc.idosexterna = osexterna.idosexterna)-- as tosexterna
        WHERE 
        --Malapi 29-08-2022 Comenta porque reporte jubilados que ya no tienen que tener cobertura... este reporte se usa para reportes de control... tiene que reflejar lo que corresponde.
        -- Malapi 29-08-2022 Me comentan por que es necesario esto ? 
        --(CASE WHEN (persona.barra = 35 OR persona.barra = 36 OR barratitular.barra = 35 OR barratitular.barra = 36)  THEN fechafinos+90  ELSE fechafinos   END) >= rparam.fecha::date
            fechafinos >= rparam.fecha::date
           AND persona.tipodoc = 1
           AND persona.nrodoc <> '10000000'  
           AND persona.nrodoc <> '00000001'
           AND persona.barra <100
        ORDER BY grupofamiliar*/


WITH UltimoCargo AS (
-- Busco todos los cargos y solo filtro por la mas reciente en caso de que tenga dos
  SELECT  nrodoc, iddepen, du.descrip AS descrip_depuni, fechainilab, fechafinlab, iddireccion, l.descrip AS descrip_loc,
  	ROW_NUMBER() OVER (PARTITION BY nrodoc ORDER BY fechainilab DESC) as rn --Ordeno los cargos mas recientes primero
      	FROM cargo
  	NATURAL JOIN depuniversitaria du
  	NATURAL JOIN direccion d
  	LEFT JOIN localidad l USING (idlocalidad)
 -- where fechafinlab>=current_date
)


SELECT
       	CASE when nullvalue(nrodoctitular) THEN 'TITULAR' ELSE 'BENEFICIARIO' END as titular
        ,case when nullvalue(nrodoctitu) then  persona.nrodoc else nrodoctitu end AS nrodoctitu 
        ,case when nullvalue(uc.descrip_loc) then  sub_descrip_loc else uc.descrip_loc end AS localidad_cargo
        ,laloc.descrip AS localidad_persona
       	,CONCAT(persona.nrodoc,persona.barra) as nroafiliado
       	,persona.barra
       	,nombres
       	,apellido
       	,email
       	,telefono
       	,tiposdoc.descrip as tipodoc
       	,lpad(persona.nrodoc,8,'0') as nrodoc
       	,persona.sexo
       	,to_char(fechanac,'YYYYMMDD') as fechanac
       	, date_part('year',age(fechanac))::text  as edad
       	,to_char(fechainios,'YYYYMMDD') as fechainios
       	,CASE WHEN (persona.barra = 35 OR persona.barra = 36 OR barratitular.barra = 35 OR barratitular.barra = 36) THEN 'J' ELSE 'O' END as condicionafiliado
       	,rpad(CASE WHEN nullvalue(codpostal) THEN '0000' ELSE codpostal END,4,'0')::numeric as codpostal
      	 
       	,CASE when nullvalue(nrodoctitular) THEN concat(persona.barra,'-',persona.nrodoc) ELSE nrodoctitular END as grupofamiliar
       	,CASE when nullvalue(nrodoctitular) THEN persona.barra::text ELSE substring(nrodoctitular FROM '^([^\\-]*)')  END as barragrupofamiliar
      	 
       	,CASE when (nullvalue(nrodoctitular)) THEN (case when (afilsosunc.idosexterna <> 0) Then osexterna.abreviatura else '' end  )   ELSE ( case when (nullvalue(osexterna) or barratitular.idosexterna = 0 ) then '' else osexterna end)  END as osexterna
	/*
,'1-titular#titular@2-nroafiliado#nroafiliado@3-barra#barra@4-nombres#nombres@5-apellido#apellido@6-email#email@7-telefono#telefono@8-tipodoc#tipodoc@9-nrodoc#nrodoc@10-sexo#sexo@10-fechanac#fechanac@11-edad#edad@12-fechainios#fechainios@13-condicionafiliado#condicionafiliado@14-codpostal#codpostal@15-barra#barra@16-grupofamiliar#grupofamiliar@17-barragrupofamiliar#barragrupofamiliar@18-LocalidadPersona#localidad_persona@19-osexterna#osexterna@20-LocalidadCargo#localidad_cargo'::text as mapeocampocolumna*/
FROM persona
   	join tiposdoc using(tipodoc)
   	left JOIN UltimoCargo AS uc ON (uc.nrodoc = persona.nrodoc and uc.rn = 1)
  	 
   JOIN direccion ladire ON (persona.iddireccion = ladire.iddireccion AND persona.idcentrodireccion = ladire.idcentrodireccion)
   LEFT JOIN localidad laloc ON (ladire.idlocalidad = laloc.idlocalidad)


    	LEFT JOIN (
          	SELECT   
             	personatitular.barra
             	,persona.nrodoc
             	,persona.tipodoc
             	,concat(personatitular.barra,'-:',personatitular.nrodoc) as nrodoctitular
             	,osexterna.idosexterna
             	,abreviatura as osexterna
                ,nrodoctitu
                ,tipodoctitu
                ,uc_sub.descrip_loc AS sub_descrip_loc
          	FROM persona
          	NATURAL JOIN benefsosunc
          	JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
          	left join osexterna using (idosexterna)
                left JOIN UltimoCargo AS uc_sub ON (uc_sub.nrodoc = nrodoctitu and uc_sub.rn = 1)
          	WHERE persona.barra < 30 AND persona.tipodoc = 1
          	 
          	) as barratitular
--USING(nrodoc,tipodoc)
on(persona.nrodoc=barratitular.nrodoc and persona.tipodoc=barratitular.tipodoc )
    	LEFT join afilsosunc on(afilsosunc.nrodoc=barratitular.nrodoc and afilsosunc.tipodoc=barratitular.tipodoc )
    	left join osexterna on (afilsosunc.idosexterna = osexterna.idosexterna)-- as tosexterna
    	WHERE
                	 
         	persona.tipodoc = 1
       	AND persona.nrodoc <> '10000000'  
       	AND persona.nrodoc <> '00000001'
       	AND persona.barra <100
 
  	AND persona.fechafinos >= now()
 
  	ORDER BY grupofamiliar
 

       )as tpadron);
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
