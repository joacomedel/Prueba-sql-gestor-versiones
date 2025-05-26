CREATE OR REPLACE FUNCTION public.actualizardireccion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

	direcciones refcursor;
	

    dir RECORD;

	unadireccion RECORD;
	
	lala RECORD;
	resultado boolean;
	indice bigint;
BEGIN

indice=1;

/*Eliminacion de tabla como sincronizables*/
              SELECT into lala * FROM eliminartablasincronizable('direccion');
              SELECT into lala * FROM eliminartablasincronizable('persona');
              SELECT into lala * FROM eliminartablasincronizable('cliente');

/* Modificacion de la tabla direccion*/
         ALTER TABLE "public"."direccion"
               DROP CONSTRAINT "clavedireccion" CASCADE;

         ALTER TABLE "public"."direccion"
               ADD COLUMN "idcentrodireccion" INTEGER;

         ALTER TABLE "public"."direccion"
               ALTER COLUMN "idcentrodireccion" SET DEFAULT centro();

          UPDATE direccion SET idcentrodireccion = 1;

          ALTER TABLE "public"."direccion"
                ADD CONSTRAINT "clavedireccion"
                 PRIMARY KEY ("iddireccion", "idcentrodireccion");

        /*  ALTER TABLE "public"."direccion"
                ADD COLUMN "auxiddireccion" SERIAL;*/

/* Modificacion tablas que referencian a direccion*/
           ALTER TABLE "public"."persona"
                      ADD COLUMN "idcentrodireccion" INTEGER;

           ALTER TABLE "public"."persona"
                 ADD CONSTRAINT "clavedireccion" FOREIGN KEY (iddireccion,idcentrodireccion)
                   REFERENCES "public"."direccion"(iddireccion,idcentrodireccion)
                   ON DELETE CASCADE
                   ON UPDATE CASCADE
                   NOT DEFERRABLE;
           
           ALTER TABLE "public"."cliente"
                 ADD COLUMN "idcentrodireccion" INTEGER;

          ALTER TABLE "public"."turismounidad"
                 ADD COLUMN "idcentrodireccion" INTEGER ;

           ALTER TABLE "public"."centroregional"
                 ADD COLUMN "idcentrodireccion" INTEGER;
                 
           ALTER TABLE "public"."osreci"
                 ADD COLUMN "idcentrodireccion" INTEGER;
                 
                 
            ALTER TABLE "public"."depuniversitaria"
                 ADD COLUMN "idcentrodireccion" INTEGER;

            ALTER TABLE "public"."afiliado"
                 ADD COLUMN "idcentrodireccion" INTEGER;
                 
            ALTER TABLE "public"."convenio"
                 ADD COLUMN "idcentrodireccion" INTEGER;

            ALTER TABLE "public"."tempconvenio"
                 ADD COLUMN "idcentrodireccion" INTEGER;
         
            ALTER TABLE "public"."temppersona"
                 ADD COLUMN "idcentrodireccion" INTEGER;
                 
            ALTER TABLE "public"."temporalpersona"
                 ADD COLUMN "idcentrodireccion" INTEGER;




           ALTER TABLE "public"."depuniversitaria"
                 ADD CONSTRAINT "clavedireccion" FOREIGN KEY (iddireccion,idcentrodireccion)
                 REFERENCES "public"."direccion"(iddireccion,idcentrodireccion)
                 ON DELETE CASCADE
                 ON UPDATE CASCADE
                 NOT DEFERRABLE;
                 
/*Actualiza la tabla turimos unidad*/
ALTER TABLE "public"."turismounidad"
  ADD COLUMN "auxdireccion" BIGINT;

UPDATE turismounidad set auxdireccion = iddireccion::BIGINT;

ALTER TABLE "public"."turismounidad"
  DROP COLUMN "iddireccion";

ALTER TABLE "public"."turismounidad"
  RENAME COLUMN "auxdireccion" TO "iddireccion";

/*Agregar como tabla sincronizables*/

SELECT into lala * FROM agregarsincronizable('persona');
SELECT into lala * FROM agregarsincronizable('direccion');
SELECT into lala * FROM agregarsincronizable('cliente');


open direcciones FOR SELECT * FROM direccion  order by iddireccion asc ;
FETCH direcciones into unadireccion;


    WHILE  found LOOP    	
	       --SELECT into dir * FROM direccion where iddireccion=indice;
	       --if not found then
	              --indice = unadireccion.auxiddireccion;
                  UPDATE direccion SET iddireccion=indice , idcentrodireccion=1 WHERE  direccion.iddireccion=unadireccion.iddireccion ;
                  update persona set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update depuniversitaria set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update cliente set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update turismounidad set iddireccion=indice, idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update centroregional set iddireccion=indice, idcentrodireccion=1 where iddireccion=unadireccion.iddireccion ;
                  update osreci set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update afiliado set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update convenio set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update depuniversitaria set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update tempconvenio set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update temporalpersona set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;
                  update temppersona set iddireccion=indice,idcentrodireccion=1  where iddireccion=unadireccion.iddireccion ;

                  FETCH direcciones into unadireccion;
             --end if;
             indice=indice+1;
      END LOOP;

  return resultado;

END;
$function$
