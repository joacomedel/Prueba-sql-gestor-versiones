CREATE OR REPLACE FUNCTION ca.cantidaddiassegunlicencia(date, date, integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/*
* La funcion devuelve la cantidad de dias entre ($1,$2) dependiendo si la licencia
* esta configurada como dias corridos o laborables
*/

DECLARE
cantdias integer;
unalic record;
elidpersona integer;
BEGIN

     elidpersona=$4;
     cantdias = 1; -- por defecto retorna 1 dia (coinciden con las licencias que son por horas)
     SELECT into unalic * FROM ca.licenciatipo WHERE idlicenciatipo=$3 ; --AND ltpordia;
     IF FOUND THEN
        IF unalic.idlicenciatipo=28  THEN
             cantdias =1; -- en este caso particular no corresponde a cantidad de dias (es una lic de 3 horas)
        ELSE
            IF (unalic.ltdiascorridos)  THEN
            /*   cantdias= (extract(DAY FROM age($2,$1 ))
               +(extract(YEAR FROM age($2,$1 ))*360)
               +(extract(MONTH FROM age($2,$1 ))*30)) +1;	*/
               cantdias=  ($2 -  $1)+1;
               ELSE
                 --  cantdias = ca.cantidaddiaslaborables($1,$2);
                  cantdias = ca.cantdiaslaborablesemp($1,$2,$4);
               END IF;
        END IF;
     END IF;

return 	cantdias;
END;
$function$
