CREATE OR REPLACE FUNCTION public.beneficiariososunc(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  
    
	usuario alias for $4;
    rec RECORD;
    rec1 RECORD;
    bandera boolean;

BEGIN

    SELECT INTO rec * FROM persona WHERE tipodoc = $1 AND nrodoc =$2 AND barra = $3;
    SELECT INTO rec1 * FROM tiposdoc WHERE tipodoc = $1;
    
IF FOUND
  THEN--existe una persona y sera cargada en la tabla para reportes rpersonalesuno
	DELETE FROM rpersonalesuno WHERE idusuario = usuario;
  	INSERT INTO rpersonalesuno VALUES(rec.nrodoc,rec.apellido,rec.nombres,rec.fechanac,rec.sexo,rec.estcivil,rec.email,rec.carct,rec.telefono,'true',rec1.descrip,rec.barra,usuario);
  	bandera ='true';
  ELSE --no hay una persona con los datos especificados como parÃ¡metros
   	bandera = 'false';
END IF;
    bandera='false';
	FOR rec IN SELECT * 
                FROM persona INNER JOIN benefsosunc  
                    ON (persona.nrodoc = benefsosunc.nrodoc  
                      AND persona.tipodoc = benefsosunc.tipodoc)
                WHERE benefsosunc.nrodoctitu=$2 
                AND benefsosunc.tipodoctitu=$1 
                AND benefsosunc.barratitu=$3 
               
    LOOP
    bandera = 'true';
    
	INSERT INTO rpersonalesuno VALUES(rec.nrodoc,rec.apellido,rec.nombres,rec.fechanac,rec.sexo,rec.estcivil,rec.email,rec.carct,rec.telefono,'false',rec1.descrip,rec.barra,usuario);
	SELECT INTO bandera * FROM buscarpartpersonalesdosbenefsos(rec.tipodoc,rec.nrodoc,rec.barra,usuario);

   END LOOP ;
	
	RETURN bandera; 
END;
$function$
