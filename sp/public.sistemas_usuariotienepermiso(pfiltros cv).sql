CREATE OR REPLACE FUNCTION public.sistemas_usuariotienepermiso(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$declare
      rfiltros RECORD;
      respuesta varchar;
      rverifica RECORD;
      viditem integer;
      vidmenu integer;
      vidmodulo integer;
      vidsupramenu integer;

BEGIN
	EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	respuesta = 'if_unchecked_8707.gif';
	viditem = 0;vidmenu = 0;vidmodulo = 0;vidsupramenu = 0;
	IF(pfiltros ilike '%iditem%') THEN
		viditem = rfiltros.iditem;
	END IF;
	IF(pfiltros ilike '%idmenu%') THEN
		vidmenu = rfiltros.idmenu;
	END IF;
	IF(pfiltros ilike '%idmodulo%') THEN
		vidmodulo = rfiltros.idmodulo;
	END IF;
	IF(pfiltros ilike '%idsupramenu%') THEN
		vidsupramenu = rfiltros.idsupramenu;
	END IF;
		RAISE NOTICE 'parametros (idsupramenu:%)(idmodulo:%)(idmenu:%)(iditem:%)(idusuario:%)',vidsupramenu,vidmodulo,vidmenu,viditem,rfiltros.idusuario;
		SELECT INTO rverifica *
		FROM admitem
		NATURAL JOIN admmenu
		NATURAL JOIN modulo
		NATURAL JOIN admsupramenumodulo
		JOIN usuario_admitem USING(iditem)
		WHERE nullvalue(uaifechafin)
			AND (idusuario = rfiltros.idusuario)
			AND (iditem = viditem OR viditem=0) 
			AND (idmenu = vidmenu OR vidmenu=0)
			AND (idmodulo = vidmodulo OR vidmodulo=0)
			AND (idsupramenu = vidsupramenu OR vidsupramenu=0)
			--AND not nullvalue(usuario_admitem.iditem)
			AND (viditem <> 0 OR vidmenu <> 0 OR vidmodulo <> 0 OR vidsupramenu <> 0)
		LIMIT 1;
		IF FOUND THEN
			--IF vidmenu=0 THEN
				respuesta = 'if_checkbox_8613.gif';
			--ELSE
			--	respuesta = 'if_x-red_8719.gif';
			--END IF;
		END IF;
		
		

RETURN respuesta;
END;
$function$
