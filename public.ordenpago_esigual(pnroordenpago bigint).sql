CREATE OR REPLACE FUNCTION public.ordenpago_esigual(pnroordenpago bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    unaordenpago RECORD;
    rta boolean;
    cant_imputacion_minuta integer;
    cant_imputacion integer;
    cant_imp_iguales integer;

BEGIN
     
     rta = false;

     select into cant_imp_iguales count(*)
     from (
          select * 
          from tempordenpago 
          join tempordenpagoimputacion using (idsiges)) x
          join (select * 
                from ordenpago 
                natural join ordenpagoimputacion 
               where nroordenpago=pnroordenpago/100 and idcentroordenpago=pnroordenpago%100
     ) y on (
          x.fechaingreso=y.fechaingreso 
          and x.importetotal=y.importetotal 
          and x.nrocuentac=y.nrocuentac 
          and x.debe=y.debe
          and x.haber=y.haber
     );

    

     if found then
                    SELECT INTO cant_imputacion count(*)
                    FROM  tempordenpagoimputacion;
      
                    SELECT INTO cant_imputacion_minuta  count(*)
                    from ordenpago 
                    natural join ordenpagoimputacion 
                    where nroordenpago=pnroordenpago/100 and idcentroordenpago=pnroordenpago%100;
 
                   IF (cant_imputacion_minuta =  cant_imputacion ) and (cant_imputacion = cant_imp_iguales)THEN
                           rta = true;
                   END IF;
     end if;

return rta;

END;
$function$
