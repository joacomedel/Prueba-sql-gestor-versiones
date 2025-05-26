CREATE OR REPLACE FUNCTION public.maximadetresfechas(date, date, date)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
/*Compara las tres fecha que se manda por parametro y devuelve la mayor de las tres.
Si alguna de las fechas es nula entonces se descarta para el analisis*/
DECLARE
fechauno alias for $1;
fechados alias for $2;
fechatres alias for $3;
fechamayor DATE;
BEGIN
IF not nullvalue(fechauno) THEN
   fechamayor = fechauno;
ELSE
    IF  not nullvalue(fechados) THEN
       fechamayor = fechados;
    ELSE
        fechamayor = fechatres;
    END IF;
END IF;
IF  not nullvalue(fechamayor)
   AND  not nullvalue(fechados)
   AND fechados > fechamayor THEN
   fechamayor = fechados;
END IF;
IF  not nullvalue(fechamayor)
   AND  not nullvalue(fechatres)
   AND fechatres > fechamayor THEN
   fechamayor = fechatres;
END IF;
RETURN fechamayor;
END;
$function$
