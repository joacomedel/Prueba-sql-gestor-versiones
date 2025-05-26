CREATE OR REPLACE FUNCTION public.insertarcambioestado(integer, integer, character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	tipoafiliado alias for $1;
	tipodocumento alias for $2;
	nrodocumento alias for $3;
	estadoanterior alias for $4;
	estadonuevo alias for $5;
	aux RECORD;
	resultado boolean;
BEGIN
resultado = 'true';
-- 1 = afiliados titulares de sosunc
if(tipoafiliado = 1) then
		SELECT INTO aux * FROM cambioestafil WHERE cambioestafil.nrodoc = nrodocumento
                          AND cambioestafil.tipodoc = tipodocumento
                          AND cambioestafil.idestado = estadonuevo
                          AND cambioestafil.fechaini = current_timestamp
                          AND fechafin = '9999-12-31';
        IF NOT Found THEN
        		UPDATE cambioestafil SET fechafin = current_date WHERE tipodoc = tipodocumento AND nrodoc = nrodocumento AND fechafin = '9999-12-31';
		        INSERT INTO cambioestafil (tipodoc,nrodoc,idestado,fechaini) VALUES(tipodocumento,nrodocumento,estadonuevo,current_timestamp);
        END IF;
end if;
-- 2 = beneficiarios de sosunc
if(tipoafiliado = 2) then
		SELECT INTO aux * FROM cambioestbenef WHERE cambioestbenef.nrodoc = nrodocumento AND cambioestbenef.tipodoc = tipodocumento
               AND cambioestbenef.idestado = estadonuevo
                AND cambioestbenef.fechaini = current_timestamp
               AND fechafin = '9999-12-31';
        IF NOT Found THEN
           SELECT INTO aux * FROM cambioestbenef WHERE cambioestbenef.nrodoc = nrodocumento AND cambioestbenef.tipodoc = tipodocumento
                           AND cambioestbenef.idestado = estadonuevo
                           AND fechafin = current_date;
           IF NOT FOUND THEN
                      UPDATE cambioestbenef SET fechafin = current_date WHERE tipodoc = tipodocumento AND nrodoc = nrodocumento  AND fechafin = '9999-12-31';
                      INSERT INTO cambioestbenef (tipodoc,nrodoc,idestado,fechaini) VALUES(tipodocumento,nrodocumento,estadonuevo,current_timestamp);
           END IF;
           if estadonuevo = 4 then
--MaLaPi 15/02/2012 esto lo modifico porque intento resolver las barras = 0 en persona, ademas no entiendo para que es necesario este sp.
				--SELECT INTO resultado * FROM borrarbarrabenefyactualizarbarrapersona(tipodocumento,nrodocumento);
           end if;
		END IF;
end if;
-- 3 = afiliados titulares de reciprocidad
if(tipoafiliado = 3) then
        SELECT INTO aux * FROM cambioestafilreci WHERE cambioestafilreci.nrodoc = nrodocumento
        AND cambioestafilreci.tipodoc = tipodocumento
         AND cambioestafilreci.fechaini = current_timestamp
        AND cambioestafilreci.idestado = estadonuevo
        AND fechafin = '9999-12-31';
        IF NOT Found THEN
   		   UPDATE cambioestafilreci SET fechafin = current_date WHERE tipodoc = tipodocumento AND nrodoc = nrodocumento AND fechafin = '9999-12-31';
		   INSERT INTO cambioestafilreci (tipodoc,nrodoc,idestado,fechaini) VALUES(tipodocumento,nrodocumento,estadonuevo,current_timestamp);
        END IF;
end if;
-- 4 = beneficiarios de reciprocidad
if(tipoafiliado = 4) then
        SELECT INTO aux * FROM cambioestbenefreci WHERE cambioestbenefreci.nrodoc = nrodocumento
        AND cambioestbenefreci.tipodoc = tipodocumento
        AND cambioestbenefreci.fechaini = current_timestamp
        AND cambioestbenefreci.idestado = estadonuevo
        AND fechafin = '9999-12-31';
        IF NOT Found THEN
        		UPDATE cambioestbenefreci SET fechafin = current_date WHERE tipodoc = tipodocumento AND nrodoc = nrodocumento  AND fechafin = '9999-12-31';
		        INSERT INTO cambioestbenefreci(tipodoc,nrodoc,idestado,fechaini) VALUES(tipodocumento,nrodocumento,estadonuevo,current_timestamp);
        end if;
	else
		resultado = 'false';
end if;
return resultado;
END;
$function$
