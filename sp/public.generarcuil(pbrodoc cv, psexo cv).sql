CREATE OR REPLACE FUNCTION public.generarcuil(pbrodoc character varying, psexo character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare

	codigo varchar;
	cuil varchar;
        x char;
	codigoarray text[];
	dniarray text[];
        acumulador int;
        multiplica int;
        indice int;
        resto int;
	inicio varchar;
	fin varchar;
        nrodoc varchar;
        
begin
	nrodoc = pbrodoc;
	IF psexo = 'M' THEN
		pbrodoc = concat('20',pbrodoc);
		inicio = '20';
	ELSE
		IF psexo = 'F' THEN
			pbrodoc = concat('27',pbrodoc);
			inicio = '27';

		ELSE
			pbrodoc = concat('30',pbrodoc);
			inicio = '30';
		END IF;
	END IF;

	codigo = '5432765432';
	codigoarray = string_to_array(codigo,null);
	dniarray = string_to_array(pbrodoc,null);
	indice = 1;
        acumulador = 0;
	

	FOREACH x IN ARRAY codigoarray LOOP
		
	multiplica = x::int * dniarray[indice]::int;
	acumulador = acumulador + multiplica;
	RAISE NOTICE 'i: % % %', x,dniarray[indice],acumulador;
	indice = indice + 1;
	END LOOP;
	resto = acumulador%11;
	
        IF resto = 0 THEN
		fin = '0';
	ELSE 
		IF resto = 1 THEN
/*• Si es Hombre, entonces Z (Dígito de Verificación) es igual a 9 (nueve) y XY es igual a 23 (veintitrés).
• Si es Mujer, entonces Z (Dígito de Verificación) es igual a 4 (cuatro) y XY es igual a 23 (veintitrés).
• En cualquier otro caso Z (Dígito de Verificación) es igual a 11 (once) menos el resto del cociente. */
			IF psexo = 'M' THEN
				inicio = '23';
				fin='9';
			ELSE
				fin='4';
				inicio = '23';
			END IF;
		ELSE
		    fin = (11 - resto)::text;
		END IF;

	END IF;
	cuil = concat(inicio,'-',nrodoc,'-',fin);
	RAISE NOTICE ' resto % fin % cuil %', resto,fin,cuil;
     return cuil;
end;
$function$
