CREATE OR REPLACE FUNCTION public.afiliaciones_gestionalertasafiliado()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	--rfiltros RECORD;
	ralerta RECORD;
	rusuario RECORD;
	
	

BEGIN
	--EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;

	select into ralerta iafechaini,iagrupofamiliar,iatexto,persona.tipodoc,nrodoc,iaidusuario,iafechafin,idcentroinfoafiliado,idinfoafiliado
			FROM temp_afiliaciones_gestionalertasafiliado
			JOIN persona USING(nrodoc);
	IF FOUND THEN 
                IF nullvalue(ralerta.idinfoafiliado) THEN -- Quiere decir que es nueva
			INSERT INTO infoafiliado(iafechaini,iagrupofamiliar,iatexto,tipodoc,nrodoc,iaidusuario,iafechafin) 
			VALUES(ralerta.iafechaini,ralerta.iagrupofamiliar,ralerta.iatexto,ralerta.tipodoc,ralerta.nrodoc,rusuario.idusuario,ralerta.iafechafin);
                        UPDATE temp_afiliaciones_gestionalertasafiliado SET idcentroinfoafiliado = centro(),idinfoafiliado = currval('infoafiliado_idinfoafiliado_seq');
		ELSE
			UPDATE infoafiliado SET 
				iafechaini = ralerta.iafechaini
				,iagrupofamiliar = ralerta.iagrupofamiliar
				,iatexto =  ralerta.iatexto
				,iafechafin = ralerta.iafechafin
				,tipodoc = ralerta.tipodoc
				,nrodoc = ralerta.nrodoc
			WHERE idcentroinfoafiliado = ralerta.idcentroinfoafiliado AND idinfoafiliado = ralerta.idinfoafiliado;
		END IF;
                -- Inserto donde se deben mostrar
                DELETE FROM infoafiliado_dondemostra 
                 WHERE  (idcentroinfoafiliado,idinfoafiliado) IN (SELECT idcentroinfoafiliado,idinfoafiliado
                                                                  FROM temp_afiliaciones_gestionalertasafiliado);
                INSERT INTO infoafiliado_dondemostra (idcentroinfoafiliado,idinfoafiliado,idinfoafiliadoquienmuestra) 
( SELECT DISTINCT idcentroinfoafiliado,idinfoafiliado,infoafiliado_quienmuestra.idinfoafiliadoquienmuestra
 -- KR 13-05-19 Comente y puse un join para que solo muestre el alerta en los lugares seleccionados por el usuario
-- FROM temp_afiliaciones_gestionalertasafiliado, infoafiliado_quienmuestra
 FROM temp_afiliaciones_gestionalertasafiliado JOIN infoafiliado_quienmuestra USING(idinfoafiliadoquienmuestra)
--MaLapi 19-10-2022 Comento porque no entiendo cual es el motivo del where -- pàra los nuevos tipos de transacciones no se vinculan
--  WHERE  infoafiliado_quienmuestra.idinfoafiliadoquienmuestra < 9 
--Dani comento el 22-10-19 . no se recuerda el motivo de porq excluir las de tipo Auditoria Orden
--and infoafiliado_quienmuestra.idinfoafiliadoquienmuestra<>2
);

	END IF;

	
		
RETURN 'true';
END;
$function$
