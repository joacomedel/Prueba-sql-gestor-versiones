CREATE OR REPLACE FUNCTION public.calcularedades()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

	contador integer;

BEGIN
contador = 0;
    WHILE  contador <= 1160 LOOP
    INSERT INTO cantidadedad (suma,rango)
    (
    SELECT sum(cantidad) as suma,concat( 'De ' , to_char(contador,'9999') , ' a ' , to_char(contador+5,'9999'))
    FROM (
         SELECT count(*) as cantidad,date_part('year', age(fechanac)) as edad
         FROM persona
         WHERE date_part('year', age(fechanac)) >=  0 and barra < 100
         group BY date_part('year', age(fechanac))
         HAVING date_part('year', age(fechanac)) >= contador AND
         date_part('year', age(fechanac)) <  contador + 5
    ) as t
    );
    contador = contador + 5;
    END LOOP;
    
return 'true';
END;
$function$
