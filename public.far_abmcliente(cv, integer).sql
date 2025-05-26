CREATE OR REPLACE FUNCTION public.far_abmcliente(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */

DECLARE
--record
rpersona RECORD;
rafil RECORD;
rcliente RECORD;
rbenef RECORD;

--variables
elafiliado INTEGER;
vnrocliente VARCHAR;
vbarracliente INTEGER;

BEGIN

SELECT INTO rpersona *, concat(apellido ,', ', nombres) as nombreapellido FROM persona WHERE nrodoc = $1 AND tipodoc = $2;
IF FOUND THEN
      SELECT INTO rbenef * FROM 
          (SELECT nrodoctitu,tipodoctitu FROM benefsosunc WHERE nrodoc = $1 AND tipodoc = $2 AND idestado<>4
		UNION 
	   SELECT nrodoctitu,tipodoctitu FROM benefreci WHERE nrodoc = $1 AND tipodoc = $2 AND idestado<>4
		) AS T;
      IF FOUND THEN --ES un beneficiario
             vnrocliente = rbenef.nrodoctitu;
             vbarracliente = rbenef.tipodoctitu;
      ELSE
	
             vnrocliente = rpersona.nrodoc;
             vbarracliente = rpersona.tipodoc;
      END IF;

      SELECT into rafil * from far_afiliado WHERE nrodoc = $1 AND tipodoc = $2 and idobrasocial=9;

      IF NOT FOUND THEN

          -- NO estÃ¡ cargado en far_afiliado con otra Obra Social

          	INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,tipodoc,nrodoc,nrocliente,barra,aapellidoynombre,iddireccion)
           	VALUES(9,$1,$2,$1,trim(lpad(vnrocliente, 8, '0'))  ,vbarracliente,rpersona.nombreapellido,rpersona.iddireccion);
                elafiliado = currval('far_afiliado_idafiliado_seq');
      END IF;

      SELECT INTO rcliente * FROM cliente where nrocliente = vnrocliente;
      IF NOT FOUND THEN
                        INSERT INTO  cliente(nrocliente,barra,idtipocliente,idcondicioniva,iddireccion,denominacion,idcentrodireccion)
                        VALUES (trim(lpad(vnrocliente, 8, '0'))  ,vbarracliente,5,1,rpersona.iddireccion,rpersona.nombreapellido,rpersona.idcentrodireccion);
      END IF;
      
END IF;
return true;

END;
$function$
