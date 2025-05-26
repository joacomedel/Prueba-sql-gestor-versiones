CREATE OR REPLACE FUNCTION public.registrarcambioamuc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$declare
 ultimo  record;
begin
   select into ultimo * from histoamuc where nrodoc = NEW.nrodoc and tipodoc = NEW.tipodoc and nullvalue(fechafin);
   if FOUND then
        update histoamuc set fechafin=CURRENT_TIMESTAMP where nrodoc= NEW.nrodoc and tipodoc = NEW.tipodoc and nullvalue(fechafin);
   end if;
   insert into histoamuc(nrodoc, tipodoc, mutu,fechaini, fechafin) values(NEW.nrodoc, NEW.tipodoc,NEW.mutu, CURRENT_TIMESTAMP, NULL);

   IF NEW.legajosiu = 0 THEN

       INSERT INTO afilimodificacamposraros(amcrlegajoanterior,amcrlegajoactual,amcrtabla) VALUES(OLD.legajosiu,NEW.legajosiu,TG_TABLE_NAME::regclass::text);

   END IF; 
   return NEW;
end;
$function$
