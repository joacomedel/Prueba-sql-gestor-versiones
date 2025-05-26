CREATE OR REPLACE FUNCTION public.obtenerdatosfichamedicaauditada_masvalores_histo(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
    
	
    cpractica refcursor;
    rpractica RECORD;
	rtemp practicavaloresxcategoriahistorico%rowtype;
    rfiltros RECORD;
    rhisto RECORD;
    vhisotorico1 INTEGER;
    vhisotorico2 INTEGER;
    vhisotorico3 INTEGER;
BEGIN

							  
	EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	
	
IF pfiltros ilike '%vigencia%' AND  not nullvalue(rfiltros.vigencia)  THEN --Solo me interesa el valor en la vigencia de la orden

RAISE NOTICE 'Llamo  a estoy en conVigencia (%)',pfiltros;

OPEN cpractica FOR SELECT iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad,idasocconv 
					FROM temp_practicavaloresxcategoriahistorico
					WHERE nullvalue(importe) 
;
FETCH cpractica INTO rpractica;
WHILE  found LOOP 
--Si el actual le da valor
INSERT INTO temp_practicavaloresxcategoriahistorico (iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, importe, internacion, idasocconv, pcategoria, pvxchfechaini, pvxchfechafin, pvxchfechainivigencia, pvxchfechafinvigencia, pvxchidusuario, pvxchordenhistorico) (
SELECT iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, t.importe, t.internacion, idasocconv, 'A' as pcategoria, null as pvxchfechaini, null as pvxchfechafin, t.pvfechainivigencia, t.pvfechafinvigencia, t.pvidusuario, 0 as pvxchordenhistorico
FROM practicavalores as t
  JOIN temp_practicavaloresxcategoriahistorico as tt
			  USING(idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica)
   WHERE not t.internacion 
	AND t.pvfechainivigencia <= rfiltros.vigencia
	AND (nullvalue(t.pvfechafinvigencia) OR t.pvfechafinvigencia >= rfiltros.vigencia) 
	AND idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
	AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo
	AND idpractica = rpractica.idpractica
LIMIT 1
);
IF FOUND THEN  --Si inserto, elimino la tupla con importe en null
	DELETE FROM temp_practicavaloresxcategoriahistorico WHERE idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
	AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo AND idpractica = rpractica.idpractica
	AND nullvalue(importe);
ELSE --Busco en los valores Historicos
--busco el que le da valor en el hisottorico
INSERT INTO temp_practicavaloresxcategoriahistorico (iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, importe, internacion, idasocconv, pcategoria, pvxchfechaini, pvxchfechafin, pvxchfechainivigencia, pvxchfechafinvigencia, pvxchidusuario, pvxchordenhistorico) (
SELECT iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, t.importe, t.internacion, idasocconv, t.pcategoria, t.pvxchfechaini, t.pvxchfechafin, t.pvxchfechainivigencia, t.pvxchfechafinvigencia, t.pvxchidusuario, t.pvxchordenhistorico
FROM practicavaloresxcategoriahistorico as t
  JOIN temp_practicavaloresxcategoriahistorico as tt
			  USING(idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica)
   WHERE not t.internacion 
	AND (t.pcategoria = 'A')
	AND t.pvxchfechainivigencia <= rfiltros.vigencia
	AND (nullvalue(t.pvxchfechafinvigencia	) OR t.pvxchfechafinvigencia	 >= rfiltros.vigencia) 
	AND idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
	AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo
	AND idpractica = rpractica.idpractica
LIMIT 1
);
IF FOUND THEN  --Si inserto, elimino la tupla con importe en null
	DELETE FROM temp_practicavaloresxcategoriahistorico WHERE idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
	AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo AND idpractica = rpractica.idpractica
	AND nullvalue(importe);
END IF;

END IF;


fetch cpractica into rpractica;
END LOOP;
CLOSE cpractica;

END IF;

IF pfiltros ilike '%cuantos%' AND  rfiltros.cuantos = 4 THEN  --El primero esta en practicavalores, los otros 3 estan en practicavaloresxcategoriahistorico

OPEN cpractica FOR SELECT iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad,idasocconv 
					FROM temp_practicavaloresxcategoriahistorico
					WHERE nullvalue(importe) 
;
FETCH cpractica INTO rpractica;
WHILE  found LOOP 


RAISE NOTICE 'Llamo  a estoy en cuantos  (%)',pfiltros;
INSERT INTO temp_practicavaloresxcategoriahistorico (iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, importe, internacion, idasocconv, pcategoria, pvxchfechaini, pvxchfechafin, pvxchfechainivigencia, pvxchfechafinvigencia, pvxchidusuario, pvxchordenhistorico) (
SELECT iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, t.importe, t.internacion, idasocconv, 'A' as pcategoria, null as pvxchfechaini, null as pvxchfechafin, t.pvfechainivigencia, t.pvfechafinvigencia, t.pvidusuario, 0 as pvxchordenhistorico
FROM practicavalores as t
  JOIN temp_practicavaloresxcategoriahistorico as tt
			  USING(idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica)
   WHERE not t.internacion
	AND idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
	AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo
	AND idpractica = rpractica.idpractica
LIMIT 1
);
IF FOUND THEN  --Si inserto, elimino la tupla con importe en null
	DELETE FROM temp_practicavaloresxcategoriahistorico WHERE idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
	AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo AND idpractica = rpractica.idpractica
	AND nullvalue(importe);
END IF;


SELECT INTO rhisto text_concatenarsinrepetir(concat(pvxchordenhistorico,'-')) as historicos
FROM (
SELECT idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,t.importe,t.pvxchfechainivigencia,t.pvxchfechafinvigencia,t.pvxchidusuario,t.pvxchordenhistorico
          FROM practicavaloresxcategoriahistorico as t
 WHERE not t.internacion 
	AND t.pcategoria = 'A'
	AND idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
	AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo
	AND idpractica = rpractica.idpractica
 ORDER BY idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,t.pvxchordenhistorico
) as orden;
IF FOUND THEN 
     IF not nullvalue(split_part(rhisto.historicos,'-',1)) THEN 
           vhisotorico1 = split_part(rhisto.historicos,'-',1)::integer;      
           
		INSERT INTO temp_practicavaloresxcategoriahistorico (iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, importe, internacion, idasocconv, pcategoria, pvxchfechaini, pvxchfechafin, pvxchfechainivigencia, pvxchfechafinvigencia, pvxchidusuario, pvxchordenhistorico) (
		SELECT rpractica.iditempractica,rpractica.idcentroitempractica,rpractica.nroorden,rpractica.centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, t.importe, t.internacion, idasocconv, t.pcategoria, t.pvxchfechaini, t.pvxchfechafin, t.pvxchfechainivigencia, t.pvxchfechafinvigencia, t.pvxchidusuario, 1 as pvxchordenhistorico
		FROM practicavaloresxcategoriahistorico as t
		   WHERE not t.internacion AND t.pvxchordenhistorico = vhisotorico1
		   AND t.pcategoria = 'A'
			AND idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
			AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo
			AND idpractica = rpractica.idpractica
		LIMIT 1		);
     END IF;

	IF not nullvalue(split_part(rhisto.historicos,'-',2)) THEN 
			   vhisotorico2 = split_part(rhisto.historicos,'-',2)::integer;

		INSERT INTO temp_practicavaloresxcategoriahistorico (iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, importe, internacion, idasocconv, pcategoria, pvxchfechaini, pvxchfechafin, pvxchfechainivigencia, pvxchfechafinvigencia, pvxchidusuario, pvxchordenhistorico) (
		SELECT rpractica.iditempractica,rpractica.idcentroitempractica,rpractica.nroorden,rpractica.centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, t.importe, t.internacion, idasocconv, t.pcategoria, t.pvxchfechaini, t.pvxchfechafin, t.pvxchfechainivigencia, t.pvxchfechafinvigencia, t.pvxchidusuario, 2 as pvxchordenhistorico
		FROM practicavaloresxcategoriahistorico as t
		   WHERE not t.internacion AND t.pvxchordenhistorico = vhisotorico2
			AND t.pcategoria = 'A'
			AND idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
			AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo
			AND idpractica = rpractica.idpractica
		LIMIT 1

		);
		 END IF;

	IF not nullvalue(split_part(rhisto.historicos,'-',3)) THEN 
           vhisotorico3 = split_part(rhisto.historicos,'-',3)::integer;

		INSERT INTO temp_practicavaloresxcategoriahistorico (iditempractica,idcentroitempractica,nroorden,centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, importe, internacion, idasocconv, pcategoria, pvxchfechaini, pvxchfechafin, pvxchfechainivigencia, pvxchfechafinvigencia, pvxchidusuario, pvxchordenhistorico) (
		SELECT rpractica.iditempractica,rpractica.idcentroitempractica,rpractica.nroorden,rpractica.centro,idcapitulo, idsubcapitulo, idpractica, idsubespecialidad, t.importe, t.internacion, idasocconv, t.pcategoria, t.pvxchfechaini, t.pvxchfechafin, t.pvxchfechainivigencia, t.pvxchfechafinvigencia, t.pvxchidusuario, 3 as pvxchordenhistorico
		FROM practicavaloresxcategoriahistorico as t
		   WHERE not t.internacion AND t.pvxchordenhistorico = vhisotorico3
			AND t.pcategoria = 'A'
			AND idasocconv = rpractica.idasocconv AND idsubespecialidad = rpractica.idsubespecialidad
			AND idcapitulo = rpractica.idcapitulo AND idsubcapitulo = rpractica.idsubcapitulo
			AND idpractica = rpractica.idpractica
			LIMIT 1

		);

          
     END IF;
END IF;

fetch cpractica into rpractica;
END LOOP;
CLOSE cpractica;


END IF;


    RETURN pfiltros;
END
$function$
