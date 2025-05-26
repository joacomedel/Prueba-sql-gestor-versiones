CREATE OR REPLACE FUNCTION ca.dar_empleadocentrocosto(integer, integer, date)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$	DECLARE
		respuesta record;
		info_centro_costo varchar;
                fechadesde date;
               
	BEGIN
	      SET search_path = ca, pg_catalog;
	     
              info_centro_costo = null;	
              -- Obtengo el primer dia del mes en el que fue dado de alta
              --SELECT INTO fechadesde  concat(EXTRACT('year' FROM  $3),'-',EXTRACT('MONTH' FROM $3),'-',1)::date;
	   SELECT INTO fechadesde  to_timestamp(concat(EXTRACT('year' FROM  $3),'-',EXTRACT('MONTH' FROM $3),'-1') ,'YYYY-MM-DD')::date;
	     SELECT INTO respuesta idcentrocosto ,eccporcentual  
	     FROM empleadocentrocosto 
	     WHERE idpersona = $1 and idcentrocosto = $2
                   and fechadesde <= $3
                   and (eccfechafin >= $3 or nullvalue(eccfechafin));
             IF FOUND THEN 
			info_centro_costo= concat (respuesta.idcentrocosto,'|', respuesta.eccporcentual) ;
                --- ELSE RAISE EXCEPTION 'R-001, No se encontro un centro de costo configurado para idpersona= %',$1; 
		                
	     END IF;
        return info_centro_costo;
END;
$function$
