CREATE OR REPLACE FUNCTION public.arreglarsecfarma()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


	

BEGIN

SELECT setval('far_ordenventa_idordenventa_seq', (SELECT MAX(idordenventa)+1 FROM far_ordenventa where idcentroordenventa=99));
SELECT setval('far_ordenventaestado_idordenventaestado_seq', (SELECT MAX(idordenventaestado)+1 FROM far_ordenventaestado where idcentroordenventaestado=99));
 
SELECT setval('far_ordenventaitem_idordenventaitem_seq', (SELECT MAX(idordenventaitem)+1 FROM far_ordenventaitem where idcentroordenventaitem=99));
 
SELECT setval('far_ordenventaitemestado_idordenventaitemaestado_seq', (SELECT MAX(idordenventaitemaestado)+1 FROM far_ordenventaitemestado where idcentroordenventaitemestado=99));
 
SELECT setval('far_ordenventaitemimportes_idordenventaitemimporte_seq', (SELECT MAX(idordenventaitemimporte)+1 FROM far_ordenventaitemimportes where idcentroordenventaitemimporte =99));
 
SELECT setval('far_ordenventaitemimportesest_idordenventaitemimportesaesta_seq', (SELECT MAX(idordenventaitemimportesaestado)+1 FROM far_ordenventaitemimportesestado where idcentroordenventaitemimportesestado =99));

SELECT setval('far_ordenventareceta_idordenventaprofesional_seq', (SELECT MAX(idordenventaprofesional)+1 FROM far_ordenventareceta where idcentroordenventaprofesion=99));
 

SELECT setval('far_oviiformapago_idoviiformapago_seq', (SELECT MAX(idoviiformapago)+1 FROM far_oviiformapago where idcentrooviiformapago=99));


SELECT setval('far_validacionitemsestado_idvalidacionitemsestado_seq',(SELECT MAX(idvalidacionitemsestado)+1 FROM far_validacionitemsestado where idcentrovalidacionitemsestado=99));

SELECT setval('far_validacionitems_idvalidacionitem_seq', (SELECT MAX(idvalidacionitem)+1 FROM far_validacionitems where idcentrovalidacionitem=99));
SELECT setval('far_validacionxml_idvalidacionxml_seq', (SELECT MAX(idvalidacionxml)+1 FROM far_validacionxml where idcentrovalidacionxml=99));


SELECT setval('far_movimientostock_idmovimientostock_seq', (SELECT MAX(idmovimientostock)+1 FROM far_movimientostock where idcentromovimientostock=99));
SELECT setval('far_movimientostockitem_idmovimientostockitem_seq', (SELECT MAX(idmovimientostockitem)+1 FROM far_movimientostockitem where idcentromovimientostockitem=99));

SELECT setval('far_stockajuste_idstockajuste_seq', (SELECT MAX(idstockajuste)+1 FROM far_stockajuste where idcentrostockajuste=99));
SELECT setval('far_precargastockajusteitem_idprecargastockajusteitem_seq', (SELECT MAX(idprecargastockajusteitem)+1 FROM far_precargastockajusteitem where idcentroprecargastockajusteitem=99));
 
SELECT setval('far_stockajusteestado_idstockajusteestado_seq', (SELECT MAX(idstockajusteestado)+1 FROM far_stockajusteestado where idcentrostockajuste=99));

SELECT setval('far_stockajusteitem_idstockajusteitem_seq', (SELECT MAX(idstockajusteitem)+1 FROM far_stockajusteitem where idcentrostockajusteitem =99));

SELECT setval('far_stockajusteiteminformado_idstockajusteiteminformado_seq', (SELECT MAX(idstockajusteiteminformado)+1 FROM far_stockajusteiteminformado where idcentrostockajusteiteminformado=99));


SELECT setval('far_stockajusteremito_idstockajuste_seq', (SELECT MAX(idstockajuste)+1 FROM far_stockajusteremito where idcentrostockajuste=99));


SELECT setval('idcontrolcaja_seq', (SELECT MAX(idcontrolcaja)+1 FROM controlcaja where idcentrocontrolcaja=99));
SELECT setval('idcontrolcajaestado_seq', (SELECT MAX(idcontrolcajaestado)+1 FROM controlcajaestado where idcentrocontrolcajaestado=99));
SELECT setval('idcontrolcajafacturaventa_seq', (SELECT MAX(idcontrolcajafacturaventa)+1 FROM controlcajafacturaventa where idcentrocontrolcaja=99));


SELECT setval('ingresosusuarios_idsesion_seq', (SELECT MAX(idsesion)+1 FROM ingresosusuarios where idcentroregional=99));

return 'true';
end;
$function$
