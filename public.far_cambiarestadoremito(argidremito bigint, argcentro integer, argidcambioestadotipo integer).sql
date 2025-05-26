CREATE OR REPLACE FUNCTION public.far_cambiarestadoremito(argidremito bigint, argcentro integer, argidcambioestadotipo integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare

begin
update far_remitoestado set remitofechafin=null where nullvalue(remitofechafin);
insert into far_remitoestado(centrocambioestado,idremito,centro, idremitoestadotipo, 
remitofechaini, remitofechafin) values(centro(),argidremito,argcentro,argidcambioestadotipo,now(),null);
end;
$function$
