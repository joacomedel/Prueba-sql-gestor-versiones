CREATE OR REPLACE FUNCTION public.contabilidad_periodofiscal_info(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	resp character varying;
        rperiodof RECORD;
        rparam  RECORD;
        rfechas  RECORD;
        elidperiodofiscal  bigint;
BEGIN
  resp = null;
  EXECUTE sys_dar_filtros($1) INTO rparam;
   SELECT INTO rperiodof *  
         ,CASE WHEN (rparam.fechaemicioncomp >= pffechadesde) THEN rparam.fechaemicioncomp
               WHEN (rparam.fechaemicioncomp < pffechadesde) THEN pffechadesde
               
         END as fechaimputacion 
 
  FROM contabilidad_periodofiscal
  WHERE pftipoiva = rparam.pftipoiva 
        AND ( (pffechadesde <= rparam.fechaemicioncomp  -- se imputa en el que corresponde
            and pffechahasta >= rparam.fechaemicioncomp
            and  (nullvalue(pfcerrado) or  NOW()<= pfcerrado)
            )
            or (pffechadesde >rparam.fechaemicioncomp -- en el que encuentra abierto
		 and (nullvalue(pfcerrado) or  NOW()<= pfcerrado)
		)
        )
     order by pffechadesde asc 
     limit 1;
     IF FOUND THEN
        resp =  concat('{fechaimputacion=',rperiodof.fechaimputacion,',idperiodofiscal=',rperiodof.idperiodofiscal,'}');
     ELSE  -- Si estamos en sede central y no hay un periodo fiscal para la fecha actual creo un nuevo periodo fiscal
           IF (centro()=1) THEN
                      SELECT INTO rperiodof *  
                             ,CASE WHEN ( now() >= pffechadesde) THEN  now()
                             WHEN ( now() < pffechadesde) THEN pffechadesde
                             END as fechaimputacion 
 
                     FROM contabilidad_periodofiscal
                     WHERE  pftipoiva=rparam.pftipoiva  AND
                            pffechadesde <=  now()
                           AND pffechahasta >= now();
                     IF not FOUND THEN 
                               --- Creo el nuevo periodo
                               SELECT INTO rfechas to_char( date_trunc('month',now())+'1month' ::interval-'1sec' ::interval, 'YYYY-MM-DD' ) as fechafin  
                                         ,to_char(date_trunc('month',now()::date) , 'YYYY-MM-DD' )as fechainicio
                                         ,to_char(date_trunc('day',now())+'17day' ::interval-'1sec' ::interval, 'YYYY-MM-DD') as pfcerrado ;    
                               INSERT INTO  contabilidad_periodofiscal (pffechadesde,pffechahasta,pftipoiva)
                                      VALUES(rfechas.fechainicio::date,rfechas.fechafin::date,rparam.pftipoiva);
                               elidperiodofiscal = currval('public.contabilidad_periodofiscal_idperiodofiscar_seq');
                               resp =  concat('{fechaimputacion=',rfechas.fechainicio::date,',idperiodofiscal=',elidperiodofiscal,'}'); 
                     END IF;
          END IF;
     END IF;
return resp;
END;
$function$
