CREATE OR REPLACE FUNCTION public.listado_afiliado_sin_cargos_actuales_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        
    rfiltros record;
        
    
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_listado_afiliado_sin_cargos_actuales_contemporal
    AS (
            SELECT                    
            persona.nrodoc, persona.apellido, persona.nombres, persona.barra, CASE WHEN ( fechafinlab<current_date)  THEN 'SIN CARGO VIGENTE' ELSE iddepen END as cargoactual,
            fechafinlab as fechafincarg, persona.fechafinos, legajosiu, iddepen as ultimocargo, concat (categoria.seaplicaasi , ' | ' ,depuniversitaria.descrip ) as descripcargo
            ,persona.email, t.iddeuda, t.idcentrodeuda, t.importe , t.saldo, t.movconcepto, t.fechamovimiento,t.idcomprobante, t.importepagado

            ,'1-Nro. Doc#nrodoc@2-Apellido#apellido@3-Nombre#nombres@4-Barra#barra@5-Cargo Actual#cargoactual@6-Fecha Fin Ultimo Cargo#fechafincarg@7-Fecha Fin Obra Social#fechafinos@8-Legajo#legajosiu@9-Ultimo Cargo#descripcargo@10-Correo#email@11-Id. Deuda#iddeuda@12-Idcentro Deuda#idcentrodeuda@13-Importe#importe@14-Saldo#saldo@15-Importe Pagado#importepagado@16-Concepto#movconcepto@17-Fecha Movimiento#fechamovimiento@18-Comprobante#idcomprobante'::text as mapeocampocolumna

            FROM persona
            natural join tiposdoc
            LEFT join
                (select nrodoc,tipodoc,legajosiu
                from afilidoc
                union
                select nrodoc,tipodoc,legajosiu
                from afilinodoc
                union
                select nrodoc,tipodoc,legajosiu
                from afilisos
                union
                select nrodoc,tipodoc,legajosiu
                from afilirecurprop
                union
                select nrodoc,tipodoc, legajosiu
                from afiliauto
                union
                select nrodoc,tipodoc, legajosiu
                from afiliauto
                ) as datospersona USING(nrodoc,tipodoc)
            left join (
                 select max(fechafinlab) as fechafinlab,nrodoc,tipodoc,max(iddepen) as iddepen, max(idcargo) as idcargo
                 from cargo
                 group by nrodoc,tipodoc ) x on persona.nrodoc=x.nrodoc and persona.tipodoc=x.tipodoc
            LEFT JOIN depuniversitaria USING (iddepen)
            LEFT JOIN ( 
                SELECT idcateg, idcargo
                FROM cargo 
                group BY idcateg, idcargo) as carg
                on (x.idcargo=carg.idcargo)
            LEFT JOIN categoria USING (idcateg)
            LEFT JOIN (
                    SELECT 
                        cuentacorrientedeuda.iddeuda, cuentacorrientedeuda.idcentrodeuda, cuentacorrientedeuda.importe
                        , cuentacorrientedeuda.saldo, cuentacorrientedeuda.movconcepto, cuentacorrientedeuda.nrodoc, cuentacorrientedeuda.fechamovimiento
                    ,idcomprobante, CASE WHEN nullvalue(pagosctacte.importepagado) THEN 0 ELSE pagosctacte.importepagado END as importepagado 
                    FROM cuentacorrientedeuda NATURAL JOIN persona 
                    LEFT JOIN ( SELECT sum(importeimp) as importepagado,iddeuda,idcentrodeuda 
                                FROM cuentacorrientedeudapago NATURAL JOIN cuentacorrientepagos 
                                group by iddeuda,idcentrodeuda ) as pagosctacte USING(iddeuda,idcentrodeuda) 
                    WHERE 
                        (cuentacorrientedeuda.importe - CASE WHEN nullvalue(pagosctacte.importepagado) THEN 0 ELSE pagosctacte.importepagado END) >= '0.01' 
                        AND TRUE AND TRUE  AND cuentacorrientedeuda.saldo >0

                    ORDER BY cuentacorrientedeuda.nrodoc, cuentacorrientedeuda.fechamovimiento ) as t ON (datospersona.nrodoc=t.nrodoc)

            WHERE persona.fechafinos > current_date --AND nullvalue(iddepen)
            and ( NOT nullvalue(legajosiu))
            AND ( persona.barra=30 OR persona.barra=31 OR persona.barra=32 )
            AND fechafinlab<current_date 

            ORDER BY persona.fechafinos, fechafinlab, persona.nrodoc, fechamovimiento desc

    );
  

return true;
END;
$function$
