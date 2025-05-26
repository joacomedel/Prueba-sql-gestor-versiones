CREATE OR REPLACE FUNCTION public.gestionartarjetaafiliado(character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
      -- Busco la tarjeta del afiliado que se encuentra en circulacion (que no fue dada de baja
      --idestadotipo <> 4; )
  
    latarjeta record;
    elcupon  RECORD;
    tarjetaexis record;
	resp boolean;
	elnrodoc character varying;
    eltipodoc integer;
    elidestadotipo integer;
     ----     1    SOLICITADO
     ----     2    CONFECCIONADO
     ----     3    ENTREGADO
     ----     4    De BAJA
BEGIN
     elnrodoc =$1;
     eltipodoc =$2;
     elidestadotipo= $3;

     IF (elidestadotipo = 1 )THEN
            SELECT INTO resp creartarjeta(elnrodoc, eltipodoc);
     END IF;

     IF (elidestadotipo = 2 or  elidestadotipo = 3 or elidestadotipo = 4) THEN
             --si hay mas de una tarjeta para la persona, a la primera q encuentro la cambio de estado
             -- y al resto  le doy de baja
             SELECT into latarjeta *
             FROM  tarjeta
             NATURAL JOIN  persona
             NATURAL JOIN  tarjetaestado
             WHERE nrodoc=$1 and tipodoc=$2 and nullvalue(tefechafin) and idestadotipo <> 4;

             IF found THEN
                SELECT INTO resp cambiarestadotarjeta(latarjeta.idtarjeta,latarjeta.idcentrotarjeta,elidestadotipo);
                       -- Si se entrega la tarjeta tambien entrego el cupon vinculado a la tarjeta
                      IF (  elidestadotipo = 2 or elidestadotipo = 3) THEN
                             SELECT INTO elcupon *
                             FROM cupon
                             WHERE idcentrotarjeta =latarjeta.idcentrotarjeta and idtarjeta =latarjeta.idtarjeta;
                             SELECT INTO resp cambiarestadocupon( elcupon.idcupon,elcupon.idcentrocupon,elidestadotipo);
                             IF (latarjeta.barra=35 and elidestadotipo = 3)then   ----si se trata de un jubilado y estoy entregando la tarjeta entonces creo el cupon del mes siguiente
                                       select into resp crearcupon(latarjeta.idtarjeta,latarjeta.idcentrotarjeta);
                             end if;
                             ---- Guardo el login por defecto para la primer tarjeta
                             INSERT INTO tarjetalogin (tlbloqueada, idtarjeta ,idcentrotarjeta,
                             tlcodigo , tlcambiarpass )VALUES(false ,latarjeta.idtarjeta,latarjeta.idcentrotarjeta
                             , md5 (substr($1 , 0, 5) ),true );

                      END IF;
              END IF;
     END IF;

RETURN resp;
END;
$function$
