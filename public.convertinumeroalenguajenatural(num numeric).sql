CREATE OR REPLACE FUNCTION public.convertinumeroalenguajenatural(num numeric)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
-- Función que devuelve la cadena de texto en castellano que corresponde a un número.
-- Parámetros: número con 2 decimales, máximo 999.999.999,99.
 
DECLARE	
	d VARCHAR[];
	f VARCHAR[];
	g VARCHAR[];
	numt VARCHAR;
	txt VARCHAR;
	a INTEGER;
	a1 INTEGER;
	a2 INTEGER;
	n INTEGER;
	p INTEGER;
	negativo BOOLEAN;
BEGIN
	-- Máximo 999.999.999,99
	IF num > 999999999.99 THEN
		RETURN '---';
	END IF;
	txt = '';
	d = ARRAY[' un',' dos',' tres',' cuatro',' cinco',' seis',' siete',' ocho',' nueve',' diez',' once',' doce',' trece',' catorce',' quince',
		' dieciseis',' diecisiete',' dieciocho',' diecinueve',' veinte',' veintiun',' veintidos', ' veintitres', ' veinticuatro', ' veinticinco',
		' veintiseis',' veintisiete',' veintiocho',' veintinueve'];
	f = ARRAY ['','',' treinta',' cuarenta',' cincuenta',' sesenta',' setenta',' ochenta', ' noventa'];
	g= ARRAY [' ciento',' doscientos',' trescientos',' cuatrocientos',' quinientos',' seiscientos',' setecientos',' ochocientos',' novecientos'];
	numt = LPAD((num::numeric(12,2))::text,12,'0');
	IF strpos(numt,'-') > 0 THEN
	   negativo = TRUE;
	ELSE
	   negativo = FALSE;
	END IF;
	numt = TRANSLATE(numt,'-','0');
	numt = TRANSLATE(numt,'.,','');
	-- Trato 4 grupos: millones, miles, unidades y decimales
	p = 1;
	FOR i IN 1..4 LOOP
		IF i < 4 THEN
			n = substring(numt::text FROM p FOR 3);
		ELSE
			n = substring(numt::text FROM p FOR 2);
		END IF;
		p = p + 3;
		IF i = 4 THEN
			IF txt = '' THEN
				txt = ' cero';
			END IF;
			IF n > 0 THEN
			-- Empieza con los decimales
				txt =concat( txt , ' con');
			END IF;
		END IF;
		-- Centenas 
		IF n > 99 THEN
			a = substring(n::text FROM 1 FOR 1);
			a1 = substring(n::text FROM 2 FOR 2);
			IF a = 1 THEN
				IF a1 = 0 THEN
					txt = concat(txt , ' cien');
				ELSE
					txt = concat(txt , ' ciento');
				END IF;
			ELSE
				txt = concat(txt , g[a]);
			END IF;
		ELSE
			a1 = n;
		END IF;
		-- Decenas
		a = a1;
		IF a > 0 THEN
			IF a < 30 THEN
				IF a = 21 AND (i = 3 OR i = 4) THEN
					txt = concat(txt , ' veintiuno');
				ELSIF n = 1 AND i = 2 THEN
					txt = txt; 
				ELSIF a = 1 AND (i = 3 OR i = 4)THEN
					txt = concat(txt , ' uno');
				ELSE
					txt = concat(txt , d[a]);
				END IF;
			ELSE
				a1 = substring(a::text FROM 1 FOR 1);
				a2 = substring(a::text FROM 2 FOR 1);
				IF a2 = 1 AND (i = 3 OR i = 4) THEN
						txt = concat(txt , f[a1] , ' y' , ' uno');
				ELSE
					IF a2 <> 0 THEN
						txt = concat(txt , f[a1] , ' y' , d[a2]);
					ELSE
						txt = concat(txt , f[a1]);
					END IF;
				END IF;
			END IF;
		END IF;
		IF n > 0 THEN
			IF i = 1 THEN
				IF n = 1 THEN
					txt = concat(txt , ' millón');
				ELSE
					txt = concat(txt , ' millones');
				END IF;
			ELSIF i = 2 THEN
				txt = concat(txt , ' mil');
			END IF;		
		END IF;
	END LOOP;
	txt = LTRIM(txt);
	IF negativo = TRUE THEN
	   txt= concat('-' , txt);
	END IF;
    RETURN txt;
END;
$function$
