CREATE OR REPLACE FUNCTION public.borrarbarrabenefyactualizarbarrapersona(integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	tipodocumento alias for $1;
	nrodocumento alias for $2;
	resultado boolean;
	benef RECORD;
	barranueva integer;
BEGIN
resultado = 'true';
SELECT INTO benef * FROM persona WHERE tipodoc = tipodocumento AND nrodoc = nrodocumento;

SELECT INTO benef * FROM barras WHERE tipodoc = tipodocumento AND nrodoc = nrodocumento;
if FOUND then
--MaLaPi 10-01-2012 Esta borrado antes estaba afuera, pero lo coloca adentro para que solo se elimine la barra si se va a generar una nueva.
DELETE FROM barras WHERE tipodoc = tipodocumento AND nrodoc = nrodocumento AND barra = benef.barra;

		SELECT INTO barranueva * FROM darbarramayorprioridad(tipodocumento,nrodocumento);
		UPDATE persona SET barra = barranueva WHERE tipodoc = tipodocumento AND nrodoc = nrodocumento;
	--no hay nada que hacer debe quedar con la barra de beneficiario.
end if;

return resultado;
END;
$function$
