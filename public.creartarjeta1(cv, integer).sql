CREATE OR REPLACE FUNCTION public.creartarjeta1(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	datotarjeta RECORD;
	datocupon RECORD;
    resp boolean;
    elnrodoc character varying;
	eltipodoc INTEGER;
	idnrotarjeta INTEGER;



BEGIN
      elnrodoc =$1;
     eltipodoc =$2;
     ---- Al crear una tarjeta nueva hay que dar de baja a la que esta en circulacion
      -- Busco la tarjeta del afiliado que se encuentra en circulacion (que no fue dada de baja idestadotipo <> 4; )

     SELECT INTO datotarjeta *
     FROM  tarjeta
     NATURAL JOIN  tarjetaestado
     WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and nullvalue(tefechaini) and idestadotipo <> 4;

    -- Si hay una tarjeta en circulacion la doy de baja
     IF FOUND THEN
        SELECT INTO resp cambiarestadotarjeta(idtarjeta,idcentrotarjeta,4);
     END IF;

	INSERT INTO tarjeta(nrodoc,tipodoc) values ($1,$2);

	idnrotarjeta =  currval('tarjeta_idtarjeta_seq');
    SELECT INTO resp cambiarestadotarjeta(idnrotarjeta,centro(),1);

    -- Se crea un nuevo cupon
    SELECT INTO resp crearcupon(idnrotarjeta,centro());


RETURN 'true';
END;
$function$
