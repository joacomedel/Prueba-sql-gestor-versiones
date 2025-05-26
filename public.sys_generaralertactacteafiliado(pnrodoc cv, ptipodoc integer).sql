CREATE OR REPLACE FUNCTION public.sys_generaralertactacteafiliado(pnrodoc character varying, ptipodoc integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE

	ruso RECORD;
    raux RECORD;
	ralerta RECORD;
	rusuario RECORD;
        rmontodisponible RECORD;
        aux record;
	resultado boolean;
        

BEGIN
/*SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
*/
IF iftableexistsparasp('temp_afiliaciones_gestionalertasafiliado') THEN
	DELETE FROM temp_afiliaciones_gestionalertasafiliado;
ELSE 
	CREATE TEMP TABLE temp_afiliaciones_gestionalertasafiliado AS  ( SELECT * FROM infoafiliado NATURAL JOIN infoafiliado_dondemostra LIMIT 0);
END IF;

SELECT INTO rmontodisponible * FROM ctasctesmontosdescuento 
                                WHERE nrodoc  =pnrodoc and nullvalue(ccmdfechafin);
IF FOUND THEN 

	SELECT INTO ralerta * FROM infoafiliado WHERE nrodoc = pnrodoc AND iagrupofamiliar AND iatexto ilike 'Sys.CC%' and nullvalue(iafechafin) LIMIT 1;
	 IF NOT FOUND THEN
		ralerta.nrodoc = pnrodoc;
		ralerta.iafechaini = CURRENT_DATE -1;
		ralerta.iagrupofamiliar = true;
		ralerta.idcentroinfoafiliado = centro();
		ralerta.idinfoafiliado = null;
		ralerta.tipodoc = ptipodoc;

		
	 END IF;
	
ELSE 
     SELECT INTO ralerta * FROM infoafiliado WHERE nrodoc = pnrodoc AND iagrupofamiliar AND iatexto ilike 'Sys.CC%' and nullvalue(iafechafin) LIMIT 1;
     IF FOUND THEN
                ralerta.nrodoc = pnrodoc;
		ralerta.iafechaini = CURRENT_DATE -1;
		ralerta.iagrupofamiliar = true;
		ralerta.idcentroinfoafiliado = centro();
		ralerta.idinfoafiliado = null;
		ralerta.tipodoc = ptipodoc; 
                rmontodisponible.ccmdimporte = 0;
                rmontodisponible.ccmdmontoconsumido = 0;
     END IF;

END IF;

ralerta.iaidusuario = 25;
	ralerta.iatexto = concat('Sys.CC ','Saldo disponible $',rmontodisponible.ccmdimporte - rmontodisponible.ccmdmontoconsumido,'. Ult. Modificación ',to_char(CURRENT_TIMESTAMP,'DD-MM-YYYY HH:MM:SS'));
	INSERT INTO temp_afiliaciones_gestionalertasafiliado(iafechaini,iagrupofamiliar,idcentroinfoafiliado,iatexto,tipodoc,nrodoc,iaidusuario,idinfoafiliado,idinfoafiliadoquienmuestra)
	(SELECT ralerta.iafechaini,ralerta.iagrupofamiliar,ralerta.idcentroinfoafiliado,ralerta.iatexto,ralerta.tipodoc,ralerta.nrodoc,ralerta.iaidusuario,ralerta.idinfoafiliado,idinfoafiliadoquienmuestra 
--KR 05-02-20 las alertas de cta cte no son requeridas cuando se audita una factura
	FROM infoafiliado_quienmuestra WHERE iaqmmuestrasys
	); 
select into raux * from temp_afiliaciones_gestionalertasafiliado
JOIN persona USING(nrodoc);
	PERFORM afiliaciones_gestionalertasafiliado();

resultado = true;
return resultado;
END;
$function$
