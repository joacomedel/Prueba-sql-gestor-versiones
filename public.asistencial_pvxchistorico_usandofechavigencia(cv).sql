CREATE OR REPLACE FUNCTION public.asistencial_pvxchistorico_usandofechavigencia(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
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
   --Es para que los que no tengan vigerncia asignado, no me afecten los contadores nuevos
    UPDATE practicavaloresxcategoriahistorico SET pvxchordenhistorico = pvxchordenhistorico + 100
           WHERE idsubespecialidad = trim(rfiltros.idnomenclador) 
           AND ( (not internacion  AND trim(rfiltros.internacion) = 'no') OR (internacion  AND trim(rfiltros.internacion) = 'si'))
           AND idasocconv = rfiltros.idasocconv
		   AND pvxchordenhistorico < 100;
   
   
  OPEN cpvxchistoricototal FOR SELECT idsubespecialidad, idcapitulo, idsubcapitulo, idpractica, idasocconv, pcategoria,internacion
      FROM practicavaloresxcategoriahistorico
      WHERE --nullvalue(pvxchfechafin) Ya no confio en la fecha fin... tambien hay que arreglarlo
           idsubespecialidad = trim(rfiltros.idnomenclador) 
           AND ( (not internacion  AND trim(rfiltros.internacion) = 'no') OR (internacion  AND trim(rfiltros.internacion) = 'si'))
           AND idasocconv = rfiltros.idasocconv
		   --AND idcapitulo = '66' 
          -- AND idsubcapitulo = '10' 
          AND not nullvalue(pvxchfechainivigencia) --No puedo ordenar las que no tengan vigencia cargada
      GROUP BY idsubespecialidad, idcapitulo, idsubcapitulo, idpractica, idasocconv, pcategoria,idasocconv, pcategoria,internacion    
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
                                       AND  not nullvalue(pvxchfechainivigencia) --No puedo ordenar las que no tengan vigencia cargada
                                       ORDER BY pvxchfechainivigencia DESC; --Puedo confiar en la vigencia, pues lo recalcule
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
--El Historico 1 es el que tiene que quedar vigente, el resto no.

UPDATE practicavaloresxcategoriahistorico SET pvxchfechafin = null 
WHERE pvxchordenhistorico = 1 AND idsubespecialidad = trim(rfiltros.idnomenclador) 
           AND ((not internacion  AND trim(rfiltros.internacion) = 'no') OR (internacion  AND trim(rfiltros.internacion) = 'si'))
           AND idasocconv = rfiltros.idasocconv;
--Le quito la vigencia a los otros		   
UPDATE practicavaloresxcategoriahistorico SET pvxchfechafin = now() 
WHERE pvxchordenhistorico > 1 AND idsubespecialidad = trim(rfiltros.idnomenclador) 
           AND ((not internacion  AND trim(rfiltros.internacion) = 'no') OR (internacion  AND trim(rfiltros.internacion) = 'si'))
           AND idasocconv = rfiltros.idasocconv
		   AND  nullvalue(pvxchfechafin);
 
   return  'OK'  ;

END;
$function$
