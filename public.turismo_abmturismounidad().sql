CREATE OR REPLACE FUNCTION public.turismo_abmturismounidad()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
      rturismounid record;
      rdir record;
      elidturismounidad BIGINT;
      eliddireccion BIGINT;

      cturismounid refcursor;
      unazona record;
BEGIN

/*     CREATE TEMP TABLE tempturismounidad ( 	  idturismounidad BIGSERIAL,	  idturismoadmin INTEGER ,	  tudescripcion VARCHAR,	  idlocalidad INTEGER, 	  tucantidadpersonas INTEGER,	  idturismounidadtipo INTEGER, 	  tutelefono VARCHAR, 	  idturismounidadusotipo INTEGER,	  tudescripcionlarga VARCHAR, 	  tuactiva BOOLEAN );

       INSERT INTO tempturismounidad( idturismounidad ,idturismoadmin,	  tudescripcion,idlocalidad,tucantidadpersonas,idturismounidadtipo,	
        tutelefono,idturismounidadusotipo,	tudescripcionlarga,	tuactiva )VALUES ( 5 , 6,'Habitación Single',49,1,11,'02934-497751' ,1,NULL,TRUE)

       CREATE TEMP TABLE  tempdireccion (iddireccion BIGSERIAL, barrio VARCHAR, calle VARCHAR, nro INTEGER , tira VARCHAR, piso VARCHAR, dpto VARCHAR, idprovincia BIGINT , idlocalidad BIGINT , idcentrodireccion )

        INSERT INTO tempdireccion ( iddireccion,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad,idcentrodireccion )
        VALUES ( 9834,'barrio','AVDA. RIO NEGRO Y EL CUY',0,'tira','piso','depto',3,49,1);
*/

     -- Primero verifico cuantos item tiene un comprobante de ajuste

      SELECT INTO rturismounid * FROM tempturismounidad;
      IF nullvalue(rturismounid.idturismounidad ) THEN -- hay que dar de alta la unidad
               INSERT INTO turismounidad( idturismoadmin,	  tudescripcion,idlocalidad,tucantidadpersonas,idturismounidadtipo,	
               tutelefono,idturismounidadusotipo,	tudescripcionlarga,	tuactiva )
               VALUES (rturismounid.idturismoadmin, rturismounid.tudescripcion,rturismounid.idlocalidad,
               rturismounid.tucantidadpersonas,rturismounid.idturismounidadtipo,	
               rturismounid.tutelefono,rturismounid.idturismounidadusotipo,	rturismounid.tudescripcionlarga,	rturismounid.tuactiva);
               elidturismounidad = currval('public.turismounidad_idturismounidad_seq');
               
      ELSE -- se trata de una actualizacion
              elidturismounidad =rturismounid.idturismounidad;
              UPDATE turismounidad  SET idturismoadmin = rturismounid.idturismoadmin  ,	
              tudescripcion = rturismounid.tudescripcion  ,
              idlocalidad = rturismounid.idlocalidad  ,
              tucantidadpersonas = rturismounid.tucantidadpersonas  ,
              idturismounidadtipo = rturismounid.idturismounidadtipo  ,	
              tutelefono = rturismounid.tutelefono  ,
              idturismounidadusotipo = rturismounid.idturismounidadusotipo  ,
              tudescripcionlarga = rturismounid.tudescripcionlarga  ,
              tuactiva = rturismounid.tuactiva
              WHERE idturismounidad = elidturismounidad;

      END IF;

      SELECT INTO rdir * FROM tempdireccion;
      IF nullvalue(rdir.iddireccion ) THEN  -- hay que dar de alta la direccion
               -- creo la nueva dir
               INSERT INTO direccion ( barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad )
               VALUES ( rdir.barrio,rdir.calle,rdir.nro,rdir.tira,rdir.piso,rdir.dpto,rdir.idprovincia,rdir.idlocalidad);
               eliddireccion =  currval('public.direccion_iddireccion_seq');

               -- actualizo el turismo unidad
               UPDATE turismounidad SET idcentrodireccion = centro(),  iddireccion =eliddireccion
               WHERE idturismounidad =elidturismounidad;
               
      ELSE -- se trata de una actualizacion de la direccion
              UPDATE direccion SET
               barrio = rdir.barrio ,   calle= rdir.calle ,     nro= rdir.nro ,
               tira= rdir.tira ,    piso= rdir.piso ,   dpto= rdir.dpto ,
               idprovincia= rdir.idprovincia ,   idlocalidad= rdir.idlocalidad
               WHERE iddireccion = rdir.iddireccion and idcentrodireccion =rdir.idcentrodireccion;
      

      END IF;
     -- Elimino todas las relaciones entre unidad y las zonas y las vuelvo a insertar
     DELETE FROM turismounidadzona WHERE idturismounidad = elidturismounidad;
     OPEN cturismounid FOR  SELECT DISTINCT * FROM  tempturismounidadzona ;
     FETCH cturismounid into unazona;
     WHILE FOUND LOOP
           INSERT INTO turismounidadzona (idturismounidad ,idturismounidadzonatipo ) VALUES (elidturismounidad,unazona.idturismounidadzonatipo);
           FETCH cturismounid into unazona;
     END LOOP;
     


     return 'Listo';
END;
$function$
