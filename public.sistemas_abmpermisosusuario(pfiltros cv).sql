CREATE OR REPLACE FUNCTION public.sistemas_abmpermisosusuario(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
      rfiltros RECORD;
      viditem integer;
      vidmenu integer;
      vidmodulo integer;
      cusuarios refcursor;
      runo RECORD;
      --vclaseprincipal varchar;

BEGIN
	CREATE TEMP TABLE temp_usuario_admitem (iditem integer, iclaseprincipal varchar);
	EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

	viditem = 0;vidmenu = 0;vidmodulo = 0;
        --rfiltros.idusuario =  runo.idusuario;
	IF(rfiltros.opcion = 'items' AND pfiltros ilike '%iditem%') THEN
		viditem = rfiltros.iditem;
                INSERT INTO temp_usuario_admitem (
		SELECT iditem,iclaseprincipal 
		FROM admitem
		WHERE (iclaseprincipal) IN (
				SELECT  iclaseprincipal 
				FROM admitem 
				WHERE iditem = viditem	
				)
		);
		
	END IF;
	IF( rfiltros.opcion = 'menu' AND  pfiltros ilike '%idmenu%') THEN
		vidmenu = rfiltros.idmenu;
		INSERT INTO temp_usuario_admitem (
		SELECT iditem,iclaseprincipal 
		FROM admitem
		WHERE (iclaseprincipal) IN (
				SELECT  iclaseprincipal 
				FROM admitem
				NATURAL JOIN admmenu
				WHERE idmenu = vidmenu	
				)
		);
	END IF;
	IF(rfiltros.opcion = 'modulo' AND  pfiltros ilike '%idmodulo%') THEN
		vidmodulo = rfiltros.idmodulo;
		INSERT INTO temp_usuario_admitem (
		SELECT iditem,iclaseprincipal 
		FROM admitem
		WHERE (iclaseprincipal) IN (
				SELECT  iclaseprincipal 
				FROM admitem
				NATURAL JOIN admmenu
				NATURAL JOIN modulo
				WHERE idmodulo = vidmodulo	
				)
		);
	END IF;


        OPEN cusuarios FOR SELECT * FROM temp_usuarios;
       FETCH cusuarios INTO runo;
       WHILE  found LOOP

/*	viditem = 0;vidmenu = 0;vidmodulo = 0;
        --rfiltros.idusuario =  runo.idusuario;
	IF(rfiltros.opcion = 'items' AND pfiltros ilike '%iditem%') THEN
		viditem = rfiltros.iditem;
                INSERT INTO temp_usuario_admitem (
		SELECT iditem,iclaseprincipal 
		FROM admitem
		WHERE (iclaseprincipal) IN (
				SELECT  iclaseprincipal 
				FROM admitem 
				WHERE iditem = viditem	
				)
		);
		
	END IF;
	IF( rfiltros.opcion = 'menu' AND  pfiltros ilike '%idmenu%') THEN
		vidmenu = rfiltros.idmenu;
		INSERT INTO temp_usuario_admitem (
		SELECT iditem,iclaseprincipal 
		FROM admitem
		WHERE (iclaseprincipal) IN (
				SELECT  iclaseprincipal 
				FROM admitem
				NATURAL JOIN admmenu
				WHERE idmenu = vidmenu	
				)
		);
	END IF;
	IF(rfiltros.opcion = 'modulo' AND  pfiltros ilike '%idmodulo%') THEN
		vidmodulo = rfiltros.idmodulo;
		INSERT INTO temp_usuario_admitem (
		SELECT iditem,iclaseprincipal 
		FROM admitem
		WHERE (iclaseprincipal) IN (
				SELECT  iclaseprincipal 
				FROM admitem
				NATURAL JOIN admmenu
				NATURAL JOIN modulo
				WHERE idmodulo = vidmodulo	
				)
		);
	END IF;
*/

	IF rfiltros.accion ='alta' THEN
		INSERT INTO usuario_admitem(iditem,idusuario) 
		(
		SELECT iditem,runo.idusuario as idusuario
		FROM temp_usuario_admitem
		WHERE iditem NOT IN (SELECT iditem
					FROM usuario_admitem
					WHERE idusuario = runo.idusuario 
					AND  nullvalue(uaifechafin)
					)
		);


	END IF;
	IF rfiltros.accion ='baja' THEN
		UPDATE usuario_admitem  SET uaifechafin = now()
			WHERE (iditem,idusuario) IN (
				SELECT iditem,runo.idusuario as idusuario
				FROM temp_usuario_admitem
				LEFT JOIN usuario_admitem USING(iditem)
				WHERE nullvalue(uaifechafin)
				AND (idusuario = runo.idusuario)
				AND CASE WHEN nullvalue(usuario_admitem.iditem) THEN false ELSE true END
				);
	END IF;

       FETCH cusuarios INTO runo;
       END LOOP;
      CLOSE cusuarios;

RETURN true;
END;
$function$
