CREATE OR REPLACE FUNCTION public.rectificarfacturas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
facoriginal cursor for select * from facturaventa where fechaemision <='2008-06-30' and fechaemision > '2008-06-19' and tipofactura='FA';
anulacion timestamp;
facorig record;
aux boolean;
datos record;

--itemfacoriginal cursor for select * from itemfacturaventa;
--facturaordenoriginal cursor for select * from facturaorden;
--facturaaporteoriginal cursor for select * from facturaaporte;

begin
--delete from facturaventanuevo;
--delete from itemfacturaventanuevo;
--delete from facturaordennuevo;
--delete from facturaaportenuevo;
--delete from facturaserror;
open facoriginal;
fetch facoriginal into facorig;
while FOUND loop
	anulacion = null;
    select into datos * from controlfacturas where nrosiges=facorig.nrofactura;
	if not FOUND then
		insert into facturaserror(nrofactura,motivo) values(facorig.nrofactura,'No aparece en una factura real. Quizas haya que eliminarla');
	else
		if datos.anulada then
			anulacion = facorig.fechaemision;
		end if;
		insert into facturaventanuevo(tipocomprobante, nrosucursal, nrofactura,nrodoc, tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago,tipofactura,anulada) values(facorig.tipocomprobante, facorig.nrosucursal, datos.nrofactura, facorig.nrodoc, facorig.tipodoc,facorig.ctacontable,facorig.centro,facorig.importeamuc,facorig.importeefectivo,facorig.importedebito,facorig.importecredito,facorig.importectacte,facorig.importesosunc,facorig.fechaemision,facorig.formapago,facorig.tipofactura,anulacion);
		if abs((facorig.importeefectivo+facorig.importecredito+facorig.importedebito+facorig.importectacte) - datos.importe) > 1 then
			insert into facturaserror(nrofactura, motivo) values(facorig.nrofactura,'importe diferentes');
		end if;
		insert into itemfacturaventanuevo(nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura)
			select nrosucursal,datos.nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura from itemfacturaventa where nrofactura = facorig.nrofactura and tipofactura=facorig.tipofactura;
		insert into facturaordennuevo(nrosucursal,nrofactura,nroorden,centro,tipocomprobante,tipofactura)
			select nrosucursal,datos.nrofactura,nroorden,centro,tipocomprobante,tipofactura from facturaorden where nrofactura=facorig.nrofactura and tipofactura=facorig.tipofactura;
		insert into facturaaportenuevo(nrosucursal,nrofactura,mes,anio,nrodoc,tipodoc,tipocomprobante,tipofactura)
			select nrosucursal,datos.nrofactura,mes,anio,nrodoc,tipodoc,tipocomprobante,tipofactura from facturaaporte where nrofactura=facorig.nrofactura and tipofactura=facorig.tipofactura;
	end if;
fetch facoriginal into facorig;
end loop;


--inserto las facturas que no figuraban en el sistema
--FALTA LA FECHA DE EMISION. REPORTO ESTOS CASOS EN LA TABLA facturaserror;
insert into facturaserror(nrofactura,motivo)
	select nrofactura,'NO ESTABA REGISTRADA EN EL SISTEMA. FALTA FECHA DE EMISION' from controlfacturas where nrosiges is null and nrofactura > 295;
insert into facturaventanuevo(tipocomprobante, nrosucursal, nrofactura,nrodoc, tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago,tipofactura,anulada)
	select 1,1,nrofactura,null, null, null, 1,null,importe,0,0,0,0,null,2,'FA', (case when anulada=true then current_date else null end) as an from controlfacturas where nrosiges is null and nrofactura > 295;
	--select into aux * from numerosfacturasfaltantes();
return true;
end;
$function$
