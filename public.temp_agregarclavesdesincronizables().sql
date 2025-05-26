CREATE OR REPLACE FUNCTION public.temp_agregarclavesdesincronizables()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
aux record;
begin

ALTER TABLE "public"."aporte"
  DROP CONSTRAINT "aporte_pkey" RESTRICT;

ALTER TABLE "public"."aportejubpen"
  DROP CONSTRAINT "aportejubpen_fk1" RESTRICT;

 ALTER TABLE "public"."aportelicsinhab"
  DROP CONSTRAINT "aportelicsinhab_fk1" RESTRICT;

ALTER TABLE "public"."aporterecibo"
  DROP CONSTRAINT "aporterecibo_fk1" RESTRICT;

ALTER TABLE "public"."aportessinfacturas"
  DROP CONSTRAINT "aportessinfacturas_fk1" RESTRICT;

ALTER TABLE "public"."facturaaporte"
  DROP CONSTRAINT "facturaaporte_fk" RESTRICT;

ALTER TABLE "public"."importesaporte"
  DROP CONSTRAINT "importesaporte_fk" RESTRICT;

DROP INDEX "public"."aporte_idaporte_idcentroregionaluso_key";

ALTER TABLE "public"."aporte"
  ADD CONSTRAINT "aporte_idaporte_idcentroregionaluso_key"
  PRIMARY KEY ("idaporte", "idcentroregionaluso");

ALTER TABLE "public"."aporte"
  ALTER COLUMN "idcentroregionaluso" SET NOT NULL;

ALTER TABLE "public"."aportejubpen"
  ADD CONSTRAINT "aportejubpen_fk1" FOREIGN KEY ("idaporte", "idcentroregionaluso")
    REFERENCES "public"."aporte"("idaporte", "idcentroregionaluso")
    ON DELETE RESTRICT
    ON UPDATE CASCADE
    NOT DEFERRABLE;


ALTER TABLE "public"."aportelicsinhab"
  ADD CONSTRAINT "aportelicsinhab_fk1" FOREIGN KEY ("idaporte", "idcentroregionaluso")
    REFERENCES "public"."aporte"("idaporte", "idcentroregionaluso")
    ON DELETE RESTRICT
    ON UPDATE CASCADE
    NOT DEFERRABLE;

ALTER TABLE "public"."aporterecibo"
  ADD CONSTRAINT "aporterecibo_fk1" FOREIGN KEY ("idaporte", "idcentroregionaluso")
    REFERENCES "public"."aporte"("idaporte", "idcentroregionaluso")
    ON DELETE RESTRICT
    ON UPDATE CASCADE
    NOT DEFERRABLE;

ALTER TABLE "public"."aportessinfacturas"
  ADD CONSTRAINT "aportessinfacturas_fk" FOREIGN KEY ("idaporte", "idcentroregionaluso")
    REFERENCES "public"."aporte"("idaporte", "idcentroregionaluso")
    ON DELETE RESTRICT
    ON UPDATE CASCADE
    NOT DEFERRABLE;

ALTER TABLE "public"."facturaaporte"
  ADD CONSTRAINT "facturaaporte_fk" FOREIGN KEY ("idaporte", "idcentroregionaluso")
    REFERENCES "public"."aporte"("idaporte", "idcentroregionaluso")
    ON DELETE RESTRICT
    ON UPDATE CASCADE
    NOT DEFERRABLE;


ALTER TABLE "public"."importesaporte"
  ADD CONSTRAINT "importesaporte_fk" FOREIGN KEY ("idaporte", "idcentroregionaluso")
    REFERENCES "public"."aporte"("idaporte", "idcentroregionaluso")
    ON DELETE RESTRICT
    ON UPDATE CASCADE
    NOT DEFERRABLE;

--select into aux eliminartablasincronizable('aporte');
--select into aux agregarsincronizable('aporte');
--select into aux eliminartablasincronizable('restados');
--select into aux agregarsincronizable('restados');

UPDATE aporte SET idcentroregionaluso = tt.centro
FROM (select t.centro,fa.idaporte from facturaaporte fa
JOIN  talonario t ON fa.nrosucursal = t.nrosucursal
and t.tipocomprobante = 1
WHERE fa.nrosucursal > 1 ) tt
WHERE tt.idaporte = aporte.idaporte;

end;
$function$
