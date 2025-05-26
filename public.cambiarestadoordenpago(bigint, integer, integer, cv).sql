CREATE OR REPLACE FUNCTION public.cambiarestadoordenpago(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    
     


--REGISTROS
rusuario record;

--VARIABLES
elidusuario integer;
resultado BOOLEAN;
vretorno varchar;

BEGIN


  /* Se guarda la informacion del usuario  */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF not found THEN
             elidusuario = 25;
    ELSE
        elidusuario = rusuario.idusuario;
    END IF;

              INSERT INTO cambioestadoordenpago(fechacambio,nroordenpago,idtipoestadoordenpago,motivo,idcentroordenpago,idusuario) 
	      VALUES(CURRENT_DATE,$1,$3,$4,$2,elidusuario);

/* KR 18-01-19 Si la minuta generó un movimiento en la cta cte del afiliado lo cancelo, verifico que sea un movimiento en la deuda, que es el uso que hoy se le está dando. Faltaría implementar la cancelación si el movimiento es en el pago - idcomprobantetipos=12 es migración ASI*/
--KR 04-06-19 solo se anula el movimiento en la cta cte si la minuta se anula, estado 4
  IF ($3=4) THEN
    SELECT INTO resultado * FROM anularmovimientoctacteafiliado($1,$2);
  END IF;

/*KR 11-11-20 Llamo al SP que genera movimiento en la deuda si corresponde*/
 --MaLaPi 13/05/2021 Ahora la duda se genera desde la factura cuando se emite
--SELECT INTO vretorno * from ctacte_abmmovimiento(concat('nroordenpago =',$1,',', 'idcentroordenpago=',$2,',','idtipoestadoordenpago=', $3));

return true;
END;

$function$
