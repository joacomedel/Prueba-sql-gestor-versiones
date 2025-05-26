CREATE OR REPLACE FUNCTION public.armarbloquectactepagocliente()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
	regpago  RECORD;
	regdeudapago RECORD;
        uncomprobante RECORD;

--CURSOR
  	ctempcomprobante refcursor;
	
--VARIABLES
        nuevosaldodeuda double precision ;
        nuevosaldopago double precision ;
        importeimput double precision ;
        difdeudapago double precision ;
	eliddeuda bigint;
	elidcentrodeuda  integer;
	elidpago bigint;
	elidcentropago integer;
	elmontopagado double precision;
	elmontoimputar double precision;
  	respuesta boolean;
  	pidimputacion bigint;
	
BEGIN
   
      pidimputacion = nextval('ctactedeudapagocliente_idimputacion_seq');

     OPEN ctempcomprobante FOR SELECT * FROM ctactepagocliente;

     FETCH ctempcomprobante into regpago;
     WHILE FOUND LOOP

            UPDATE ctactedeudapagocliente set  idimputacion = pidimputacion
                                  where idpago =regpago.idpago and idcentropago= idcentropago;
    
          FETCH ctempcomprobante into regpago;
           
           pidimputacion = nextval('ctactedeudapagocliente_idimputacion_seq');
     END LOOP;
     close ctempcomprobante;

   
     respuesta =true;

RETURN respuesta;

END;
$function$
