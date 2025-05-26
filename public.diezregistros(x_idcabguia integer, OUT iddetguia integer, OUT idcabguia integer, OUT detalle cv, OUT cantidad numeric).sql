CREATE OR REPLACE FUNCTION public.diezregistros(x_idcabguia integer, OUT iddetguia integer, OUT idcabguia integer, OUT detalle character varying, OUT cantidad numeric)
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$
DECLARE
r RECORD;
fila integer;
max integer;
BEGIN
   fila:=0;
   FOR r IN SELECT * FROM detguia  WHERE detguia.idcabguia = x_idcabguia LOOP
      fila:=fila+1;  
      idDetGuia = r.idDetGuia;
      idCabGuia = r.idCabGuia;
      Detalle = r.Detalle;
      cantidad = r.cantidad;
      RETURN NEXT;
   END LOOP;
   /* Aqui le agregamos el resto de registros y se coloca los valores que uno quiera*/
   max:=10-fila;
   FOR fila IN 1..max LOOP
      idDetGuia = NULL;
      idCabGuia = NULL;
      Detalle = NULL;
      cantidad = NULL;
      RETURN NEXT;
   END LOOP;
   /* FIN de le agregamos el resto de registros */
END;
$function$
