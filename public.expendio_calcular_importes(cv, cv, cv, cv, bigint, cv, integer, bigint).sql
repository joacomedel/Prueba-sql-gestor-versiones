CREATE OR REPLACE FUNCTION public.expendio_calcular_importes(character varying, character varying, character varying, character varying, bigint, character varying, integer, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        pidnomenclador alias for $1;
        pidcapitulo alias for $2;
        pidsubcapitulo alias for $3;
        pidpractica alias for $4;
        pidplancoberturas alias for $5;
        pidasociacion alias for $8;
        pnrodoc alias for $6;
        ptipodoc alias for $7;
        lapracticavalor record;
        lapractctacle record;
        rposibleconsumo refcursor;

        tieneamuc boolean;
        imppractica double precision;
        --imppracticacobertura double precision;
        importeamuc double precision;
        importesosunc double precision;
        impaffiliado double precision;
        cesposibleelconsumo CURSOR FOR SELECT * FROM esposibleelconsumo;
        rposibleelconsumo record;
        --ppp double precision;
        --BelenA 31/03/25 agrego para los calculos:
        inttieneamuc integer; --Es un 1 o un 0 dependiendo de si el afil tiene o no amuc (Para multiplicar)
        pcoberturaamuc double precision;
        pAUXcoberturasosunc double precision;
        pcoberturasosunc double precision;

BEGIN

    open cesposibleelconsumo;
    FETCH cesposibleelconsumo into rposibleelconsumo;
        WHILE FOUND LOOP

            SELECT INTO lapractctacle * FROM practica
            WHERE  idcapitulo = pidcapitulo
                   AND idnomenclador = pidnomenclador
                   AND idsubcapitulo = pidsubcapitulo
                   AND idpractica = pidpractica;
            /* -- BelenA 31/03/25 31/03/25 todo lo original:
                -- RECUPERO  LA INFORMACION DE LOS IMPORTES DE LA PRACTICA
                                SELECT INTO lapracticavalor *
                                FROM practicavalores
                                WHERE  idcapitulo = pidcapitulo
                                       AND idsubespecialidad = pidnomenclador
                                       AND idsubcapitulo = pidsubcapitulo
                                       AND idpractica = pidpractica
                                       and  not internacion
                                       and  idasocconv  = pidasociacion;
                                
                                imppractica =lapracticavalor.importe;
                              

                                SELECT into tieneamuc expendio_tiene_amuc(pnrodoc,ptipodoc);
                                IF tieneamuc THEN -- calcula cobertura amuc
                                   IF(  rposibleelconsumo.coberturaamuc > 1) THEN
                                       importeamuc = rposibleelconsumo.coberturaamuc;
                                   ELSE
                                       importeamuc = rposibleelconsumo.coberturaamuc * imppractica;
                                   END IF;
                                
                                ELSE
                                    importeamuc = 0;
                                END IF;
                                -- calcula importe sosunc

                                IF ( (imppractica -importesosunc - importeamuc)< 0) THEN
                                         importesosunc = imppractica - importeamuc;
                                END IF;
                                 importesosunc = imppractica * (rposibleelconsumo.cobertura::float4 /100) ;
                                --Se calcula el importe que el afiliado paga, si es una consulta son 6
                                IF(  rposibleelconsumo.coberturasosunc > 1) THEN
                                       impaffiliado = rposibleelconsumo.coberturasosunc-  importeamuc;
                                       IF impaffiliado < 0 THEN
                                           impaffiliado=0;
                                       END IF;
                                ELSE
                -- CS 2017-05-02
                -- Para que soporte AMUC cuando el importe de cobertura de amuc es mayor

                                        if (imppractica - importesosunc - importeamuc)<0 then
                                            importeamuc = imppractica - importesosunc;                        
                                        end if;
                -------------------------------------------------------------------------
                                        impaffiliado = imppractica - importesosunc -  importeamuc;

                                END IF;
                               
                               
                               -- impaffiliado = imppractica - importesosunc -  importeamuc;
            */
  
               -- RECUPERO  LA INFORMACION DE LOS IMPORTES DE LA PRACTICA
                SELECT INTO lapracticavalor *
                FROM practicavalores
                WHERE  idcapitulo = pidcapitulo
                       AND idsubespecialidad = pidnomenclador
                       AND idsubcapitulo = pidsubcapitulo
                       AND idpractica = pidpractica
                       and  not internacion
                       and  idasocconv  = pidasociacion;
                
                imppractica = lapracticavalor.importe;


                -- BelenA 31/03/25 con lo nuevo de que ahora la cob de amuc deberia ser siempre un porcentaje del tipo 0 <= cob <= 1.
                -- Si AMUC cubre con un porcentaje
                    pcoberturaamuc = rposibleelconsumo.coberturaamuc;
                    importeamuc = pcoberturaamuc * imppractica;

                
                -- cobertura de sosunc
                pAUXcoberturasosunc=rposibleelconsumo.cobertura;
                    -- si la cobertura es mayor a 1, es que por ej ponen 70 si es un 0.7
                    IF pAUXcoberturasosunc > 1 THEN 
                        pcoberturasosunc = pAUXcoberturasosunc/100;
                    ELSE
                        pcoberturasosunc = pAUXcoberturasosunc;
                    END IF;

                --RAISE EXCEPTION 'pcoberturasosunc  % ', pcoberturasosunc ;
                -- Si la suma de la cobertura de Amuc y la de Sosunc es mayor al 100%, sosunc cubre el 100-amuc
                IF (rposibleelconsumo.coberturaamuc + pcoberturasosunc ) > 1 THEN
                    pcoberturasosunc = 1 - pcoberturaamuc;
                ELSE
                    pcoberturasosunc = pcoberturasosunc;
                END IF;
                importesosunc = pcoberturasosunc * imppractica;



                SELECT into tieneamuc expendio_tiene_amuc(pnrodoc,ptipodoc);
                IF tieneamuc THEN inttieneamuc = 1; ELSE inttieneamuc = 0; END IF;



                impaffiliado = 0;

                IF rposibleelconsumo.coberturasosunc > 0 THEN
                --Si tiene monto fijo que no es 0 para el afil

                -- Si AMUC cubre con un porcentaje
                impaffiliado = rposibleelconsumo.coberturasosunc - ( inttieneamuc * (pcoberturaamuc * rposibleelconsumo.coberturasosunc) );

                IF impaffiliado<0 THEN impaffiliado = 0; END IF;  -- Si por como esta configurada la practica el afiliado no tiene que pagar nada
                importesosunc = imppractica - importeamuc - impaffiliado;
                    
                ELSE
                    IF nullvalue(rposibleelconsumo.coberturasosunc) THEN
                    --Si no tiene monto fijo para el afil
                        impaffiliado = imppractica - importeamuc - importesosunc;
                    END IF;
                END IF;



            UPDATE esposibleelconsumo
            SET pimportesosunc =    round(CAST (importesosunc AS numeric),2) ,
                pimporteamuc = round(CAST (importeamuc AS numeric),2) ,
                pimportepractica = imppractica ,
                pimporteafiliado =     round(CAST (impaffiliado AS numeric),2),
                nrocuentac  = lapractctacle.nrocuentac
            WHERE  idesposibleelconsumo = rposibleelconsumo.idesposibleelconsumo;

            FETCH cesposibleelconsumo into rposibleelconsumo;
   
        END LOOP;
    CLOSE cesposibleelconsumo ;
return true;
END;

$function$
