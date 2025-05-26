CREATE OR REPLACE FUNCTION public.datoscarnetsordenados(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    rec RECORD;
	aux RECORD;

BEGIN
--Busco el titular en person, segun la barra que han mandado
 FOR rec IN SELECT * FROM persona WHERE persona.barra= $1 LOOP
	INSERT INTO datosCarnets VALUES(rec.barra,rec.nrodoc,rec.apellido,rec.nombres,rec.fechafinos);
        --Inserto todos los beneficiarios activos de ese titular
        FOR aux IN SELECT * FROM persona,benefsosunc WHERE persona.tipodoc = benefsosunc.tipodoctitu  
                                                        AND  persona.nrodoc= benefsosunc.nrodoctitu 
                                                        AND benefsosunc.nrodoctitu = rec.nrodoc 
                                                        AND benefsosunc.tipodoctitu = rec.tipodoc  
                                                        AND benefSosunc.idestado <> 4 LOOP
	            INSERT INTO datosCarnets VALUES(aux.barra,aux.nrodoc,aux.apellido,aux.nombres,aux.fechafinos);
        END LOOP ;
 END LOOP ;

RETURN 'true';
END;
$function$
