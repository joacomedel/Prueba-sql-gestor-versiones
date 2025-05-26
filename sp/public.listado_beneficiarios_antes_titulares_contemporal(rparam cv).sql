CREATE OR REPLACE FUNCTION public.listado_beneficiarios_antes_titulares_contemporal(rparam character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--  rparam RECORD;
--  relem RECORD;
--  rvalorescaja RECORD;
  rfiltros RECORD;
--  vquery text;
   
  cursorcc refcursor;
  varrvalorescaja  varchar[];
  varrlongitud integer;
  vvalorescaja  varchar;
  vcontador integer;
BEGIN
  
 
 

EXECUTE sys_dar_filtros(rparam) INTO rfiltros;
--(rfiltros.idconac= 1) con asientos contables
        
CREATE TEMP TABLE temp_listado_beneficiarios_antes_titulares_contemporal
AS (

SELECT distinct *,
'1-Nrodoc#nrodoc@2-Afiliado#afiliado@3-Apellido#apellido@4-Nombres#nombres@5-Barras_previas#barra_previas@6-Fechafinos_benef#fechafinos_benef@7-ultimoaporterecibido#ultimoaporterecibido@8-Titular#titular@9-Apellido Titular#ape_titu@10-Nombre Titular#nom_titu@11-FechaFinOS_titu#fechafinos_titu'::text as mapeocampocolumna


FROM (

       select persona.nrodoc,   concat(persona.nrodoc,'/',persona.barra) as afiliado,apellido,nombres
                , histobarras.barra as barra_previas , persona.fechafinos as fechafinos_benef
       , ultimoaporterecibido(persona.nrodoc,persona.tipodoc)
       , concat(titular.nrodoctitu,'/',titular.barratitu) as titular 
       , titular.ape_titu, titular.nom_titu, fechafinos_titu
       FROM persona
       NATURAL JOIN  (SELECT  b.nrodoc, b.tipodoc, nrodoctitu, barra as barratitu ,apellido as ape_titu,nombres as nom_titu, fechafinos as fechafinos_titu
               FROM benefsosunc b
               JOIN persona as p ON (nrodoctitu = p.nrodoc AND tipodoctitu = p.tipodoc) 
               WHERE barra>=30 AND  barra<=100 AND  fechafinos>= '2024-01-01' 
       ) as titular 
       join histobarras using(nrodoc,tipodoc)
       where fechafinos>= rfiltros.fecha  and persona.barra=1
              and (barratitu>=30 AND  barratitu<=100)
              and histobarras.barra<100 and histobarras.barra>1
 
       ) as T
WHERE not nullvalue( ultimoaporterecibido) AND barra_previas >=30
     
order by apellido,nombres 	   



);

return true;
END;$function$
