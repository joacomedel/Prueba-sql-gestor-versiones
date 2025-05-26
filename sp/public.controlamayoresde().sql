CREATE OR REPLACE FUNCTION public.controlamayoresde()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  
rec RECORD;
fechanueva varchar;
fechaFinAÃ±o varchar; 
dia varchar;
mes varchar;
anio varchar;

BEGIN
	fechaFinAÃ±o = concat(EXTRACT(year FROM current_timestamp) , '-12-31');
	
   FOR rec IN SELECT * FROM public.barras INNER JOIN public.benefsosunc ON (public.barras.nrodoc = public.benefsosunc.nrodoctitu ) 
			INNER JOIN persona ON (benefsosunc.nrodoc = persona.nrodoc) 
			WHERE barras.barra=31 or barras.barra=32 and 18 > age(to_timestamp(fechaFinAÃ±o,'YYYY-MM-DD'),current_timestamp) LOOP
	dia =EXTRACT(day FROM to_timestamp(rec.fechanac,'YYYY-MM-DD'));
	mes=EXTRACT(month FROM to_timestamp(rec.fechanac,'YYYY-MM-DD'));
	anio=EXTRACT(year FROM current_timestamp);
	fechanueva= concat(anio , '-' , mes , '-' , dia);
	update persona set fechafinos=to_date(fechanueva,'YYYY-MM-DD') where persona.nrodoc = rec.nrodoc;

   END LOOP ;
	
   RETURN 'true';
END;
$function$
