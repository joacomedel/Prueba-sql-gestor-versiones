CREATE OR REPLACE FUNCTION public.anularorden(nroorden bigint, centro integer, idusuario integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
rusuario record;
elidusuario integer;
BEGIN

 /* Se guarda la informacion del usuario  */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF not found THEN
             elidusuario = 25;
    ELSE
        elidusuario = rusuario.idusuario;
    END IF;
      INSERT INTO ordenestados (idordenventaestadotipo,nroorden,centro,idusuario) VALUES($3,$1,$2,elidusuario);
     
 if ($3="53" || $3="37"  ) then 
			
				 SELECT  * from expendio_cambiarestadoorden ($1, $2, 2);
 else 
				
                
                
     DELETE FROM ordenessinfacturas WHERE nroorden=$1 AND centro=$2;
     DELETE FROM itemordenessinfactura WHERE nroorden=$1 AND centro=$2;
     
     end if;

return true;
END;
$function$
