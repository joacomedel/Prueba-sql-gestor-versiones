CREATE OR REPLACE FUNCTION public.actualizaramucba(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	baja CURSOR FOR SELECT * FROM bajaafiliado;
	elem RECORD;
	aux RECORD;
	auto BOOLEAN;
	doc BOOLEAN;
	nodoc BOOLEAN;
	recur BOOLEAN;
	sos BOOLEAN;
	resultado BOOLEAN;
	
BEGIN
auto = 'true';
doc = 'true';
nodoc = 'true';
recur = 'true';
sos = 'true';

--KR 22-07-21 no existe la tabla, se ve antes era fisica. 
IF (NOT iftableexists('rerrorba')) THEN
    CREATE TEMP TABLE rerrorba( 
		legajosiu int8, 
		nombre varchar,
		nromutu int8,
		nrodoc varchar,
                idusuario varchar);
else 
   delete from rerroraa;
END IF;

OPEN baja;
FETCH baja INTO elem;
WHILE  found LOOP
	SELECT INTO aux * FROM afiliauto WHERE nrodoc = elem.nrodoc;
 	if NOT FOUND
 		then
 			auto = 'false';
 		else
 	   		UPDATE afiliauto SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
    end if;
	SELECT INTO aux * FROM afilidoc WHERE nrodoc = elem.nrodoc;
 	if NOT FOUND
 		then
 			doc = 'false';
 		else
 	   		UPDATE afilidoc SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
    end if;
    SELECT INTO aux * FROM afilinodoc WHERE nrodoc = elem.nrodoc;    
 	if NOT FOUND
 		then
 			nodoc = 'false';
 		else
 	   		UPDATE afilinodoc SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
    end if;
    SELECT INTO aux * FROM afilirecurprop WHERE nrodoc = elem.nrodoc;    
 	if NOT FOUND
 		then
 			recur = 'false';
 		else
 	   		UPDATE afilirecurprop SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
    end if;
    SELECT INTO aux * FROM afilisos WHERE nrodoc = elem.nrodoc;
 	if NOT FOUND
 		then
 			sos = 'false';
 		else
 	   		UPDATE afilisos SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
    end if;
resultado = 'true';
if auto  
	then   resultado = 'false';
end if;
if doc 
	then   resultado = 'false';
end if;
if nodoc
	then   resultado = 'false';
end if;
if recur
	then   resultado = 'false';
end if;
if sos
	then   resultado = 'false';
end if;	        	 		  				
if resultado
	then

		INSERT INTO rerrorba VALUES(elem.legajosiu,elem.nombre,elem.nromutu,elem.nrodoc,$1);
end if;
auto = 'true';
doc = 'true';
nodoc = 'true';
recur = 'true';
sos = 'true';
fetch baja into elem;
END LOOP;
CLOSE baja;
return 'true';
END;
$function$
