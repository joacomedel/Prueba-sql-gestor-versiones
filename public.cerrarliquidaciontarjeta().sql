CREATE OR REPLACE FUNCTION public.cerrarliquidaciontarjeta()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
    rliq RECORD;
    xestado bigint;
    unaordenpago RECORD;
    generar boolean;
    rordenpago RECORD;
    resultado boolean;
    xidliq bigint;
    xidcentroliq integer;
    laorden bigint;
    xfechaimputa date;
    xnrocuentacordenpago VARCHAR;
   
BEGIN
  

    --CS 2019-04-09
    --Si No Existe Minuta, entonces Generarla...

    SELECT INTO unaordenpago * FROM tempordenpago;
        
    xidliq = unaordenpago.idsiges::bigint/100;
    xidcentroliq = unaordenpago.idsiges::bigint%100;
    

--MaLaPi 24-09-2020 Agrego para que la cuenta contable de la Minuta, se defina segun el banco que se trate
IF not existecolumtemp('tempordenpago', 'nrocuentachaber') THEN 
          ALTER TABLE tempordenpago ADD COLUMN nrocuentachaber VARCHAR;

END IF; 
--KR 29-03-23 modifico la consulta, no se inserta la 1ra vez en mapeoliquidaciontarjeta, se hace recien al final de este sp. Esa tabla es para la migracion de multivac
SELECT into xnrocuentacordenpago case when nullvalue(nrocuentacordenpago) THEN '10374' ELSE nrocuentacordenpago END as nrocuentacordenpago 
FROM  liquidaciontarjeta JOIN cuentabancariasosunc USING(idcuentabancaria) 
join banco USING(idbanco) LEFT JOIN mapeoliquidaciontarjeta USING(idliquidaciontarjeta,idcentroliquidaciontarjeta) 
WHERE idliquidaciontarjeta = xidliq AND idcentroliquidaciontarjeta = xidcentroliq; 

RAISE NOTICE 'xnrocuentacordenpago (%)',xnrocuentacordenpago;

UPDATE tempordenpago SET nrocuentachaber = xnrocuentacordenpago ;
SELECT INTO unaordenpago * FROM tempordenpago;

RAISE NOTICE 'unaordenpago (%)',unaordenpago;
    generar=false;

    select into laorden idcomprobantemultivac::bigint 
        from mapeoliquidaciontarjeta m
        join ordenpago o on (m.idcomprobantemultivac::bigint/100=o.nroordenpago and m.idcomprobantemultivac::bigint%100= o.idcentroordenpago) 
       --KR 21-04-22 Modifico el natural join, hoy se agrego a la tabla  mapeoliquidaciontarjeta las columnas nroordenpago , idcentroordenpago y eso rompio el join
        --natural join ordenpagoimputacion
        join ordenpagoimputacion opi ON (o.nroordenpago= opi.nroordenpago and o.idcentroordenpago=opi.idcentroordenpago)
        where m.idliquidaciontarjeta=xidliq and m.idcentroliquidaciontarjeta=xidcentroliq;
      
    if found then --EXISTE        
            --select into rordenpago * from ordenpago natural join ordenpagoimputacion where nroordenpago=xnroordenpago/100 and centro=xnroordenpago%100;
            --MaLaPi 12/01/2022 Hay varias OP que no guardaron la cuentas del haber, entonces la guardo cuando se abre y cierra una liq              
            UPDATE ordenpago SET nrocuentachaber = unaordenpago.nrocuentachaber WHERE nroordenpago = laorden/100;  
            if ordenpago_esigual(laorden) then -- ES IGUAL A LA ANTERIOR
               -- CAMBIAR EL ESTADO de la OP a ACTIVA
               PERFORM cambiarestadoordenpago(laorden/100,(laorden%100)::integer,3,concat('Al Modificar la Liquidacion Tarjeta ',unaordenpago.idsiges));
            else
               -- ANULAR OP y Revertir el Asiento Contable
                PERFORM cambiarestadoordenpago(laorden/100,(laorden%100)::integer,4,concat('Al Modificar la Liquidacion Tarjeta ',unaordenpago.idsiges));
                PERFORM asientogenerico_revertir(idasientogenerico*100+idcentroasientogenerico)
                    from asientogenerico where idcomprobantesiges=concat(laorden/100,'|',laorden%100);
                generar=true;
            end if;
    else    -- NO EXISTE
        generar=true;
    end if;
    
    if generar then
        -- GENERAR la MINUTA    

        IF nullvalue(unaordenpago.nroordenpago) THEN
                SELECT INTO laorden nextval('ordenpago_seq')*100+centro()  ;
                UPDATE tempordenpagoimputacion SET nroordenpago = laorden/100;
                UPDATE tempordenpago SET nroordenpago = laorden/100;
        ELSE
                laorden = unaordenpago.nroordenpago*100+centro();
        END IF;

--MaLaPi 05-06-2019 la fecha de ingreso de la minuta se usar para la fecha de imputación del asiento. Por lo que la fecha de ingreso de la minuta  debe venir de la fecha de imputacion de los comprobantes de gastos
--       select into xfechaimputa max(fechaimputacion) fechaimputacion 
--       from reclibrofact r
--       join liquidaciontarjetacomprobantegasto l on (r.numeroregistro=l.nroregistro and r.anio=l.anio)
--        where l.idliquidaciontarjeta = xidliq AND idcentroliquidaciontarjeta = xidcentroliq;
--       IF FOUND THEN
--            UPDATE tempordenpago SET fechaingreso = xfechaimputa;
--       END IF;

        SELECT INTO resultado generarordenpago();
        if resultado then
           PERFORM cambiarestadoordenpago(laorden/100,(laorden%100)::integer,3,concat('Al Cerrar la Liquidacion Tarjeta ',unaordenpago.idsiges));

        end if;
 
    end if;

    -- CERRAR LA LIQUIDACION TARJETA

         --MaLaPi 21-04-2022 Agregos 2 nuevos campos al mapeo de liquidacion de tarjeta nroordenpago,idcentroordenpago
	select into xestado * from mapeoliquidaciontarjeta where idliquidaciontarjeta=xidliq and idcentroliquidaciontarjeta=xidcentroliq;
        if not found then   -- La Liq Aun No esta cerrada
         	insert into mapeoliquidaciontarjeta(idliquidaciontarjeta,idcentroliquidaciontarjeta,idcomprobantemultivac,nroordenpago,idcentroordenpago)
	        values(xidliq,xidcentroliq,laorden,laorden/100,laorden%100);
        else

            update mapeoliquidaciontarjeta set idcomprobantemultivac=laorden,nroordenpago =laorden/100 , idcentroordenpago = laorden%100
            where idliquidaciontarjeta=xidliq and idcentroliquidaciontarjeta=xidcentroliq;

        end if;

    insert into liquidaciontarjetaestado(idliquidaciontarjeta,idcentroliquidaciontarjeta,idtipoestadoliquidaciontarjeta)
	values(xidliq,xidcentroliq,2);

     --MaLaPi
      UPDATE ordenpago SET nroordenpago = laorden/100 WHERE nroordenpago = laorden/100;

     RETURN laorden;
END;$function$
