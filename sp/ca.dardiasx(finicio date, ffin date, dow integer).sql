CREATE OR REPLACE FUNCTION ca.dardiasx(finicio date, ffin date, dow integer)
 RETURNS SETOF date
 LANGUAGE plpgsql
AS $function$
DECLARE
      dia date;
      fin date;
BEGIN
      IF finicio < ffin THEN
            dia := finicio;
            fin := ffin;
      ELSE
            dia := ffin;
            fin := finicio;
      END IF;
      WHILE dia <= fin LOOP
            IF EXTRACT('dow' FROM dia) = dow THEN
                  RETURN NEXT dia;
            END IF;
            dia := dia + 1;
      END LOOP;
END;
$function$
