CREATE OR REPLACE FUNCTION public.listado_total_adherentes_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        
	rfiltros record;
        
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_listado_total_adherentes_contemporal
	AS (
		SELECT   
                 concat(calle, ' NRO: ',nro,' tira: ',tira,' piso: ',piso,' dpto: ',dpto) as direccion,
                provincia.descrip as provincia,localidad.descrip as localidad,
                 idaporteconfiguracion, idcentroaporteconfiguracion,    nrodoc  ,       p.apellido,     nombres, barra,

                fechanac,       sexo,   estcivil,concat(carct,'-',telefono) as telefono,        email,  fechainios,     fechafinos,contcarencia

                ,acfechainicio aporte_configuracion_inicio,acfechafin aporte_configuracion_fin, acimporteaporte  aporte_configuracion_importeaporte 
                   ,acporcentaje  aporte_configuracion_acporcentaje,    acimportebruto::        double precision, aporteconfiguracioncc aporte_configuracion_ingreso,             
                   iddireccion,    carct,   idcentrodireccion       ,nrodocreal,    personacc,      idaporteconfiguracionimportes   
                   ,idcentroaporteconfiguracionimportes,   concat(usuario.apellido,' ', usuario.nombre) as usuario_mod,    aciimportesiniva        ,aciimporteiva
                   ,'1-direccion#direccion@2-provincia#provincia@3-localidad#localidad@4-idaporteconfiguracion#idaporteconfiguracion@5-idcentroaporteconfiguracion#idcentroaporteconfiguracion@6-nrodoc#nrodoc@7-apellido#apellido@8-nombres#nombres@9-barra#barra@10-fechanac#fechanac@11-sexo#sexo@12-estcivil#estcivil@13-telefono#telefono@14-email#email@15-fechainios#fechainios@16-fechafinos#fechafinos@17-contcarencia#contcarencia@18-aporte_configuracion_inicio#aporte_configuracion_inicio@19-aporte_configuracion_fin#aporte_configuracion_fin@20-aporte_configuracion_importeaporte#aporte_configuracion_importeaporte@21-aporte_configuracion_acporcentaje#aporte_configuracion_acporcentaje@22-acimportebruto#acimportebruto@23-aporte_configuracion_ingreso#aporte_configuracion_ingreso@24-iddireccion#iddireccion@25-carct#carct@26-idcentrodireccion#idcentrodireccion@27-nrodocreal#nrodocreal@28-personacc#personacc@29-idaporteconfiguracionimportes#idaporteconfiguracionimportes@30-idcentroaporteconfiguracionimportes#idcentroaporteconfiguracionimportes@31-usuario_mod#usuario_mod@32-aciimportesiniva#aciimportesiniva@33-aciimporteiva#aciimporteiva@34-porc_iva#porc_iva@35-aciobservacion#aciobservacion@36-aciporcentaje#aciporcentaje@37-aciimportebruto#aciimportebruto@38-acifechainicio#acifechainicio@39-acifechafin#acifechafin@40-nrodoc_conyuge#nrodoc_conyuge@41-cant_conyug#cant_conyug@42-cant_benef#cant_benef'::text as mapeocampocolumna                --,     aciimportetotal 
                , ti.porcentaje as porc_iva             ,aciobservacion
                ,       aciporcentaje   ,aciimportebruto        ,acifechainicio,        acifechafin                     ,nrodoc_conyuge ,cant_conyug,   cant_benef

                FROM aporteconfiguracion ac
                NATURAL JOIN  persona p
                NATURAL JOIN direccion
                LEFT JOIN provincia USING(idprovincia)
                LEFT JOIN localidad USING(idlocalidad)

                NATURAL JOIN  aporteconfiguracionimportes 
                LEFT JOIN ( SELECT nrodoctitu, tipodoctitu, text_concatenar(concat(conyug.nrodoc,'  ')) as  nrodoc_conyuge ,  count(*)   as cant_conyug
                              FROM benefsosunc 
                              JOIN persona as conyug USING (nrodoc,tipodoc)
                              JOIN persona as titu ON ( nrodoctitu = titu.nrodoc AND tipodoctitu = titu.tipodoc )       
                              WHERE conyug.barra = 1 
                                   
                                   AND conyug.fechafinos = titu.fechafinos
                                   GROUP BY  nrodoctitu, tipodoctitu --- por si hay algun 35 con mas de un conyuge
                ) AS el_conyuge ON (nrodoctitu=nrodoc AND tipodoctitu = tipodoc)                
                LEFT JOIN ( SELECT nrodoctitu, tipodoctitu, count(*)   as cant_benef
                            FROM benefsosunc 
                            JOIN persona as hijo USING (nrodoc,tipodoc)
                            JOIN persona as titu ON ( nrodoctitu = titu.nrodoc AND tipodoctitu = titu.tipodoc ) 
                            WHERE hijo.barra <> 1 
                                AND hijo.fechafinos = titu.fechafinos
                           GROUP BY  nrodoctitu, tipodoctitu --- 
                ) AS los_benef ON (los_benef.nrodoctitu=nrodoc AND los_benef.tipodoctitu = tipodoc) 
                LEFT JOIN usuario USING(idusuario)      
                 LEFT JOIN tipoiva as ti USING (idiva)
                WHERE nullvalue(acfechafin)  and fechafinos >=current_date - 180::integer
                AND CASE WHEN nullvalue(rfiltros.nrodoc) THEN TRUE ELSE nrodoc=rfiltros.nrodoc END
                      
                ORDER BY apellido,nombres,nrodoc,barra
		
	);
  

return true;
END;
$function$
