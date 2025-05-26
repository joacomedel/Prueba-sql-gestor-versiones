CREATE OR REPLACE FUNCTION public.expendio_solicitar_token_afiliado(pfiltros character varying)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"token":"28272137","Barra":30,"NroDocumento":null,"TipoDocumento":null,"Track":null}
*/
DECLARE
--VARIABLES 
	vtoken varchar;
--RECORD
      respuestajson jsonb;
      respuestajsontk VARCHAR;
      rpersona RECORD;
      relem  RECORD;
      rfiltros RECORD;
      param VARCHAR;
      
begin

	EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
	SELECT INTO relem * FROM ttordenesgeneradas 
						NATURAL JOIN ordenrecibo
						NATURAL JOIN orden
						NATURAL JOIN consumo 
			    		        NATURAL JOIN persona 
                                                --sl 25/09/23 - Agrego condicion para que acepte solo ordenes online desede la APP (56 y 154)
						LEFT JOIN (SELECT DISTINCT idasocconv, acdecripcion FROM asocconvenio where acactivo and aconline ) as asocconvenio USING (idasocconv)
                                                WHERE tipo <> 56 OR (tipo = 56 AND asocconvenio.idasocconv = 154) -- Malapi 23/04/2020 Dejo afuera las ordenes online.
                            LIMIT 1;
	IF FOUND THEN 
	
		param = concat('{"NroAfiliado":"',relem.nrodoc,'","Barra":',relem.barra,',"NroDocumento":null,"TipoDocumento":null,"Track":null,"info_solicita":"sosunc"} ');

		SELECT INTO respuestajson * FROM w_solicitar_token_afiliado(param::jsonb);

		-- sl 11/08/23 - Creo estructura para asociar token a la orden
		--param = concat('{"idpersonatoken":',respuestajson->>'idpersonatoken',',"idcentropersonatoken":',respuestajson->>'idcentropersonatoken',',"nroorden":',relem.nroorden,',"centro":',relem.centro,'} ');
		
		-- sl 11/08/23 - Modularizo funcion para poder utilizar las ordenes virtuales desde la APP
		--PERFORM w_asociartokenorden(param::jsonb);

                 INSERT INTO persona_token(pttoken,nrodoc,tipodoc,ptfechavencimiento) (
                   SELECT  concat(nroorden,centro,pttoken) as pttoken,consumo.nrodoc,consumo.tipodoc,ptfechavencimiento 
                          FROM ttordenesgeneradas 
			  NATURAL JOIN ordenrecibo 
                          NATURAL JOIN consumo
                          LEFT JOIN persona_token ON (idpersonatoken = respuestajson->>'idpersonatoken' AND idcentropersonatoken = respuestajson->>'idcentropersonatoken')
                  );
                  INSERT INTO recibo_token(idrecibo,centro,pttoken) (
                   SELECT  idrecibo,centro,concat(nroorden,centro,pttoken) as pttoken 
                          FROM ttordenesgeneradas 
			  NATURAL JOIN ordenrecibo 
                          NATURAL JOIN consumo
                          LEFT JOIN persona_token ON (idpersonatoken = respuestajson->>'idpersonatoken' AND idcentropersonatoken = respuestajson->>'idcentropersonatoken')
                  );
                  DELETE FROM persona_token 
                        WHERE idpersonatoken = respuestajson->>'idpersonatoken' AND idcentropersonatoken = respuestajson->>'idcentropersonatoken';
                 
	END IF;
       
      return respuestajson;

end;
$function$
