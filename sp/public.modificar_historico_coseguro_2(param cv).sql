CREATE OR REPLACE FUNCTION public.modificar_historico_coseguro_2(param character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    -- declarations
BEGIN
/*
      update practconvval  
      set tvvigente = false
           ,pcvfechafin = '2023-12-01',pcvfechamodifica = '2023-12-01 09:47:02.97526-03'
           , pcvobs = 'Toca Malapi para reflotar luego de invertir el orden de carga - se quita de vigencia'
      where (idpractconvval, idasocconv, idsubcapitulo, idcapitulo, idpractica, idnomenclador, internacion) IN (
            select idpractconvval, idasocconv, idsubcapitulo, idcapitulo, idpractica, idnomenclador, internacion
            from practconvval 
            where fijoh1	and fijoh2 and	fijoh3 and fijogs 
                  and pcvfechainicio = '2023-11-01' 
                  and pcvfechamodifica >= '2023-12-22 09:47:02.97526-03'
                  and idasocconv <> 154
                  and tvvigente 
--- para asegurarme que la que estoy dando de baja sea una de las practicas que luego voy a activar su valor
                  and (idasocconv,idsubcapitulo,idcapitulo,idpractica,idnomenclador,fijoh1,fijoh2,fijoh3,fijogs,internacion) 
                      in (select idasocconv,idsubcapitulo,idcapitulo,idpractica,idnomenclador,fijoh1,fijoh2,fijoh3,fijogs,internacion
                          from practconvval 
                          where fijoh1	and fijoh2 and	fijoh3 and	fijogs 
                                and pcvfechainicio = '2023-12-01' and pcvfechafin = '2023-11-01'
                                and not tvvigente  )
           );


-- SELECT count(*)  se actualizaron 31160
---FROM practconvval  
--- wHERE pcvobs = 'Toca Malapi para reflotar luego de invertir el orden de carga - se quita de vigencia'
*/
      update practconvval  
      set tvvigente = true,pcvfechafin = null,pcvfechamodifica = now()
        , pcvobs = 'Toca Malapi para reflotar luego de invertir el orden de carga - poner configuracion de valores  vigentes '
      where fijoh1	and fijoh2 and	fijoh3 and	fijogs --- me aseguro q es un valor fijo
            and pcvfechainicio = '2023-12-01' and pcvfechafin = '2023-11-01'
            and not tvvigente;

    return true;
END;
$function$
