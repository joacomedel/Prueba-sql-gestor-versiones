CREATE OR REPLACE FUNCTION public.test_muchas_hojas_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_test_muchas_hojas_contemporal_h1 AS (
    
        SELECT 
           CASE when nullvalue(nrodoctitular) THEN 'TITULAR' ELSE 'BENEFICIARIO' END as titular
           ,CONCAT(nrodoc,persona.barra) as nroafiliado
           ,nombres
           ,apellido
           ,tiposdoc.descrip as tipodoc
           ,lpad(nrodoc,8,'0') as nrodoc 
           , fechanac ::date
           , date_part('year',age(fechanac))  as edad
           , fechainios ::date
           ,CASE when nullvalue(nrodoctitular) THEN concat(persona.barra,'-',persona.nrodoc) ELSE nrodoctitular END as grupofamiliar,barratitular.descrip,
 		  '1-apellido#apellido@2-nombres#nombres@3-nrodoc#nrodoc@4-nroafiliado#nroafiliado@5-fechanac#fechanac@6-edad#edad@7-fechainios#fechainios@8-Titular#grupofamiliar@9-TipoAfiliado#titular@10-Vinculo#descrip'::text as mapeocampocolumna
        FROM persona
        join tiposdoc using(tipodoc)
        LEFT JOIN direccion USING(iddireccion,idcentrodireccion)
        LEFT JOIN localidad USING(idlocalidad)
        LEFT JOIN (
              SELECT   
                 personatitular.barra 
                 ,persona.nrodoc
                 ,persona.tipodoc
                 ,concat(personatitular.barra,'-:',personatitular.nrodoc) as nrodoctitular,vinculos.descrip  
              FROM persona 
              NATURAL JOIN benefsosunc
              NATURAL JOIN vinculos
              JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
              WHERE persona.barra < 30 AND persona.tipodoc = 1
              
              ) as barratitular USING(nrodoc,tipodoc) 
        WHERE 
            fechafinos >= rparam.fecha::date
 
           AND persona.tipodoc = 1
           AND persona.nrodoc <> '10000000'  
           AND persona.nrodoc <> '00000001'
           AND persona.barra = 35
        ORDER BY grupofamiliar

       );
	   
	   CREATE TEMP TABLE temp_test_muchas_hojas_contemporal_h2 AS (
    
        SELECT 
           CASE when nullvalue(nrodoctitular) THEN 'TITULAR' ELSE 'BENEFICIARIO' END as titular
           ,CONCAT(nrodoc,persona.barra) as nroafiliado
           ,nombres
           ,apellido
           ,tiposdoc.descrip as tipodoc
           ,lpad(nrodoc,8,'0') as nrodoc 
           , fechanac ::date
           , date_part('year',age(fechanac))  as edad
           , fechainios ::date
           ,CASE when nullvalue(nrodoctitular) THEN concat(persona.barra,'-',persona.nrodoc) ELSE nrodoctitular END as grupofamiliar,barratitular.descrip,
 		  '1-apellido#apellido@2-nombres#nombres@3-nrodoc#nrodoc@4-nroafiliado#nroafiliado@5-fechanac#fechanac@6-edad#edad@7-fechainios#fechainios@8-Titular#grupofamiliar@9-TipoAfiliado#titular@10-Vinculo#descrip'::text as mapeocampocolumna
        FROM persona
        join tiposdoc using(tipodoc)
        LEFT JOIN direccion USING(iddireccion,idcentrodireccion)
        LEFT JOIN localidad USING(idlocalidad)
        LEFT JOIN (
              SELECT   
                 personatitular.barra 
                 ,persona.nrodoc
                 ,persona.tipodoc
                 ,concat(personatitular.barra,'-:',personatitular.nrodoc) as nrodoctitular,vinculos.descrip  
              FROM persona 
              NATURAL JOIN benefsosunc
              NATURAL JOIN vinculos
              JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
              WHERE persona.barra < 30 AND persona.tipodoc = 1
              
              ) as barratitular USING(nrodoc,tipodoc) 
        WHERE 
            fechafinos >= rparam.fecha::date
 
           AND persona.tipodoc = 1
           AND persona.nrodoc <> '10000000'  
           AND persona.nrodoc <> '00000001'
           AND persona.barra = 32
        ORDER BY grupofamiliar

       );
 
   
      CREATE TEMP TABLE temp_test_muchas_hojas_contemporal as (
	  	SELECT 'Hoja 1' as titulohoja,'temp_test_muchas_hojas_contemporal_h1' as nombretabla 
		  UNION 
		SELECT 'Hoja 2' as titulohoja,'temp_test_muchas_hojas_contemporal_h2' as nombretabla 
	  );
--por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;
$function$
