CREATE OR REPLACE FUNCTION public.far_regenerarorden(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


cTFAR_ORDENVENTA refcursor;
cTFAR_ORDENVENTAITEM refcursor;    
cTFAR_ORDENVENTAITEMIMPORTES refcursor;
cTEMP_FAR_ARTICULOTRAZABILIDAD refcursor;
cTFAR_ORDENVALIDACIONES refcursor;


RTFAR_ORDENVENTA RECORD;
RTFAR_ORDENVENTAITEM RECORD;    
RTFAR_ORDENVENTAITEMIMPORTES RECORD;
RTEMP_FAR_ARTICULOTRAZABILIDAD RECORD;
RTFAR_ORDENVALIDACIONES RECORD;
rparam RECORD;

contador INTEGER;
contador2 INTEGER;

BEGIN




--CREATES
CREATE TEMP TABLE TFAR_ORDENVENTA (         
    IDORDENVENTA INTEGER,           
    OVFECHA TIMESTAMP WITHOUT TIME ZONE,        
    IDORDENVENTATIPO INTEGER,           
    IDVENDEDOR INTEGER NOT NULL,            
    IDAFILIADO INTEGER ,            
    IDCENTROAFILIADO INTEGER ,          
    NROCLIENTE VARCHAR NOT NULL,            
    BARRA BIGINT NOT NULL,          
    OVNOMBRECLIENTE VARCHAR,            
    OVOBSERVACION VARCHAR,          
    OVNRORECETA VARCHAR,            
    CENTRO VARCHAR,         
    OVFECHAUSO DATE,            
    NROMATRICULA INTEGER,           
    MALCANCE VARCHAR,           
    MESPECIALIDAD VARCHAR,          
    IDPRESTADOR BIGINT,         
    IDVALIDACION INTEGER,          
    IDCENTROVALIDACION INTEGER          
    );

CREATE TEMP TABLE TFAR_ORDENVENTAITEM (         
    IDORDENVENTAITEM INTEGER,           
    IDORDENVENTA INTEGER,           
    IDCENTROORDENVENTA INTEGER DEFAULT CENTRO(),            
    IDARTICULO INTEGER,         
    IDCENTROARTICULO INTEGER,           
    OVIDESCRIPCION VARCHAR,         
    OVICANTIDAD INTEGER,            
    IDCENTROORDENVENTAITEM INTEGER DEFAULT CENTRO() NOT NULL,           
    OVIPRECIOVENTA DOUBLE PRECISION,            
    OVIDESCUENTO DOUBLE PRECISION,              
    OVIIMPDESCUENTO DOUBLE PRECISION,               
    OVIPRECIOLISTA DOUBLE PRECISION,            
    OVIALICUOTAIVA DOUBLE PRECISION,         
    OVIIMPORTEIVA DOUBLE PRECISION,         
    IDARTICULOTRAZA INTEGER,            
    IDCENTROARTICULOTRAZA INTEGER,           
    OVIIDIVA BIGINT         );

CREATE TEMP TABLE TFAR_ORDENVENTAITEMIMPORTES (     
    IDORDENVENTAITEM INTEGER,       
    IDCENTROORDENVENTAITEM INTEGER,     
    IDVALORESCAJA INTEGER NOT NULL,         
    OVIIMONTO DOUBLE PRECISION NOT NULL,        
    OVIICOB DOUBLE PRECISION NOT NULL,     
    OVIIAUTORIZACION  VARCHAR,     
    IDAFILIADOCOBERTURA INTEGER,      
    NRODOC VARCHAR ,
    IDCENTROAFILIADOCOBERTURA INTEGER
    );

CREATE TEMP TABLE TEMP_FAR_ARTICULOTRAZABILIDAD (    
    IDARTICULOTRAZA BIGINT NOT NULL,    
    IDCENTROARTICULOTRAZA INTEGER DEFAULT CENTRO() NOT NULL,    
    IDARTICULO BIGINT,    
    IDCENTROARTICULO INTEGER,       
    ATCODIGOTRAZABILIDAD CHARACTER VARYING,    
    ATCODIGOBARRAGTIN CHARACTER VARYING,    
    NRODOC CHARACTER VARYING(8),    
    TIPODOC INTEGER,    
    IDORDENVENTAITEM BIGINT,    
    IDCENTROORDENVENTAITEM INTEGER
    );

CREATE TEMP TABLE TFAR_ORDENVALIDACIONES (    
    IDORDENVENTA BIGINT NOT NULL, 
    IDCENTROORDENVENTA INTEGER DEFAULT CENTRO(), 
    IDVALIDACION INTEGER NOT NULL,  
    IDCENTROVALIDACION INTEGER
    );

--------------------------------------------------------------------------------------------

-- OBTENGO PARAMETROS 
EXECUTE sys_dar_filtros($1) INTO rparam; 



--------------------------------------------------------------------------------------------
--Busco datos y genero los insert

SELECT into RTFAR_ORDENVENTA *  FROM far_ordenventa WHERE idordenventa=rparam.idordenventa AND idcentroordenventa=rparam.idcentroordenventa;

IF FOUND THEN 
    INSERT INTO tfar_ordenventa (idordenventa,ovfecha,idordenventatipo,idvendedor,idafiliado,idcentroafiliado, 
    nrocliente,barra,ovnombrecliente,ovobservacion,ovnroreceta,centro,ovfechauso,nromatricula,malcance,mespecialidad,idprestador,
    idvalidacion) VALUES (
        1,           
        current_timestamp,        
        2,           
        RTFAR_ORDENVENTA.idvendedor,            
        RTFAR_ORDENVENTA.idafiliado  ,            
        RTFAR_ORDENVENTA.idcentroafiliado  ,          
        RTFAR_ORDENVENTA.nrocliente ,            
        RTFAR_ORDENVENTA.barra ,          
        RTFAR_ORDENVENTA.ovnombrecliente ,            
        RTFAR_ORDENVENTA.ovobservacion ,          
        '',--RTFAR_ORDENVENTA.OVNRORECETA ,            
        RTFAR_ORDENVENTA.idcentroordenventa      ,         
        now(),--RTFAR_ORDENVENTA.OVFECHAUSO ,            
        0,--RTFAR_ORDENVENTA.NROMATRICULA ,           
        '',--RTFAR_ORDENVENTA.MALCANCE ,           
        '',--RTFAR_ORDENVENTA.MESPECIALIDAD ,          
        null,--RTFAR_ORDENVENTA.IDPRESTADOR ,         
        RTFAR_ORDENVENTA.idvalidacion --,          
        --RTFAR_ORDENVENTA.idcentrovalidacion 
        );


    OPEN cTFAR_ORDENVALIDACIONES FOR SELECT *  FROM far_ordenvalidaciones WHERE idordenventa=rparam.idordenventa AND idcentroordenventa=rparam.idcentroordenventa;
    FETCH cTFAR_ORDENVALIDACIONES into RTFAR_ORDENVALIDACIONES;
        WHILE  FOUND LOOP
            INSERT INTO tfar_ordenvalidaciones (idordenventa,idcentroordenventa,idvalidacion,idcentrovalidacion)     
            VALUES (
                1,
                99,
                RTFAR_ORDENVALIDACIONES.idvalidacion,
                99
                );


            FETCH cTFAR_ORDENVALIDACIONES into RTFAR_ORDENVALIDACIONES;
        END LOOP;
    CLOSE cTFAR_ORDENVALIDACIONES;

    contador=1;
    OPEN cTFAR_ORDENVENTAITEM FOR SELECT *  FROM far_ordenventaitem  LEFT JOIN tipoiva ON(idiva=oviidiva) WHERE idordenventa=rparam.idordenventa AND idcentroordenventa=rparam.idcentroordenventa;
    FETCH cTFAR_ORDENVENTAITEM into RTFAR_ORDENVENTAITEM;
        WHILE  FOUND LOOP
            INSERT INTO tfar_ordenventaitem(idordenventa,idordenventaitem,idarticulo,idcentroarticulo,ovidescripcion,ovicantidad,oviprecioventa,
                    ovidescuento,ovipreciolista,oviimpdescuento,oviimporteiva,ovialicuotaiva,oviidiva)   
            VALUES (
                1,
                contador,
                RTFAR_ORDENVENTAITEM.idarticulo,
                RTFAR_ORDENVENTAITEM.idcentroarticulo,
                RTFAR_ORDENVENTAITEM.ovidescripcion,
                RTFAR_ORDENVENTAITEM.ovicantidad,
                RTFAR_ORDENVENTAITEM.oviprecioventa,
                RTFAR_ORDENVENTAITEM.ovidescuento,
                RTFAR_ORDENVENTAITEM.ovipreciolista,
                RTFAR_ORDENVENTAITEM.oviimpdescuento,
                RTFAR_ORDENVENTAITEM.oviimporteiva,
                RTFAR_ORDENVENTAITEM.porcentaje,
                RTFAR_ORDENVENTAITEM.oviidiva
                );
                contador2=1;

                OPEN CTFAR_ORDENVENTAITEMIMPORTES FOR SELECT * 
                FROM far_ordenventaitemimportes  
                LEFT JOIN far_afiliado ON (oviinrodoc=nrodoc AND oviitipodoc=tipodoc AND  oviiidafiliadocobertura=idobrasocial)
                WHERE   
                        idordenventaitem=RTFAR_ORDENVENTAITEM.idordenventaitem 
                        AND idcentroordenventaitem=RTFAR_ORDENVENTAITEM.idcentroordenventaitem;
                        
                FETCH CTFAR_ORDENVENTAITEMIMPORTES into RTFAR_ORDENVENTAITEMIMPORTES;
                    WHILE  FOUND LOOP
                

                    IF FOUND THEN
                        INSERT INTO tfar_ordenventaitemimportes (idordenventaitem,idvalorescaja,oviimonto,oviicob,oviiautorizacion,
                            idafiliadocobertura,
                            idcentroafiliadocobertura,nrodoc)   
                        VALUES (
                            contador,
                            RTFAR_ORDENVENTAITEMIMPORTES.idvalorescaja,
                            RTFAR_ORDENVENTAITEMIMPORTES.oviimonto,
                            RTFAR_ORDENVENTAITEMIMPORTES.oviiporcentajecobertura,
                            RTFAR_ORDENVENTAITEMIMPORTES.oviiautorizacion,
                            RTFAR_ORDENVENTAITEMIMPORTES.idafiliado,
                            RTFAR_ORDENVENTAITEMIMPORTES.idcentroafiliado,
                            RTFAR_ORDENVENTAITEMIMPORTES.oviinrodoc
                        );
                    END IF;
                    contador2= contador2+1;
            FETCH CTFAR_ORDENVENTAITEMIMPORTES into RTFAR_ORDENVENTAITEMIMPORTES;
            END LOOP;
            CLOSE CTFAR_ORDENVENTAITEMIMPORTES;
            contador= contador+1;

    FETCH cTFAR_ORDENVENTAITEM into RTFAR_ORDENVENTAITEM;
    END LOOP;
    CLOSE cTFAR_ORDENVENTAITEM;

    PERFORM  far_ingresarordenventatrazabilidad()  as ordenventa;

END IF;



return true;

END;
$function$
