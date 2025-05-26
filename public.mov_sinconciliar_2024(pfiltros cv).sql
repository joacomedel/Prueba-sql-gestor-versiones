CREATE OR REPLACE FUNCTION public.mov_sinconciliar_2024(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$

DECLARE

    rfiltros record;
    rafiliado record;
    unaconcilbanc record;
    respboolean boolean;

    cursconcilbanc refcursor;
    
    /*Ejemplo:
        SELECT * FROM mov_sinconciliar_2024( 
        '{"nrodoc"=27091730,"tipodoc"=1}'
        );
    */
BEGIN


    EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

    respboolean=true;

    CREATE TEMP TABLE temp_movsigessinconciliar_todos(
        idconciliacionbancaria integer,
        fechacompr date,
        elcomprobante character varying,
        detalle character varying,
        monto double precision,
         impconc double precision, 
        agfechacontable character varying
        );

    OPEN cursconcilbanc FOR SELECT *
        FROM conciliacionbancaria
        --natural join cuentabancariasosunc
        WHERE cbfechadesdemovimiento>='2024-01-01' AND cbfechahastamovimiento<='2024-12-31'
        AND idcuentabancaria=6;
      FETCH cursconcilbanc INTO unaconcilbanc;
      WHILE FOUND LOOP

        INSERT INTO temp_movsigessinconciliar_todos (
            SELECT unaconcilbanc.idconciliacionbancaria, fechacompr,elcomprobante,detalle,monto,round((impconc::numeric),2) as impconc,agfechacontable
            FROM (
                SELECT * , (1) as multiplicador
                FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',unaconcilbanc.idcentroconciliacionbancaria,', idconciliacionbancaria=',unaconcilbanc.idconciliacionbancaria,',  todos=false, movfechadesde=', unaconcilbanc.cbfechadesdemovimiento , ' , tipoComp=OPC, cadena=null, nrocuentac=',10261,', movfechahasta=',unaconcilbanc.cbfechahastamovimiento,'}') )
                WHERE FALSE or  impconc >0

                union
                SELECT * , (1) as multiplicador
                FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',unaconcilbanc.idcentroconciliacionbancaria,', idconciliacionbancaria=',unaconcilbanc.idconciliacionbancaria,',  todos=false, movfechadesde=', unaconcilbanc.cbfechadesdemovimiento , ' , tipoComp=FA, cadena=null, nrocuentac=',10261,', movfechahasta=',unaconcilbanc.cbfechahastamovimiento,'}') )
                WHERE FALSE or  impconc >0

                union
                SELECT * , (1) as multiplicador
                FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',unaconcilbanc.idcentroconciliacionbancaria,', idconciliacionbancaria=',unaconcilbanc.idconciliacionbancaria,',  todos=false, movfechadesde=', unaconcilbanc.cbfechadesdemovimiento , ' , tipoComp=MIN, cadena=null,  nrocuentac=',10261,', movfechahasta=',unaconcilbanc.cbfechahastamovimiento,'}') )
                WHERE FALSE or  impconc >0

                union
                SELECT * , (1) as multiplicador
                FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',unaconcilbanc.idcentroconciliacionbancaria,', idconciliacionbancaria=',unaconcilbanc.idconciliacionbancaria,',  todos=false, movfechadesde=', unaconcilbanc.cbfechadesdemovimiento , ' , tipoComp=RE|Descuento UNC|not ilike, cadena=null,  nrocuentac=',10261,', movfechahasta=',unaconcilbanc.cbfechahastamovimiento,'}') )
                WHERE FALSE or  impconc >0

                union
                SELECT * , (1) as multiplicador
                FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',unaconcilbanc.idcentroconciliacionbancaria,', idconciliacionbancaria=',unaconcilbanc.idconciliacionbancaria,',todos=false, movfechadesde=', unaconcilbanc.cbfechadesdemovimiento , ' , tipoComp=LT, cadena=null,  nrocuentac=',10261,', movfechahasta=',unaconcilbanc.cbfechahastamovimiento,'}') )
                WHERE FALSE or  impconc >0

                order by fechacompr
                ) as T
            );


        FETCH cursconcilbanc INTO unaconcilbanc;               
      END LOOP;

    RETURN respboolean;
    --RAISE EXCEPTION 'respboolean  %', respboolean;
END;
$function$
