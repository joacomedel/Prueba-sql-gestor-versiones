CREATE OR REPLACE FUNCTION public.expediente_crear(integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rfiltros RECORD;
    rexpediente RECORD;
    elnumeroexp integer;
    eliddocumento  integer;
    elidcentrodocumento  integer;

BEGIN
     eliddocumento = $1;
     elidcentrodocumento = $2;
     --- SELECT INTO rexpediente * FROM tempexpediente ; -- Si necesito mas informacion llenar la temporal
     SELECT INTO elnumeroexp  getnroexpediente();
     INSERT INTO expediente(iddocumento,idcentrodocumento,enumero,eanio)
     VALUES(eliddocumento,elidcentrodocumento,elnumeroexp,extract(year from now()));

return elnumeroexp;
END;
$function$
