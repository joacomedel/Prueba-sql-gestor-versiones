CREATE OR REPLACE FUNCTION public.cargarconsumorecetarioreciprocidad(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
   pnrorecetario alias for $1;
   pcentro alias for $2;
   idtipocuentacorriente INTEGER;
   importes RECORD;
   unrecetario RECORD;
   titureci RECORD;
   datoscuentacorriente RECORD;
   idcuentacorriente VARCHAR(50);





BEGIN
select into importes sum(importe) as importe,
			sum(importeAPagar) as importeAPagar,
			sum(ridebito) as ridebito
		from recetarioitem where recetarioitem.nrorecetario = pnrorecetario and
			recetarioitem.centro = pcentro;

select into unrecetario * from recetario natural join persona
		where recetario.nrorecetario=pnrorecetario and
		recetario.centro = pcentro;

IF unrecetario.barra >= 100 THEN --Corresponde a un afiliado por reciprocidad, corresponde que se imputa a la cta cte de la Obra social por reciprocidad
          IF  unrecetario.barra < 130 THEN --Corresponde a un afiliado de reciprocidad del benef, hay que buscar la barra del titu
             SELECT INTO titureci * FROM benefreci NATURAL JOIN persona WHERE benefreci.nrodoc = unrecetario.nrodoc AND persona.barra = unrecetario.barra;
             SELECT INTO datoscuentacorriente * FROM osreci WHERE osreci.barra = titureci.barratitu;
             IF FOUND THEN
                  idcuentacorriente = datoscuentacorriente.abreviatura;
                  idtipocuentacorriente = datoscuentacorriente.barra;
             END IF;
          ELSE --Corresponde a un afiliado de reciprocidad titular
             SELECT INTO datoscuentacorriente * FROM osreci WHERE osreci.barra = unrecetario.barra;
             IF FOUND THEN
                  idcuentacorriente = datoscuentacorriente.abreviatura;
                  idtipocuentacorriente = datoscuentacorriente.barra;
             END IF;
          END IF;

update consumorecetarioreciprocidad set importe=importes.importe, importeapagar=importes.importeapagar, debito=importes.importe - importes.importeapagar, abreviatura=idcuentacorriente, tipocuenta=idtipocuentacorriente, tipocomprobante=13 where nrorecetario = pnrorecetario and centro = pcentro;

if not FOUND then
    insert into consumorecetarioreciprocidad(nrorecetario, centro, importe, importeapagar, debito,   abreviatura, tipocuenta, tipocomprobante) 
values(pnrorecetario, pcentro, importes.importe, importes.importeapagar, importes.importe - importes.importeapagar, idcuentacorriente, idtipocuentacorriente,14);
end if;

perform asentarconsumorecetarioctacte(pnrorecetario, pcentro);
       END IF;
return 'true';
END;$function$
