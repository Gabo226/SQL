--> 1.-Buscar el identificador de la factura mediante el folio que nos otorgo el usuario
	SELECT * FROM TBL_FACTURA
	WHERE CFACTURA LIKE '%17-20101%'

--> 2.-Buscar los materiales asociados a la factura los cuales también se tiene 
	--que dar de baja, mediaante el identificador de la factura
	SELECT * FROM TBL_FACTURA_MATERIAL
	WHERE NID_FACTURA=2675

--> 3.-Verificar que el costo y el tipo de moneda concuerde con lo solicitado
	SELECT * FROM CAT_MONEDAS

--> 4.-Verificar que el Proveedor sea el mismo que nos indico el usuario
	SELECT CPROVEEDOR FROM TBL_FACTURA TF
	INNER JOIN TBL_PEDIDOS  TP
	ON TF.NID_PEDIDO=TP.NID_PEDIDO
	INNER JOIN TBL_GRUPO_COTIZACIONES TGC
	ON TP.NID_GRUPO_COTIZACION=TGC.NID_GRUPO_COTIZACION
	INNER JOIN CAT_PROVEEDORES CP
	ON TGC. NID_PROVEEDOR=CP. NID_PROVEEDOR
	WHERE NID_FACTURA=2675
	
--> 5.-Si todos los datos concuerdan con los que solicitó el Usuario 
	-- se actualizan los campos de control

	UPDATE  TBL_FACTURA
	SET BHABILITADO=0, DFECHA_BAJA=GETDATE()
	WHERE NID_FACTURA = 2675

	UPDATE  TBL_FACTURA_MATERIAL
	SET BHABILITADO=0, DFECHA_BAJA=GETDATE()
	WHERE NID_FACTURA=2675
