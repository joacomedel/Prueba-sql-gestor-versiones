CREATE OR REPLACE FUNCTION public.padron_reciprocidades_activas_contemporal(rparam character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN

     respuesta = '' ;
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_padron_reciprocidades_activas_contemporal AS (
  SELECT *, 
 '1-titular#titular@2-nroafiliado#nroafiliado@3-barra#barra@4-nombres#nombres@5-apellido#apellido@6-email#email@7-telefono#telefono@8-tipodoc#tipodoc@9-nrodoc#nrodoc@10-sexo#sexo@10-fechanac#fechanac@11-edad#edad@12-fechainios#fechainios@13-codpostal#codpostal@14-barra#barra@15-grupofamiliar#grupofamiliar@16-barragrupofamiliar#barragrupofamiliar@17-localidad#localidad@18-reciprocidad#reciprocidad'::text as mapeocampocolumna  FROM(
-- CREATE TABLE temp_padron_afiliados_activos_contemporal_malapi AS (
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
           ,rpad(CASE WHEN nullvalue(codpostal) THEN '0000' ELSE codpostal END,4,'0')::numeric as codpostal           
           ,CASE when nullvalue(nrodoctitular) THEN concat(persona.barra,'-',persona.nrodoc) ELSE nrodoctitular END as grupofamiliar
           ,CASE when nullvalue(nrodoctitular) THEN persona.barra::text ELSE substring(nrodoctitular FROM '^([^\\-]*)')  END as barragrupofamiliar
           ,CASE when nullvalue(idlocalidad) THEN '' ELSE localidad.descrip END as localidad
           ,CASE when nullvalue(nrodoctitular) THEN osreci.abreviatura ELSE barratitular.abreviatura END as reciprocidad
          
        FROM persona
        join tiposdoc using(tipodoc)
        LEFT JOIN direccion USING(iddireccion,idcentrodireccion)
        LEFT JOIN localidad USING(idlocalidad)
        LEFT JOIN osreci  ON (persona.barra = osreci.barra)
        LEFT JOIN (
              SELECT   
                 personatitular.barra 
                 ,persona.nrodoc
                 ,persona.tipodoc
                 ,concat(personatitular.barra,'-:',personatitular.nrodoc) as nrodoctitular 
                 ,osreci.abreviatura
              FROM persona 
              NATURAL JOIN benefreci
              JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
              LEFT JOIN osreci  ON (personatitular.barra = osreci.barra)
              WHERE persona.barra < 130 AND persona.barra >= 100 AND persona.tipodoc = 1
              
              ) as barratitular USING(nrodoc,tipodoc) 

        WHERE 
        --Malapi 29-08-2022 Comenta porque reporte jubilados que ya no tienen que tener cobertura... este reporte se usa para reportes de control... tiene que reflejar lo que corresponde.
        -- Malapi 29-08-2022 Me comentan por que es necesario esto ? 
        --(CASE WHEN (persona.barra = 35 OR persona.barra = 36 OR barratitular.barra = 35 OR barratitular.barra = 36)  THEN fechafinos+90  ELSE fechafinos   END) >= rparam.fecha::date
            fechafinos >= rparam.fecha::date
           AND persona.tipodoc = 1
           AND persona.nrodoc <> '10000000'  
           AND persona.nrodoc <> '00000001'
           AND persona.barra >100
        ORDER BY grupofamiliar

       )as tpadron);
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
