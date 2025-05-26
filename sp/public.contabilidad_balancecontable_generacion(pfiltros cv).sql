CREATE OR REPLACE FUNCTION public.contabilidad_balancecontable_generacion(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	cursorctacblesumariza refcursor;
	rparam RECORD;
	rctacblesumariza RECORD; 
	rdatosctassumariza RECORD;
	rfiltros RECORD;

BEGIN

	EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

	PERFORM contabilidad_balancecontable_mensual_indicexinflacion(concat('idejerciciocontable=',rfiltros.idejerciciocontable));



	OPEN cursorctacblesumariza FOR SELECT *
                            FROM cuentacontablesumariza ccs
                            JOIN cuentascontables c ON (ccsnrocuentac=nrocuentac)
                            JOIN contabilidad_historico_indices_inflacion ON ( c.nrocuentac =  hiicuenta)
                            /*WHERE 
                                ccsnrocuentac=10420*/
                            ORDER BY ccsnrocuentac asc
                            ;

        FETCH cursorctacblesumariza INTO rctacblesumariza;
        WHILE FOUND LOOP 

            SELECT INTO rdatosctassumariza 
            sum(hiihistorico) as hiihistorico, sum(hiihistorico_saldo) as hiihistorico_saldo, sum(hiisaldoinicialanual_saldo) as hiisaldoinicialanual_saldo, sum(hiisaldoinicialanual) as hiisaldoinicialanual, 

            sum(hiienero) as hiienero, sum(hiifebrero) as hiifebrero, sum(hiimarzo) as hiimarzo, sum(hiiabril) as hiiabril,
            sum(hiimayo) as hiimayo, sum(hiijunio) as hiijunio, sum(hiijulio) as hiijulio, sum(hiiagosto) as hiiagosto,
            sum(hiiseptiembre) as hiiseptiembre, sum(hiioctubre) as hiioctubre, sum(hiinoviembre) as hiinoviembre, sum(hiidiciembre) as hiidiciembre,

            sum(hiienero_saldo) as hiienero_saldo, sum(hiifebrero_saldo) as hiifebrero_saldo, sum(hiimarzo_saldo) as hiimarzo_saldo, sum(hiiabril_saldo) as hiiabril_saldo,
            sum(hiimayo_saldo) as hiimayo_saldo, sum(hiijunio_saldo) as hiijunio_saldo, sum(hiijulio_saldo) as hiijulio_saldo, sum(hiiagosto_saldo) as hiiagosto_saldo,
            sum(hiiseptiembre_saldo) as hiiseptiembre_saldo, sum(hiioctubre_saldo) as hiioctubre_saldo, sum(hiinoviembre_saldo) as hiinoviembre_saldo, sum(hiidiciembre_saldo) as hiidiciembre_saldo

            FROM cuentacontablesumariza ccs
            JOIN cuentascontables c ON ( c.nrocuentac = ANY(string_to_array(ccs.ccslistacuentas, ',')) )
            JOIN contabilidad_historico_indices_inflacion ON ( c.nrocuentac =  hiicuenta)
            WHERE not nullvalue(ccslistacuentas)
            AND ccsnrocuentac=rctacblesumariza.ccsnrocuentac
            GROUP BY ccs.ccsnrocuentac
            ORDER BY ccsnrocuentac asc
            ;

            UPDATE contabilidad_historico_indices_inflacion
            SET hiihistorico=rdatosctassumariza.hiihistorico, 
            hiihistorico_saldo=rdatosctassumariza.hiihistorico_saldo,
            hiisaldoinicialanual_saldo=rdatosctassumariza.hiisaldoinicialanual_saldo,
            hiisaldoinicialanual=rdatosctassumariza.hiisaldoinicialanual,


            hiienero=rdatosctassumariza.hiienero,
            hiifebrero=rdatosctassumariza.hiifebrero,
            hiimarzo=rdatosctassumariza.hiimarzo,
            hiiabril=rdatosctassumariza.hiiabril,
            hiimayo=rdatosctassumariza.hiimayo,
            hiijunio=rdatosctassumariza.hiijunio,
            hiijulio=rdatosctassumariza.hiijulio,
            hiiagosto=rdatosctassumariza.hiiagosto,
            hiiseptiembre=rdatosctassumariza.hiiseptiembre,
            hiioctubre=rdatosctassumariza.hiioctubre,
            hiinoviembre=rdatosctassumariza.hiinoviembre,
            hiidiciembre=rdatosctassumariza.hiidiciembre,


            hiienero_saldo=rdatosctassumariza.hiienero_saldo,
            hiifebrero_saldo=rdatosctassumariza.hiifebrero_saldo,
            hiimarzo_saldo=rdatosctassumariza.hiimarzo_saldo,
            hiiabril_saldo=rdatosctassumariza.hiiabril_saldo,
            hiimayo_saldo=rdatosctassumariza.hiimayo_saldo,
            hiijunio_saldo=rdatosctassumariza.hiijunio_saldo,
            hiijulio_saldo=rdatosctassumariza.hiijulio_saldo,
            hiiagosto_saldo=rdatosctassumariza.hiiagosto_saldo,
            hiiseptiembre_saldo=rdatosctassumariza.hiiseptiembre_saldo,
            hiioctubre_saldo=rdatosctassumariza.hiioctubre_saldo,
            hiinoviembre_saldo=rdatosctassumariza.hiinoviembre_saldo,
            hiidiciembre_saldo=rdatosctassumariza.hiidiciembre_saldo
            WHERE hiicuenta = rctacblesumariza.ccsnrocuentac;

        FETCH cursorctacblesumariza INTO rctacblesumariza;
        END LOOP;



	return true;

END;
$function$
