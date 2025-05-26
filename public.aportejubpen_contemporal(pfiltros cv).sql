CREATE OR REPLACE FUNCTION public.aportejubpen_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    arr varchar[];
    array_len integer;
    rfiltros record;
        vquery varchar;
    
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_aportejubpen_contemporal
AS (



select 
apellido,nombres,
nrodoc,
nroafiliado,
fechafinos,
telefono,
email,    
round(t.acimportebruto::numeric,2) as acimportebruto
,round(importe::numeric,2)as importe,
mes,ano    ,
t.idrecibo,
fechaingreso,
nomapeafiliado,
acfechainicio as ultimaactualizacion,
round(acporcentaje::numeric,2) as acporcentaje, 
round(acimporteaporte::numeric,2) as acimporteaporte,nrofactura,nrosucursal,
tipofactura,tipocomprobante,facturaventa.fechaemision as fechafactura
, '1-Apellido#apellido@2-Nombres#nombres@3-NroAfiliado#nroafiliado@4-FechaFinOS#fechafinos@5-Telefono#telefono@6-Email#email@7-ImporteBruto#acimportebruto@8-Importe#importe@9-Mes#mes@10-Ano#ano@11-Recibo#t.idrecibo@12-FechaIngreso#fechaingreso@13-NomApeAfiliado#nomapeafiliado@14-UltimaActualizacion#ultimaactualizacion@15-Porcentaje#acporcentaje@16-ImporteAporteB#acimporteaporte@17-NroFactura#nrofactura@18-NroSucursal#nrosucursal@19-TipoFactura#tipofactura@20-TipoComprobante#tipocomprobante@21-FacturaFechaEmision#fechafactura'::text as mapeocampocolumna 
    
 from

 informefacturacionaporte

natural join informefacturacion
natural join facturaventa
natural join informefacturacionestado
 join 
(
SELECT  acimportebruto,acporcentaje,idaporte,
acimporteaporte,apellido,nombres,
mes,ano,idcentroregionaluso,concat(persona.nrodoc ,' - ',persona.barra) as nroafiliado,importe,
telefono    ,
email,    
fechafinos,persona.barra,
  concat(persona.apellido ,', ',persona.nombres) as nomapeafiliado ,acfechainicio,aporte.idrecibo,fechaingreso,(select count(*) as cantbenf from benefsosunc where nrodoctitu=persona.nrodoc and (idestado=2 or idestado=3)) as t
                                   FROM aporte
                                      NATURAL JOIN (
                                       SELECT   aporte.ano,MAX(aporte.mes) as mes,nrodoc,tipodoc,idlaboral
                                       FROM aporte
                                       JOIN afiljub ON aporte.idcertpers = afiljub.idcertpers
                                       NATURAL JOIN persona
                                       WHERE barra = 35 AND ano >= EXTRACT(YEAR FROM CURRENT_date-60)
                                       group BY aporte.ano,nrodoc,tipodoc,idlaboral

 UNION

SELECT   aporte.ano,MAX(aporte.mes) as mes,nrodoc,tipodoc,idlaboral
                                       FROM aporte
                                       JOIN afilpen ON aporte.idcertpers = afilpen.idcert
                                       NATURAL JOIN persona
                                       WHERE barra = 36 AND ano  >=   EXTRACT(YEAR FROM CURRENT_date-60)
                                       group BY aporte.ano,nrodoc,tipodoc,idlaboral


                                       ) as datosaporte
NATURAL JOIN persona
 join aporteconfiguracion on(persona.nrodoc=aporteconfiguracion.nrodoc and
 persona.tipodoc=aporteconfiguracion.tipodoc and nullvalue(acfechafin))


where  
nullvalue(acfechafin) and
( '0'='0' or persona.nrodoc ='0' )
and ( ( '35'='0' or persona.barra ='35'  )
or  ( '36'='0' or persona.barra ='36'  ))
and persona.fechafinos>=rfiltros.fechaemision
)as t
on (t.idaporte=informefacturacionaporte.idaporte and t.idcentroregionaluso=informefacturacionaporte.idcentroregionaluso)


where nullvalue(fechafin)
and nullvalue(anulada)
order by apellido,nombres

);
     

return true;
END;
$function$
