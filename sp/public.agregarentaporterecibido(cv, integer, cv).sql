CREATE OR REPLACE FUNCTION public.agregarentaporterecibido(character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*agregarentaporterecibido('28272137',30,'MALAPI')
$1 nrodoc
$2 barra
$3 usuario
*/
DECLARE
    verifica RECORD;
    nrodocumento alias for $1;
	barrasel alias for $2;
	usu alias for $3;
BEGIN
     SELECT INTO verifica * FROM taporterecibido WHERE taporterecibido.nrodoc = nrodocumento
                            and taporterecibido.barra = barrasel
                            and taporterecibido.usuario = usu;
     IF NOT found THEN
        INSERT INTO taporterecibido
         SELECT nrodoc,barra,usu FROM (
               SELECT nrodoc, barra FROM persona
                 NATURAL JOIN afilsosunc
                 WHERE nrodoc = nrodocumento AND barra = barrasel
                UNION
                SELECT nrodoc, barra FROM persona
                        NATURAL JOIN benefsosunc
                  WHERE nrodoctitu = nrodocumento
                        and idestado <> 4
        ) AS uniDatos;

  	    --INSERT INTO taporterecibido (nrodoc,barra,usuario) values (nrodocumento,barrasel,usu);
     end if;

return true;
END;
$function$
