CREATE OR REPLACE FUNCTION public.contabilidad_abmliquidacioniva(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	resp character varying;
        rperiodofiscal RECORD;
        rparam  RECORD;
        rfechas RECORD;
        resp_info_ejercico varchar;
        ranio  RECORD;
        rresp RECORD ;
BEGIN
 
  EXECUTE sys_dar_filtros($1) INTO rparam;
 
  SELECT INTO rperiodofiscal date_part('YEAR',pffechadesde) as liq_iva_anio,*
  FROM contabilidad_periodofiscal
  WHERE idperiodofiscal = rparam.idperiodofiscal;
  resp='false';
  IF FOUND THEN 
      IF(rparam.accion='cerrar') THEN
         IF nullvalue(rperiodofiscal.pfcerrado) THEN 
             --- Lo cierro
             UPDATE contabilidad_periodofiscal SET pfcerrado = now()    
             WHERE idperiodofiscal =   rparam.idperiodofiscal and nullvalue(pfcerrado);
              resp='true';
         END IF;
      END IF;
      
      IF(rparam.accion='abrir') THEN
           -- 1 busco el anio de la fecha del ejercicio correspondiente
           SELECT INTO resp_info_ejercico  contabilidad_ejercicio_info(concat('{agfechacontable=',rperiodofiscal.pffechadesde,',idasientogenericocomprobtipo=99}'));  --- cuando no se conoce el idasientogenericocomprobtipo enviar el valor 99
           EXECUTE sys_dar_filtros(resp_info_ejercico) INTO rresp;
           SELECT INTO ranio date_part('YEAR',rresp.fechaimputacion) as anioejercicio; 
           --

           -- solo se debe poder habrir una liquidacion iva si corresponde a un ejercicio abierto si esta cerrado NO SE PUEDE ABRIR
           IF (ranio.anioejercicio::integer =  rperiodofiscal.liq_iva_anio::integer) AND NOT nullvalue(rperiodofiscal.pfcerrado) THEN 
                      --- La abro
                       UPDATE contabilidad_periodofiscal SET pfcerrado = NULL
                       WHERE idperiodofiscal = rparam.idperiodofiscal and not nullvalue(pfcerrado);
                       resp = 'true';
           ELSE 
                 RAISE EXCEPTION 'No es posible abrir una LIQ IVA de un ejercicio cerrado';
           END IF;
      END IF;
  END IF;


return resp;
END;
$function$
