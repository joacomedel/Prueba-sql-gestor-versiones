CREATE OR REPLACE FUNCTION public.beneficiarioreci(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  
    usuario alias for $4;
    rec RECORD;
    rec1 RECORD;
    bandera boolean;

BEGIN
	bandera = 'false';
    SELECT INTO rec * FROM persona WHERE tipodoc = $1 AND nrodoc =$2 AND barra = $3;
    SELECT INTO rec1 * FROM tiposdoc WHERE tipodoc = $1;
IF FOUND
  THEN--existe una persona y sera cargada en la tabla para reportes rpersonalesuno
	DELETE FROM rpersonalesuno WHERE idusuario = usuario;
  	INSERT INTO rpersonalesuno VALUES(rec.nrodoc,rec.apellido,rec.nombres,rec.fechanac,rec.sexo,rec.estcivil,rec.email,rec.carct,rec.telefono,'true',rec1.descrip,rec.barra,usuario);
  	bandera ='true';
     	
END IF;
    bandera='false';
	FOR rec IN SELECT * 
                FROM persona INNER JOIN benefreci  
                    ON (persona.nrodoc = benefreci.nrodoc  
                      AND persona.tipodoc = benefreci.tipodoc)
                WHERE benefreci.nrodoctitu=$2 
                AND benefreci.tipodoctitu=$1 
                AND benefreci.barratitu=$3 
                
    LOOP
    bandera = 'true';
    
	INSERT INTO rpersonalesuno VALUES(rec.nrodoc,rec.apellido,rec.nombres,rec.fechanac,rec.sexo,rec.estcivil,rec.email,rec.carct,rec.telefono,'false',rec1.descrip,rec.barra,usuario);
	SELECT INTO bandera * FROM buscarpartpersonalesdosbenefreci(rec.tipodoc,rec.nrodoc,rec.barra,usuario);
   END LOOP ;
	
	RETURN bandera; 
END;    
$function$
