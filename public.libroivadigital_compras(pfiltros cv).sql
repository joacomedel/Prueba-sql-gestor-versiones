CREATE OR REPLACE FUNCTION public.libroivadigital_compras(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
 
CREATE TEMP  TABLE temp_libroivadigital_compras
AS (
SELECT TO_CHAR( rf.fechaemision :: DATE, 'yyyymmdd')::numeric fechacomprobante,tccodigo,
lpad(rf.puntodeventa,5,'0') puntodeventa,
lpad(rf.numero,20,'0') numero,
lpad('',16,' ') despachoimportacion,
80 codigovendedor,
lpad(replace(p.pcuit,'-',''),20,'0') idvendedor,
rpad(BTRIM(p.pdescripcion),30,' ') pdescripcion,
to_char(monto ,'0000000000000V99')  importetotal,   
to_char(( case when nullvalue(rf.nogravado) then 0 when rf.nogravado<0 then rf.nogravado*(-1) else rf.nogravado end ), '0000000000000V99') impnogravado, 
to_char(( case when nullvalue(rf.exento) then 0 else replace(rf.exento,'-','')::numeric end ), '0000000000000V99')  impexento,
to_char(  (case when nullvalue(rf.retiva) then 0 else rf.retiva end), '0000000000000V99') percepcionesiva,
to_char(  (case when nullvalue(rf.percepciones) then 0 else rf.percepciones end), '0000000000000V99') percepcionesotras,
to_char( case when nullvalue(rf.retiibb) then 0 else rf.retiibb end , '0000000000000V99')  retiibb,
lpad(0,15,'0') percepcionesimpmunicipales,
lpad(0,15,'0') impuestosinternos,
'PES' as codigomoneda,
'0001000000' tipocambio,
case when rf.iva21<>0 then 1 else 0 end + case when  rf.iva105<>0 then 1 else 0 end + case when rf.iva27<>0 then 1 else 0 end cantalicuotas,
lpad(' ',1,' ') codoperacion, --NO CORRESPONDE Segun tabla . Código de Operación del afip ivarecargo21
to_char((rf.iva21+ rlfivarecargo21 -rlfivadescuento21  )  
+ 
(rf.iva105+ rlfivarecargo105 - rflivadescuento105 )   
+ 
(rf.iva27+ rlfivarecargo27 - rlfivadescuento27)
  ,'0000000000000V99')   credfiscalcomp,
lpad(0,15,'0') otrostributos, 
30590509643 as cuitemision,
lpad('SOSUNC',30,' ') denominacion,
lpad(0,15,'0') ivacomision
 
--,rf.tipofactura,rf.letra 


FROM  reclibrofact AS rf JOIN prestador p on (rf.idprestador=p.idprestador) JOIN tipocomprobantecodigo tcc ON (rf.idtipocomprobante= tcc.idtipocomprobante AND rf.letra = tcc.tccletra ) 
JOIN condicioniva t on (p.idcondicioniva=t.idcondicioniva)
JOIN contabilidad_periodofiscalreclibrofact using (idrecepcion,idcentroregional)
natural join contabilidad_periodofiscal cpf 
--WHERE  idperiodofiscal = 924
 
WHERE  idperiodofiscal = rfiltros.idperiodofiscal
 
ORDER BY puntodeventa,numero, idvendedor
);

return '';
END;
$function$
