CREATE OR REPLACE FUNCTION ca.actualizarmontoactacuerdo0221(bigint, double precision, double precision, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    
 
BEGIN

    
             UPDATE  ca.conceptotope
             SET ctfechahasta=NOW()
             WHERE idcategoria=$4 and nullvalue(ctfechahasta);

             INSERT INTO ca.conceptotope (idconcepto,ctmontominimo,ctmontomaximo,idcategoria)
             VALUES($1,$2,$3,$4);

return true;
END;

 
$function$
