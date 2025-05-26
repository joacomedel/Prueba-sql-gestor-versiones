CREATE OR REPLACE FUNCTION public.asientogenerico_daridasientogenerico(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE

	rfiltros RECORD;
  	rasiento RECORD;
  	salida character varying;
BEGIN
   salida = '';
    
   SELECT INTO rasiento text_concatenar(concat(' ( ',idasientogenerico,'|',idcentroasientogenerico,' ) ')) as losasientos
   FROM asientogenerico
 --  NATURAL JOIN asientogenericoestado
   WHERE idcomprobantesiges ilike $1
      ---AND nullvalue(idasientogenericorevertido)
   --   AND nullvalue(agefechafin)
      AND agfechacontable >='2019-01-01'
   GROUP BY idcomprobantesiges;

   IF FOUND THEN
      salida = rasiento.losasientos;
   END IF;
   

   RETURN salida;
END;
$function$
