CREATE OR REPLACE FUNCTION public.expendio_controlpractica(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
   vnrodocumento VARCHAR;
       
--REGISTROS
   rparam RECORD;
   rpractica RECORD;
--CURSOR
   cpracticas refcursor;
BEGIN
  EXECUTE sys_dar_filtros($1) INTO rparam;  
  vnrodocumento = rparam.nrodoc;

 --KR 06-06-22 tkt 5121
  update tempitems set auditoria= true,tierror='La practica se emitio mas de una vez.' from (
            SELECT  max(idtemitems) idtemitems, idnomenclador, idcapitulo, idsubcapitulo, idpractica
            FROM tempitems  natural join (
                 select idnomenclador, idcapitulo, idsubcapitulo, idpractica
                  from tempitems 
                 group by idnomenclador, idcapitulo, idsubcapitulo, idpractica
                having count(*)>1 ) as t
            group by idnomenclador, idcapitulo, idsubcapitulo, idpractica ) tt
   where tempitems.idtemitems=tt.idtemitems;

--KR 30-06-22 TKT 5198
   OPEN cpracticas FOR SELECT pccpvalor*100 as iicoberturasosuncsugerida, nrodoc,tipodoc, nombreimprimir,pcpfechaingreso as fechaingresoplan
                       ,pcpfechafin as fechasalidaplan, idtemitems,pccpvalor*100 as iicoberturasosuncsugerida
                       FROM persona natural join plancobpersona pcp natural join plancobertura natural join plancoberturaconporcentaje JOIN 
                       tempitems ON concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica)=pcppcodigopractica
                       WHERE pcppdesdepractica AND fechafinos >= current_date AND (nullvalue(pcpfechafin) OR pcpfechafin >= current_date)
                       and nrodoc=vnrodocumento; 
   FETCH cpracticas INTO rpractica;
   WHILE  found LOOP
         UPDATE tempitems SET auditoria= true,tierror=concat('La practica tiene cobertura diferenciada para el afiliado en el plan ', rpractica.nombreimprimir), 
                          porcentajesugerido= rpractica.iicoberturasosuncsugerida
          WHERE  tempitems.idtemitems=rpractica.idtemitems; 
 
   FETCH cpracticas INTO rpractica;
   END LOOP;
   CLOSE cpracticas;   
return ' ';
END;$function$
