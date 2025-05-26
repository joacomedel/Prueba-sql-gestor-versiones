CREATE OR REPLACE FUNCTION public.sys_abrirliquidaciontarjeta(pidliquidacion bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
  id bigint;
  cen integer;
  xnroordenpago varchar;   

begin

id=pidliquidacion/100;
cen=pidliquidacion%100;

-- CS 2019-04-09
-- Cambio en la forma de gestionar Apertura y Cierre de las Liq de Tarjeta

select into xnroordenpago idcomprobantemultivac from mapeoliquidaciontarjeta
where idliquidaciontarjeta=id and idcentroliquidaciontarjeta=cen;

--perform cambiarestadoordenpago((xnroordenpago::bigint)/100,((xnroordenpago::bigint)%100)::integer,1,'Al Abrir la Liquidacion Tarjeta ');
--insert into liquidaciontarjetaestado(idliquidaciontarjeta,idcentroliquidaciontarjeta,idtipoestadoliquidaciontarjeta)
--		values(id,cen,0); --Vuelve a Estado Registrada

delete from liquidaciontarjetaestado where idliquidaciontarjeta=id and idcentroliquidaciontarjeta=cen;
-- -----------------------------------------------------------------------

-- CS 2019-04-09
-- Cambio en la forma de gestionar Apertura y Cierre de las Liq de Tarjeta
-- Queda deshabilitada esta parte

delete from mapeoliquidaciontarjeta
where idliquidaciontarjeta=id and idcentroliquidaciontarjeta=cen;

update mapeocompcompras set tipomov='I',update=true,idcomprobantemultivac=null
where idrecepcion in
(select idrecepcion from reclibrofact r
join liquidaciontarjetacomprobantegasto g on (r.numeroregistro=g.nroregistro) 
where idliquidaciontarjeta=id and idcentroliquidaciontarjeta=cen);

delete from festados
where tipoestadofactura=7 and concat(nroregistro::text,anio::text) in
(select concat(g.nroregistro::text,g.anio::text) from reclibrofact r
join liquidaciontarjetacomprobantegasto g on (r.numeroregistro=g.nroregistro) 
where idliquidaciontarjeta=id and idcentroliquidaciontarjeta=cen);

update festados set fefechafin=null
where tipoestadofactura=2 and concat(nroregistro::text,anio::text) in
(select concat(g.nroregistro::text,g.anio::text) from reclibrofact r
join liquidaciontarjetacomprobantegasto g on (r.numeroregistro=g.nroregistro) 
where idliquidaciontarjeta=id and idcentroliquidaciontarjeta=cen);


return true;
end;
$function$
