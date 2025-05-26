CREATE OR REPLACE FUNCTION public.tesoreria_cuentasbancariasafiliados_contemporal(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       
  rfiltros record; 
  
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

EXECUTE sys_dar_filtros($1) INTO rfiltros;

  CREATE TEMP TABLE temp_tesoreria_cuentasbancariasafiliados_contemporal 
	AS (
       SELECT concat(apellido, ' ', nombres) elafiliado, concat(nrodoc, '-', barra) nroafiliado, desctipocuenta, cuentas.nrocuenta,nrobanco,    
       nrosucursal,    digitoverificador,concat(cbuini    ,cbufin)cbuafiliado, banco.idbanco,nombrebanco    ,bacodigoentidad,    baactivo
       	,'1-Afiliado#elafiliado@2-Nro.Afiliado#nroafiliado@3-Tipo Cuenta#desctipocuenta@4-Nro.Cuenta#nrocuenta@5-Nro.Banco#nrobanco@6-Nro.Sucursal#nrosucursal@7-Dig. Verificador#digitoverificador@8-CBU#cbuafiliado@9-Banco#nombrebanco@10-Codigo Entidad#bacodigoentidad@11-Banco Activo#baactivo'::text as mapeocampocolumna

       FROM persona natural join cuentas natural join tipocuenta join banco on(nrobanco=idbanco)
       where (cuentas.nrocuenta is not null OR length(concat(cbuini,cbufin))=22) AND (persona.nrodoc =rfiltros.nrodoc OR nullvalue(rfiltros.nrodoc))
       order by apellido, nombres
);
    
return 'true';
END;
$function$
