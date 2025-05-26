CREATE OR REPLACE FUNCTION public.asistencial_pvxchistorico(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--cursor 
  cpvxchistoricototal REFCURSOR;
  cpvxchistorico REFCURSOR;
--record
  rpvxchistoricototal  record;
  rfiltros RECORD;
  runapractica RECORD;
--VARIABLES 
  contadorordenh INTEGER;

BEGIN

   EXECUTE sys_dar_filtros($1) INTO rfiltros;
   RAISE NOTICE 'Los filtros con (%)',rfiltros;
  OPEN cpvxchistoricototal FOR SELECT idsubespecialidad, idcapitulo, idsubcapitulo, idpractica, idasocconv, pcategoria,internacion
      FROM practicavaloresxcategoriahistorico
      WHERE nullvalue(pvxchfechafin) 
           AND idsubespecialidad = trim(rfiltros.idnomenclador) 
           AND ( (not internacion  AND trim(rfiltros.internacion) = 'no') OR (internacion  AND trim(rfiltros.internacion) = 'si'))
           --AND idcapitulo = '66' 
          -- AND idsubcapitulo = '10' 
          --AND nullvalue(pvxchordenhistorico)
           
      ORDER BY idsubespecialidad, idcapitulo, idsubcapitulo, idpractica, idasocconv, pcategoria; 
  FETCH cpvxchistoricototal into rpvxchistoricototal;

  WHILE FOUND LOOP
      --RAISE NOTICE 'Adentro con (%)',rpvxchistoricototal;
      OPEN cpvxchistorico FOR SELECT  * FROM  practicavaloresxcategoriahistorico
                                       WHERE idsubespecialidad = rpvxchistoricototal.idsubespecialidad AND 
                                       idcapitulo = rpvxchistoricototal.idcapitulo AND
                                       idsubcapitulo = rpvxchistoricototal.idsubcapitulo AND
                                       idpractica = rpvxchistoricototal.idpractica AND
                                       idasocconv = rpvxchistoricototal.idasocconv AND
                                       pcategoria = rpvxchistoricototal.pcategoria 
                                       AND internacion = rpvxchistoricototal.internacion
                                      -- AND  nullvalue(pvxchordenhistorico)
                                       ORDER BY pvxchfechaini DESC;
     FETCH cpvxchistorico into runapractica;
     contadorordenh =1;
     WHILE FOUND LOOP
         UPDATE practicavaloresxcategoriahistorico SET pvxchordenhistorico = contadorordenh
           WHERE idsubespecialidad = runapractica.idsubespecialidad AND 
           idcapitulo = runapractica.idcapitulo AND
           idsubcapitulo = runapractica.idsubcapitulo AND
           idpractica = runapractica.idpractica AND
           idasocconv = runapractica.idasocconv AND
           pcategoria = runapractica.pcategoria AND
           internacion = runapractica.internacion AND
           pvxchfechaini = runapractica.pvxchfechaini 
           AND internacion = runapractica.internacion
           -- AND nullvalue(pvxchordenhistorico)
         ;
  
         contadorordenh = contadorordenh+1;
         FETCH cpvxchistorico into runapractica ;

     END LOOP;
     CLOSE cpvxchistorico;

  
	
     FETCH cpvxchistoricototal into rpvxchistoricototal ;

  END LOOP;
  CLOSE cpvxchistoricototal;

 
   return  'OK'  ;

END;
$function$
