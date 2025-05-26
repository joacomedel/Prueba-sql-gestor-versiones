CREATE OR REPLACE FUNCTION public.contabilidad_ejercicio_info(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	resp character varying;
        rejercicio RECORD;
        rparam  RECORD;
        rfechas  RECORD;
        elidejercicio  bigint;
BEGIN
/**
Este SP retorna el ejerciio contable que corresponde segun la fecha enviada por parametro con clave agfechacontable
resp_info_ejercico  contabilidad_ejercicio_info(concat('{agfechacontable=','2022-01-01',',idasientogenericocomprobtipo=99}')); cuando no se conoce el idasientogenericocomprobtipo enviar el valor 99

*/
  resp = null;
  EXECUTE sys_dar_filtros($1) INTO rparam;
   SELECT INTO rejercicio *
         ,CASE WHEN (rparam.agfechacontable >= ecfechadesde) THEN rparam.agfechacontable
               WHEN ((rparam.agfechacontable < ecfechadesde) AND(rparam.idasientogenericocomprobtipo=6)) THEN ecfechaimpxcierre_asientomanual -- es un asiento manual
               WHEN ((rparam.agfechacontable< ecfechadesde) AND(rparam.idasientogenericocomprobtipo<>6)) THEN ecfechaimpxcierre -- no es una asiento manual

         END as fechaimputacion

  FROM contabilidad_ejerciciocontable
  WHERE (ecfechadesde <= rparam.agfechacontable  -- se imputa en el ejercicio que corresponde
            and ecfechahasta >= rparam.agfechacontable
            and nullvalue(eccerrado)
        )
        OR (ecfechadesde >rparam.agfechacontable -- en el que encuentra abierto
		       and nullvalue(eccerrado)
		)

     order by ecfechadesde asc
     limit 1;
     IF FOUND THEN
        resp =  concat('{fechaimputacion=',rejercicio.fechaimputacion,',idejerciciocontable=',rejercicio.idejerciciocontable,'}');
     ELSE  -- Si estamos en sede central y no hay un ejercicio para la fecha actual creo un nuevo ejercicio
           IF (centro()=1) THEN
                      SELECT INTO rejercicio *
                             ,CASE WHEN ( now() >= ecfechadesde) THEN  now()
                             WHEN ( now() < ecfechadesde) THEN ecfechadesde
                             END as fechaimputacion

                     FROM contabilidad_ejerciciocontable
                     WHERE ecfechadesde <= rparam.agfechacontable AND ecfechahasta >= rparam.agfechacontable;
                     IF not FOUND THEN

                           /*    --- Creo el nuevo periodo AUTOMATICAMENTE por el momento se va a enviar un valor NULL como respuesta
                               SELECT INTO rfechas to_char(concat(extract(year from rparam.agfechacontable ),'-01','-01')::date, 'YYYY-MM-DD' )  as fechainicio
                                      ,  to_char(concat(extract(year from rparam.agfechacontable ),'-12','-31')::date, 'YYYY-MM-DD' )  as fechafin;

                               INSERT INTO  contabilidad_ejerciciocontable (ecfechadesde,ecfechahasta)
                                      VALUES(rfechas.fechainicio::date,rfechas.fechafin::date );
                                      
                               elidejercicio = currval('public.contabilidad_ejerciciocontable_idejerciciocontable_seq');
                               resp =  concat('{fechaimputacion=',rfechas.fechainicio::date,',idejerciciocontable=',elidejercicio,'}');
                           */
                     END IF;
          END IF;
     END IF;
return resp;
END;
$function$
