CREATE OR REPLACE FUNCTION public.insertarestadonuevapers(integer, integer, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	tipoafiliado alias for $1;
	tipodocumento alias for $2;
	nrodocumento alias for $3;
	estadonuevo alias for $4;
	camb Record;
	resultado boolean;
BEGIN
resultado = 'true';
-- 1 = afiliados titulares de sosunc
if(tipoafiliado = 1)
	then
		INSERT INTO cambioestafil (tipodoc,nrodoc,idestado,fechaini) VALUES(tipodocumento,nrodocumento,estadonuevo,current_timestamp);
end if;
-- 2 = beneficiarios de sosunc
if(tipoafiliado = 2)
	then
	    SELECT INTO camb * FROM cambioestbenef WHERE cambioestbenef.nrodoc = nrodocumento
                                                     AND cambioestbenef.tipodoc = tipodocumento
                                                     AND cambioestbenef.idestado = estadonuevo
                                                     AND cambioestbenef.fechaini = current_timestamp;
        IF Not Found THEN
		INSERT INTO cambioestbenef (tipodoc,nrodoc,idestado,fechaini) VALUES(tipodocumento,nrodocumento,estadonuevo,current_timestamp);
		END If;
end if;
-- 3 = afiliados titulares de reciprocidad
if(tipoafiliado = 3)
	then
		INSERT INTO cambioestafilreci (tipodoc,nrodoc,idestado,fechaini) VALUES(tipodocumento,nrodocumento,estadonuevo,current_timestamp);
end if;
-- 4 = beneficiarios de reciprocidad
if(tipoafiliado = 4)
	then 
		INSERT INTO cambioestbenefreci(tipodoc,nrodoc,idestado,fechaini) VALUES(tipodocumento,nrodocumento,estadonuevo,current_timestamp);
	else
		resultado = 'false';
end if;
return resultado;
END;
$function$
