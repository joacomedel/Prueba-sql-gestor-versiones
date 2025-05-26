CREATE OR REPLACE FUNCTION public.w_solicitar_token_afiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
 *{"token":"28272137", "NroAfiliado":"28272137","Barra":30,"NroDocumento":null,"TipoDocumento":null,"Track":null, "info_solicita":"online/sosunc"}
 */
DECLARE
--VARIABLES 
	vtoken varchar;
    nrodoctoken varchar;
    tipodoctoken varchar;
--RECORD
respuestajson jsonb;
rtokenexistente RECORD;
rdocumento RECORD;
rpersona RECORD;
rtoken RECORD;
vvencimiento timestamp;
long_token INTEGER = 8;
idpersona_token BIGINT;


begin
        IF (parametro->>'NroDocumento') is null AND (parametro->>'TipoDocumento') is null 
          AND (parametro->>'NroAfiliado') is null AND (parametro->>'Barra') is null
	  AND (parametro->>'Track') is null  THEN 
		RAISE EXCEPTION 'R-001, Al Menos uno de los parametros deben estar completos.  %',parametro;
       ELSE
        	SELECT INTO rpersona nrodoc as nroafiliado
				     ,barra
				     ,nrodoc as nrodocumento
				     ,descrip as tipodocumento
				     ,nombres
				     ,apellido
				     ,sexo
				     ,fechanac as fechanacimiento
				     ,tipodoc 
				     FROM persona 
                     NATURAL JOIN tiposdoc
				     WHERE -- fechafinos >= current_date AND --Malapi comento pues reciprocidad no estan activos
((not (parametro->>'NroDocumento') is null AND not (parametro->>'TipoDocumento') is null AND nrodoc = parametro->>'NroDocumento' AND descrip = parametro->>'TipoDocumento')
				     OR ( not (parametro->>'NroAfiliado') is null AND not (parametro->>'Barra') is null AND nrodoc = parametro->>'NroAfiliado' AND barra = parametro->>'Barra')
				     OR (not (parametro->>'Track') is null AND parametro->>'Track' ilike concat('%',nrodoc,'_') )
				     );
		IF FOUND THEN 
        nrodoctoken = rpersona.nrodocumento;
        tipodoctoken = rpersona.tipodoc;
        rtokenexistente = null;

                    -- Analizo de donde se invoca al sp
                    IF(parametro->>'uwnombre' = 'ususm'  AND parametro->>'info_solicita' = 'app' and parametro->>'accion'='Firma APP' ) THEN
                            long_token = 4;

                            --SL 12/04/24 - Busco datos si es beneficiario para el consumo del token del titular
                            SELECT INTO rdocumento
                                    CASE WHEN not b.nrodoctitu is null   THEN  b.nrodoctitu  
                                        WHEN not br.nrodoctitu is null   THEN  br.nrodoctitu  
                                        WHEN (b.nrodoctitu is null AND br.nrodoctitu is null) THEN  p.nrodoc END as nrodoctitu,
                                    CASE WHEN not b.tipodoctitu is null   THEN  b.tipodoctitu  
                                        WHEN not br.tipodoctitu is null   THEN  br.tipodoctitu  
                                        WHEN (b.tipodoctitu is null AND br.tipodoctitu is null) THEN  p.tipodoc END as tipodoctitu
                            FROM persona p 
                            LEFT JOIN benefsosunc b USING (nrodoc,tipodoc)
                            LEFT JOIN benefreci br USING (nrodoc,tipodoc)
                            WHERE nrodoc = nrodoctoken;

                            nrodoctoken = rdocumento.nrodoctitu;
                            tipodoctoken = rdocumento.tipodoctitu;


                            --Busco si existe algun token sin usar
                            SELECT INTO rtokenexistente * 
                                FROM persona_token pt
                                NATURAL JOIN w_persona_token_info pti
                                LEFT JOIN persona p ON (pt.nrodoc = p.nrodoc)        --SL 29/01/25 - Agrego persona para traerme mas info
                                LEFT JOIN persona_token_tipo ptt ON (ptt.idpersonatoken = pt.idpersonatoken AND ptt.idcentropersonatoken = pt.idcentropersonatoken)
                            WHERE pt.nrodoc = nrodoctoken
                                AND ptutilizado	IS NULL 
                                --SL 24/05/24 - La condicion de nula es por un tiempo hasta que todos los token tengan tipo. Si tiene tipo tiene que ser "1" = Firma APP
                                AND ((ptt.idpersonatokentipo is null AND pti.ptidescripcion = 'Firma APP') OR ptt.idtipotoken = 1);

                    END IF;     

                    --SL 11/04/25 - Si no existe el token lo genero
                    IF rtokenexistente IS NULL THEN 

                        IF(parametro->>'uwnombre' = 'ususm'  AND parametro->>'info_solicita' = 'app' and parametro->>'accion'='Firma APP' ) THEN
                            -- Generar 4 números aleatorios
                            SELECT INTO vtoken array_to_string(ARRAY(SELECT floor(random() * 10)::text
                            FROM generate_series(1, long_token)),'');
                        ELSE 
                            --Genera N letras aleatorias
                            SELECT INTO vtoken array_to_string(ARRAY(SELECT chr((65 + round(random() * 25)) :: integer)
                            FROM generate_series(1,long_token)), '');
                        END IF;

                        /*	FOR vtoken IN SELECT pttoken FROM persona_token WHERE ptfechavencimiento >= now()   LOOP
                                    
                                    SELECT INTO vtoken array_to_string(ARRAY(SELECT chr((65 + round(random() * 25)) :: integer)
                                    FROM generate_series(1,8)), '');
                            END LOOP;
                        */

                        IF (parametro->>'info_solicita') is null 
                                        OR parametro->>'info_solicita' ilike 'suap' THEN
                                vvencimiento =now() + interval '1 day';
                        ELSE
                                vvencimiento = now() + interval '30 day';
                        END IF;
                        INSERT INTO persona_token (pttoken,nrodoc,tipodoc,ptfechavencimiento) VALUES(vtoken,nrodoctoken,CAST(tipodoctoken AS integer),vvencimiento);
                        idpersona_token = currval('persona_token_idpersonatoken_seq'::regclass);
                        SELECT INTO rtoken * 
                        FROM persona_token 
                        WHERE idpersonatoken = idpersona_token
                                AND idcentropersonatoken = centro();
                        respuestajson = row_to_json(rtoken);

                        IF(parametro->>'uwnombre' = 'ususm' AND parametro->>'info_solicita' = 'app' AND parametro->>'accion'= 'Firma APP') THEN
                        
                                -- SL 24/05/24 - Creo el registro en info
                                INSERT INTO w_persona_token_info (idpersonatoken,ptidescripcion,idcentropersonatoken) VALUES
                                    (idpersona_token,'Firma APP',centro());


                                -- SL 24/05/24 - Almaceno el tipo en la tabla para luego saber de que es el token
                                INSERT INTO  persona_token_tipo (idpersonatoken,  idcentropersonatoken, idtipotoken   )
                                VALUES (idpersona_token, centro(), 1);

    --Tipo "1" = Firma Token
                        END IF;
                    ELSE
                        --Devuelvo el token
                        respuestajson = row_to_json(rtokenexistente);
                    END IF;
                 	
		ELSE 
			RAISE EXCEPTION 'R-001, El afiliado no esta activo o no existe,%)',parametro;
		END IF;
        END IF;     
       
      return respuestajson;

end;
$function$
