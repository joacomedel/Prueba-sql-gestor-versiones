CREATE OR REPLACE FUNCTION public.w_consumir_token_afiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"token":"28272137","info_consumio_token":"Sin Informacion"}
*/
DECLARE
--VARIABLES 
    vtoken varchar;
--RECORD
      respuestajson jsonb;
      rpersona RECORD;
      rtoken  RECORD;
      rdocumento RECORD;
      
begin
         IF nullvalue(parametro->>'token')   THEN 
        --RAISE EXCEPTION 'R-001, Al Menos uno de los parametros deben estar completos.  %',parametro;
                --MaLapi 22-04-2020 Por el momento lo comento, pues hay partes del sistema que aun no lo usan
         ELSE
                ---- Analizo si se trata de un token comodin
                IF ( (parametro->>'token' = 'suap1234'  OR  parametro->>'token' = 'suap279' OR parametro->>'token'= substr(parametro->>'NroAfiliado',5) )
                     OR (parametro->>'token' = 'evweb3412' OR parametro->>'token' = 'evweb5553' OR parametro->>'token' = 'exp_sc' OR parametro->>'token'= substr(parametro->>'NroAfiliado',6) )   
                    ----Para evweb solicita los ultimos 3 digistos del DNI como token comodin para EVEWEB
                   --- SL 16/05/24 - solicita los ultimos 4 digitos del DNI como token comodin para SUAP
                   -- BelenA 16/12/24 agrego que tambien tome el token de expendio "exp_sc"
                ) THEN
                        IF (parametro->>'info_consumio_token'  = 'suap' OR parametro->>'info_consumio_token'  = 'evweb' OR parametro->>'info_consumio_token' = 'exp_sc')  THEN
                        -- BelenA 16/12/24 agrego que tambien tome el token de expendio "exp_sc"
                        --MaLapi 22-04-2020 Es un token comodin que usa la gente de suap, por el momento lo dejo pasar
                        --SL 08/01/25 - No se permiten mas uso de token comodin.
                            --RAISE EXCEPTION 'R-150, Usted ingresó un token comodín. Debe solicitar el token correspondiente al afiliado.';
                        ELSE 
                            RAISE EXCEPTION 'R-014, El token no existe ,(%)',parametro;  
                        END IF;

                ELSE   -- NO  se trata de un token comodin
                       -- Analizamos 
                       --- VAS 071123 busco los datos del token 
                                        
                    --SL 12/04/24 - Busco datos si es beneficiario para el consumo del token del titular
                        SELECT INTO rdocumento
                                CASE WHEN not nullvalue(b.nrodoctitu)   THEN  b.nrodoctitu  
                                    WHEN not nullvalue(br.nrodoctitu)   THEN  br.nrodoctitu  
                                    WHEN (nullvalue(b.nrodoctitu) AND nullvalue(br.nrodoctitu)) THEN  p.nrodoc END as titu
                        FROM persona p 
                        LEFT JOIN benefsosunc b USING (nrodoc,tipodoc)
                        LEFT JOIN benefreci br USING (nrodoc,tipodoc)
                        WHERE nrodoc = parametro->>'NroDocumento' OR nrodoc = parametro->>'NroAfiliado';
                                        
                        IF FOUND THEN  -- 071123 En este caso se tiene informacion de a quien pertenece el token
                            SELECT INTO rtoken * 
                            FROM persona_token 
                            WHERE pttoken = parametro->>'token' 
                                   AND nrodoc = rdocumento.titu
                             ORDER BY ptutilizado DESC  ----  nos aseguramos que si hay uno sin consumir aparece antes que el consumido
                             LIMIT 1;
                        ELSE
                            SELECT INTO rtoken * 
                            FROM persona_token 
                            WHERE pttoken = parametro->>'token'
                            ORDER BY ptutilizado DESC  ----  nos aseguramos que si hay uno sin consumir aparece antes que el consumido
                            LIMIT 1;
                        END IF;
                        IF FOUND THEN 
                                respuestajson = row_to_json(rtoken);
                                /*KR 24-07-20 Se comenta ya que existen muchos pedidos para prorrogar el vto del token
                            IF rtoken.ptfechavencimiento < now() THEN
                                RAISE EXCEPTION 'R-0011, El token ya se encuentra vencido, (%)',rtoken.ptfechavencimiento;
                                ELSE */
                                IF not nullvalue(rtoken.ptutilizado) THEN
                                        --SL 15/01/24 - Agrego "YYYY-MM-DD" al parametro del raice
                                    RAISE EXCEPTION 'R-012, El token figura consumido la Fecha: %.', TO_CHAR(rtoken.ptutilizado, 'YYYY-MM-DD HH24:MI:SS');
                                ELSE
                                        UPDATE persona_token SET ptutilizado = now()
                                            ,ptinfoutilizado=parametro->>'info_consumio_token' 
                                        WHERE idpersonatoken = rtoken.idpersonatoken --- VAS 071123 
                                               AND idcentropersonatoken  = rtoken.idcentropersonatoken; --- VAS 071123 
                                          --- 071123 puedo obtener el mismo token para diferentes persona pttoken = parametro->>'token';
                                        SELECT INTO rtoken * FROM persona_token 
                                        WHERE idpersonatoken = rtoken.idpersonatoken ----VAS 071123 
                                               AND idcentropersonatoken  = rtoken.idcentropersonatoken ; --- VAS 071123 
                                        --- pttoken = parametro->>'token'; 071123 puedo obtener el mismo token para diferentes persona pttoken = parametro->>'token'
                                        respuestajson = row_to_json(rtoken);
                                END IF;
                        --END IF;
                 ELSE 
            --RAISE EXCEPTION 'R-0013, El token no existe ,(%)',parametro;
                        
                            IF CHAR_LENGTH(parametro->>'token') >=8 THEN
                                   INSERT INTO persona_token (pttoken,ptinfoutilizado,ptutilizado) VALUES(parametro->>'token','Lo cargo Malapi',now());
                                   SELECT INTO rtoken * FROM persona_token WHERE pttoken = parametro->>'token';
                       respuestajson = row_to_json(rtoken);
                            ELSE
                                   RAISE EXCEPTION 'R-0013, El token no existe o no coincide con el afiliado,(%)',parametro;
                            END IF;
                       
                END IF;
             END IF;
        END IF;     
       
      return respuestajson;

end;$function$
