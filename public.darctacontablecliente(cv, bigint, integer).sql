CREATE OR REPLACE FUNCTION public.darctacontablecliente(character varying, bigint, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* Funcion que dado un tipo de informe y cliente devuelve la cuenta contable a aplicar */
DECLARE
     
--registros
       resultado  RECORD;
--variables
    elnrocuentactipoinfo integer;
BEGIN
    
     SELECT INTO resultado * FROM informefacturaciontipo 
      WHERE idinformefacturaciontipo = $3;
     

      IF FOUND AND nullvalue(resultado.nrocuentac) THEN
	SELECT INTO resultado * FROM far_obrasocial JOIN cliente 
			ON(oscuit ILIKE concat(cuitini,cuitmedio,cuitfin))
		WHERE nrocliente=$1 AND barra=$2;
	IF FOUND THEN 
		elnrocuentactipoinfo=resultado.nrocuentac;
	END IF; 
      ELSE
	elnrocuentactipoinfo=resultado.nrocuentac;
      END IF;
       
       
RETURN elnrocuentactipoinfo;
END;
$function$
