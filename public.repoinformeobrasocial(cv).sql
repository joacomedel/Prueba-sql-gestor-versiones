CREATE OR REPLACE FUNCTION public.repoinformeobrasocial(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/**/
DECLARE

    rparam RECORD;
    respuesta character varying;

    
   

BEGIN
    respuesta = '';
    EXECUTE sys_dar_filtros($1) INTO rparam;


 CREATE TEMP TABLE temp_repoinformeobrasocial AS (
    
           
SELECT DISTINCT informefacturacionreciprocidad.fechauso,prestador.pdescripcion,
concat(informefacturacionreciprocidad.nroorden, ' - ', informefacturacionreciprocidad.centro) as laorden,
informefacturacionreciprocidad.nroorden,
informefacturacionreciprocidad.centro,
CASE WHEN informefacturacionreciprocidad.idcomprobantetipos=4 THEN 'Consultas'
     WHEN informefacturacionreciprocidad.idcomprobantetipos=14 THEN 'Farmacia'
     WHEN informefacturacionreciprocidad.idcomprobantetipos=3 THEN 'Internación'
ELSE cuentascontables.desccuenta
END AS desccuenta,  

concat(t.apellido,', ',
t.nombres) as afiliado,  
 concat((t.nrodoc,'-',t.barraafil)) as nroafiliado,
t.nrodoc,
t.barraafil,
informefacturacionreciprocidad.importe, osreci.descrip,
case when nullvalue(factura.nroordenpago) then 'carga manual'
else factura.nroordenpago::varchar end as nroordenpago,
'1-NroOrden#nroorden@2-Centro#centro@3-Tipo#desccuenta@4-ApellidoyNombre#afiliado@5-Nrodoc#nrodoc@6-Barra#barraafil@7-Importe#importe@8-Reciprocidad#descrip@9-OrdenPago#nroordenpago'::text as mapeocampocolumna


FROM  informefacturacionreciprocidad
join orden
on(informefacturacionreciprocidad.nroorden=orden.nroorden and informefacturacionreciprocidad.centro=orden.centro )
left JOIN facturaordenesutilizadas
on(facturaordenesutilizadas.nroorden=orden.nroorden and facturaordenesutilizadas.centro=orden.centro
and facturaordenesutilizadas.tipo=informefacturacionreciprocidad.idcomprobantetipos)
left JOIN factura USING(nroregistro, anio)
LEFT JOIN
(SELECT nroorden, centro, desccuenta
FROM practica NATURAL JOIN cuentascontables NATURAL JOIN item NATURAL JOIN itemvalorizada) AS cuentascontables
on(cuentascontables.nroorden=orden.nroorden and cuentascontables.centro=orden.centro)
LEFT JOIN prestador
on( informefacturacionreciprocidad.idprestador=prestador.idprestador)

JOIN osreci USING(idosreci,barra) JOIN
(SELECT persona.nrodoc, persona.tipodoc,persona.apellido, persona.nombres,
CASE WHEN nullvalue(tbenef.barra)  THEN persona.barra
ELSE tbenef.barra
END AS barra,
persona.barra AS barraafil
FROM persona LEFT JOIN
(SELECT benefreci.nrodoc, benefreci.tipodoc, barra
FROM benefreci JOIN persona ON(benefreci.nrodoctitu=persona.nrodoc AND benefreci.tipodoctitu=persona.tipodoc)) as tbenef ON (persona.nrodoc=tbenef.nrodoc AND persona.tipodoc=tbenef.tipodoc)) as t USING(nrodoc,tipodoc)

WHERE informefacturacionreciprocidad.nroinforme= rparam.nroinforme and
informefacturacionreciprocidad.idcentroinformefacturacion=rparam.idcentroregional
ORDER BY afiliado

);



return respuesta;
END;
$function$
