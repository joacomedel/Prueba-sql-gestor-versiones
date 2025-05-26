CREATE OR REPLACE FUNCTION public.lala(_observacion text)
 RETURNS TABLE(nrocomprobante integer, minuta text, elresto text)
 LANGUAGE plpgsql
AS $function$
DECLARE
   --_sensors text := 'col1::text, col2::text';  -- cast each col to text
   --_type    text := 'foo';
      relem record;
      vencontre boolean;
BEGIN
	vencontre = false;
 	FOR relem  IN (SELECT 1  ) LOOP
		IF _observacion ILIKE '%Factura%' THEN
		--Pago de Factura Electronica A 0010-00000924 - RECARGA ZEPELIN BOTIQUIN COPAHUE - CABAÑAS - TEMPORADA 2017-2018
			vencontre = true;
			nrocomprobante := 456;
			minuta :=(regexp_split_to_array(_observacion, E'\\s+'))[6];
			elresto := '';
		RETURN NEXT ;
		END IF;
		IF _observacion ILIKE '%Reintegro%' THEN
		--MP: 107853|1 Pago Reintegro 32904-2017-3 del afiliado AZCONA, JUAN PEDRO Doc:18007439 con la OTP 4|OT|1|1783. Emitada el 2018-01-09 - Minuta: 107853|1
			vencontre = true;
			nrocomprobante := 123;
			minuta :=(regexp_split_to_array(_observacion, E'\\s+'))[1];
			elresto := regexp_split_to_array(_observacion, E'\\s+')::text;
		RETURN NEXT ;
		END IF;
		IF not vencontre THEN
			nrocomprobante := 0;
			minuta :='Ni idea';
			elresto := _observacion;
			RETURN NEXT ;
		END IF;
	END LOOP;
 -- // Pago de Factura Electronica A 0010-00000924 - RECARGA ZEPELIN BOTIQUIN COPAHUE - CABAÑAS - TEMPORADA 2017-2018
	


END;
$function$
