CREATE OR REPLACE FUNCTION public.minimadetresfechas(date, date, date)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
/*Compara las tres fecha que se manda por parametro y devuelve la menor de las tres.
Si alguna de las fechas es nula entonces se descarta para el analisis*/
DECLARE
fechauno alias for $1;
fechados alias for $2;
fechatres alias for $3;
fechamenor DATE;
BEGIN
IF not nullvalue(fechauno) THEN
   fechamenor = fechauno;
ELSE
    IF  not nullvalue(fechados) THEN
       fechamenor = fechados;
    ELSE
        fechamenor = fechatres;
    END IF;
END IF;
IF  not nullvalue(fechamenor)
   AND  not nullvalue(fechados)
   AND fechados < fechamenor THEN
   fechamenor = fechados;
END IF;
IF  not nullvalue(fechamenor)
   AND  not nullvalue(fechatres)
   AND fechatres < fechamenor THEN
   fechamenor = fechatres;
END IF;
RETURN fechamenor;
END;
$function$
