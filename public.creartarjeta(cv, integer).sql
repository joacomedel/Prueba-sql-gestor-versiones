CREATE OR REPLACE FUNCTION public.creartarjeta(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	datotarjeta RECORD;
        latarjeta RECORD;
	datocupon RECORD;
        resp boolean;
        elnrodoc character varying;
	eltipodoc INTEGER;
	idnrotarjeta INTEGER;
        tarjetas refcursor;


BEGIN
      elnrodoc =$1;
     eltipodoc =$2;
     ---- Al crear una tarjeta nueva hay que dar de baja a la que esta en circulacion
      -- Busco la tarjeta del afiliado que se encuentra en circulacion (que no fue dada de baja idestadotipo <> 4; )

     open tarjetas for SELECT  *
     FROM  tarjeta
     NATURAL JOIN  tarjetaestado
     NATURAL JOIN  cupon
     join cuponestado using(idcupon,idcentrocupon)
     WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and nullvalue(tefechafin) and tarjetaestado.idestadotipo <> 4
            and nullvalue(cefechafin);

    -- Si hay una tarjeta en circulacion la doy de baja

    fetch tarjetas into latarjeta;
    while FOUND loop
                SELECT INTO resp cambiarestadotarjeta(latarjeta.idtarjeta,latarjeta.idcentrotarjeta,4);
                SELECT INTO resp cambiarestadocupon(latarjeta.idcupon,latarjeta.idcentrocupon,4);
                             
               fetch tarjetas into latarjeta;

    END loop;

	INSERT INTO tarjeta(nrodoc,tipodoc) values ($1,$2);

	idnrotarjeta =  currval('tarjeta_idtarjeta_seq');
    SELECT INTO resp cambiarestadotarjeta(idnrotarjeta,centro(),1);

    -- Se crea un nuevo cupon
    SELECT INTO resp crearcupon(idnrotarjeta,centro());


RETURN 'true';
END;
$function$
