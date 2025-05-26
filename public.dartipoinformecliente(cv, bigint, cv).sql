CREATE OR REPLACE FUNCTION public.dartipoinformecliente(character varying, bigint, character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Funcion que verifica dado un cliente y un tipo de comprobante cual es el tipo de informe que 
corresponde. Esto es asi ya que para AMUC, si el tipo de comprobante es FA entonces la cuenta que debe
usar es la 10323 (SOSUNC) y si es una LI entonces la 10818 (FARMACIA) */
DECLARE
     
--registros
       resultado  RECORD;
--variables
    eltipoinfo integer;
BEGIN
    
     SELECT INTO resultado * FROM
     (
     SELECT idinformefacturaciontipo FROM informefacturaciontipo 
     LEFT JOIN cliente ON lower(replace(cliente.denominacion,'.',''))  SIMILAR TO lower(replace(iftdescripcion,'.',''))
     WHERE cliente.nrocliente=$1 AND cliente.barra=$2 AND $3='FA'
     UNION 
     SELECT 2 FROM osreci
     WHERE osreci.idosreci=$1 AND osreci.barra=$2 AND $3='FA') AS T;

     IF FOUND THEN
	eltipoinfo=resultado.idinformefacturaciontipo;
     ELSE  
          IF ($3='LI') THEN
                 eltipoinfo=12;
         
          END IF;
      END IF;
       
       
RETURN eltipoinfo;
END;
$function$
