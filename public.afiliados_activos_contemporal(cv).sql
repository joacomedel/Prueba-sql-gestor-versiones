CREATE OR REPLACE FUNCTION public.afiliados_activos_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_afiliados_activos_contemporal AS (
    
         SELECT 
           CASE when nullvalue(nrodoctitular) THEN 'TITULAR' ELSE 'BENEFICIARIO' END as titular
           ,CONCAT(nrodoc,persona.barra) as nroafiliado
           ,nombres
           ,apellido
           ,tiposdoc.descrip as tipodoc
           ,lpad(nrodoc,8,'0') as nrodoc 
            , fechanac ::date
         /* ,to_char(fechanac,'YYYYMMDD') as fechanac*/
           , date_part('year',age(fechanac))  as edad
          /* ,to_char(fechainios,'YYYYMMDD') as fechainios*/
          , fechainios ::date
            ,CASE when nullvalue(nrodoctitular) THEN concat(persona.barra,'-',persona.nrodoc) ELSE nrodoctitular END as grupofamiliar,barratitular.descrip
            ,CASE when (nullvalue(nrodoctitular)) THEN (case when (afilsosunc.idosexterna <> 0) Then osexterna.abreviatura else '' end  )   ELSE ( case when (nullvalue(osexterna) or barratitular.idosexterna = 0 ) then '' else osexterna end)  END as osexterna,

 '1-apellido#apellido@2-nombres#nombres@3-nrodoc#nrodoc@4-nroafiliado#nroafiliado@5-fechanac#fechanac@6-edad#edad@7-fechainios#fechainios@8-Titular#grupofamiliar@9-TipoAfiliado#titular@10-Vinculo#descrip@11-OSExterna#osexterna'::text as mapeocampocolumna

          

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
                 ,osexterna.idosexterna 
                 ,abreviatura as osexterna
              FROM persona 
              NATURAL JOIN benefsosunc
              NATURAL JOIN vinculos
              JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
              left join osexterna using (idosexterna)
              WHERE persona.barra < 30 AND persona.tipodoc = 1
              
              ) as barratitular USING(nrodoc,tipodoc) 
        LEFT join afilsosunc using(nrodoc,tipodoc )
        left join osexterna on (afilsosunc.idosexterna = osexterna.idosexterna)-- as tosexterna

        WHERE 
            fechafinos >= rparam.fecha
 
           AND persona.tipodoc = 1
           AND persona.nrodoc <> '10000000'  
           AND persona.nrodoc <> '00000001'
           AND persona.barra <100
        ORDER BY grupofamiliar

       );
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
