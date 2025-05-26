CREATE OR REPLACE FUNCTION public.crearnuevadireccion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

	recdireccion refcursor;
    dir RECORD;

    unadir RECORD;
    recperconmismadir refcursor;
     unapermismadir RECORD;
     eliddireccion integer;
BEGIN
ALTER TABLE persona disable trigger actualizaestadoconfechafinos;
ALTER TABLE persona disable trigger actualizarbarrastitulares;
ALTER TABLE persona disable trigger aepersona;
ALTER TABLE persona disable trigger ampersona;
     open recdireccion FOR SELECT count(*),iddireccion,idcentrodireccion FROM persona
                         group by iddireccion,idcentrodireccion
                         having count(*)  >1 ;
      FETCH recdireccion into unadir;
      WHILE  found LOOP    	
	               open recperconmismadir for SELECT * FROM persona
                   WHERE persona.iddireccion=unadir.iddireccion and persona.idcentrodireccion =unadir.idcentrodireccion  ;
                   FETCH recperconmismadir into unapermismadir; -- LA primer persona queda con la misma dir cambio las siguientes
                   FETCH recperconmismadir into unapermismadir;
                   while found loop

                         INSERT INTO direccion (barrio, calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
                         (SELECT barrio, calle,nro,tira,piso,dpto,idprovincia,idlocalidad
                         FROM direccion WHERE iddireccion=unadir.iddireccion and idcentrodireccion=unadir.idcentrodireccion);
                         eliddireccion = currval('direccion_iddireccion_seq');

                         UPDATE persona SET idcentrodireccion = centro(), iddireccion = eliddireccion
                         WHERE nrodoc = unapermismadir.nrodoc and tipodoc =unapermismadir.tipodoc;

                         UPDATE cliente SET idcentrodireccion = centro(), iddireccion = eliddireccion
                         WHERE nrocliente = unapermismadir.nrodoc and barra =unapermismadir.barra;
                         
                 FETCH recperconmismadir into unapermismadir;

      end loop;
      CLOSE recperconmismadir;
      FETCH recdireccion into unadir;
      END LOOP;

      CLOSE recdireccion;

ALTER TABLE persona enable trigger actualizaestadoconfechafinos;
ALTER TABLE persona enable trigger actualizarbarrastitulares;
ALTER TABLE persona enable trigger aepersona;
ALTER TABLE persona enable trigger ampersona;

  return true;

END;
$function$
