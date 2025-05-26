CREATE OR REPLACE FUNCTION public.actualizarctasctes()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
*/
DECLARE
	afiliados CURSOR FOR SELECT * FROM afilsosunc ;
	resultado boolean;
	resultado2 boolean;
	afiliado RECORD;
	nrodoc varchar;
	tipodoc integer;
	
BEGIN
     resultado = true;
     OPEN afiliados;
     FETCH afiliados INTO afiliado;
     WHILE  found LOOP
            nrodoc = afiliado.nrodoc;
            tipodoc = afiliado.tipodoc;
            SELECT INTO resultado2 *
                       FROM actualizarctacte(nrodoc,tipodoc);
            FETCH afiliados INTO afiliado;
            END LOOP;
     CLOSE afiliados;
     return resultado;
END;
$function$
