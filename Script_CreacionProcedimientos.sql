USE DB_ARES 
GO
ALTER PROCEDURE [dbo].[SPD_CONSULTA_FECHA_SERVIDOR]
AS
SELECT CONVERT(VARCHAR(10),GETDATE(),120)

GO
ALTER PROCEDURE [dbo].[SPD_CONSULTA_FUNCIONARIO_X_UR]
(
@pnUnidadResponsable VARCHAR(150)
)
AS 
/*SET NOCOUNT ON*/
--Variables
DECLARE @vcMensaje VARCHAR (100)

  

/*Validar si es la unidad responsable corespondiente*/
IF EXISTS ( SELECT 1 FROM CAT_UNIDADES_RESPONSABLES AS CUR 
			INNER JOIN TBL_FUNCIONARIOS AS TF
			ON CUR.NID_UNIDAD_RESPONSABLE= TF.NID_UNIDAD_RESPONSABLE 
			WHERE CUR.NID_UNIDAD_RESPONSABLE= @pnUnidadResponsable  AND TF.BHABILITADO=1)
			
		BEGIN  
		/*validar si la homoclave es nula*/
			IF EXISTS (SELECT 1 FROM TBL_FUNCIONARIOS AS TF
			INNER JOIN TBL_PERSONAS AS TP
			ON TF.NID_PERSONA=TP.NID_PERSONA
			INNER JOIN CAT_UNIDADES_RESPONSABLES AS CUR
			ON TF.NID_UNIDAD_RESPONSABLE=CUR.NID_UNIDAD_RESPONSABLE
			WHERE TF.NID_UNIDAD_RESPONSABLE=@pnUnidadResponsable
			AND CHOMOCLAVE_RFC IS NOT NULL  AND TF.BHABILITADO=1)
				BEGIN 
				
					SELECT CAPELLIDO_PATERNO +' '+ CAPELLIDO_MATERNO +' '+ CNOMBRE AS NOMBRE, 
						CPUESTO AS PUESTO, 
						CASE 
							WHEN CTELEFONO IS NULL THEN 'Sin telefono'
							ELSE CTELEFONO 
						END  AS TELEFONO ,
						CASE
							WHEN CCORREO IS NULL THEN 'Sin correo electronico'  
							ELSE CCORREO 
						END  AS CORREO, 
						CRFC +' '+ CHOMOCLAVE_RFC AS RFC, 
						CASE 
							WHEN CCURP IS NULL THEN 'Sin CURP'
							ELSE CCURP  
						END AS CURP
						FROM TBL_FUNCIONARIOS AS TF
						INNER JOIN TBL_PERSONAS AS TP
						ON TF.NID_PERSONA=TP.NID_PERSONA
						INNER JOIN CAT_PUESTOS AS CP
						ON TF.NID_PUESTO=CP.NID_PUESTO
						INNER JOIN CAT_UNIDADES_RESPONSABLES AS CUR
						ON TF.NID_UNIDAD_RESPONSABLE=CUR.NID_UNIDAD_RESPONSABLE
						WHERE TF.NID_UNIDAD_RESPONSABLE=@pnUnidadResponsable AND TF.BHABILITADO=1
				 END	
			
			/*EN CASO DE QUE LA HOMOCLAVE SEA NULA */
			ELSE 
				BEGIN 
						SELECT  CAPELLIDO_PATERNO +' '+ CAPELLIDO_MATERNO +' '+ CNOMBRE  AS NOMBRE, 
						CPUESTO AS PUESTO, 
						CASE 
							WHEN CTELEFONO IS NULL THEN 'Sin telefono'
							ELSE CTELEFONO 
							END  AS TELEFONO ,
						CASE
							WHEN CCORREO  IS NULL THEN 'Sin correo electronico'  
							ELSE CCORREO  
						END  AS CORREO, 
						CASE 
							WHEN CRFC IS NULL THEN 'Sin RFC'
							ELSE CRFC 
						END AS RFC,	 
						CASE 
							WHEN CCURP IS NULL THEN 'Sin CURP'
							ELSE CCURP  
						END AS CURP
						FROM TBL_FUNCIONARIOS AS TF
						INNER JOIN TBL_PERSONAS AS TP
						ON TF.NID_PERSONA=TP.NID_PERSONA
						INNER JOIN CAT_PUESTOS AS CP
						ON TF.NID_PUESTO=CP.NID_PUESTO
						INNER JOIN CAT_UNIDADES_RESPONSABLES AS CUR
						ON TF.NID_UNIDAD_RESPONSABLE=CUR.NID_UNIDAD_RESPONSABLE
						WHERE CUR.NID_UNIDAD_RESPONSABLE=@pnUnidadResponsable AND TF.BHABILITADO=1	
						
				END
		END
	
ELSE
	BEGIN 
		SET @vcMensaje= 'No hay funcionario para esa dependencia' 
		SELECT @vcMensaje AS MENSAJE
	END
	
GO
ALTER PROCEDURE [dbo].[SPD_CONSULTA_UNIDADES_RESPONSABLES]
AS
/*SET NOCOUNT ON*/
SELECT  NID_UNIDAD_RESPONSABLE , CUNIDAD_RESPONSABLE
 FROM CAT_UNIDADES_RESPONSABLES  
 WHERE  NID_DEPENDENCIA_INSTITUCION= 229  
 AND BHABILITADO = 1
 ORDER BY CUNIDAD_RESPONSABLE/*MANDA TODAS LAS DEPENDENCIAS EXIXTENTES*/
 

GO
ALTER PROCEDURE [dbo].[SPD_LISTA_RFC_NUEVO_FUN]
(
	@pcRFC VARCHAR(10)
)
AS

SET  @pcRFC= RTRIM(@pcRFC) + '%'/* DEVUELVE UNA CADENA DE CARACTERES DESPUES DE TRUNCAR TODOS LOS ESPACIOS EN BLANCO FINALES*/

IF EXISTS (SELECT * FROM TBL_PERSONAS WHERE CRFC LIKE @pcRFC AND BHABILITADO=1)
	BEGIN
		SELECT 
			NID_PERSONA AS  ID_PERSONA, 
			CAPELLIDO_PATERNO + ' '+ ISNULL(CAPELLIDO_MATERNO,'') + ' '+ CNOMBRE AS NOMBRE_COMPLETO,
			CRFC AS RFC, 
			CHOMOCLAVE_RFC AS HOMOCLAVE, 
			CCURP AS CURP 
		FROM TBL_PERSONAS
		WHERE CRFC LIKE @pcRFC AND BHABILITADO=1
	END
ELSE
	BEGIN
		SELECT 'No hay RFC'
	END

GO
ALTER PROCEDURE [dbo].[SPD_ACTUALIZA_FUNCIONARIO]
(
	@pnIdPersona INT,--no permite nulos
	@pnIdUnidadResponsable INT, --no permite nulos
	@pnMensaje INT OUTPUT /*Si ocurre un error al insertar, la variable de salida @pnMensaje regresa un 0. Si todo se realizo bien regresa un número 1 */
)
AS

BEGIN TRANSACTION

DECLARE @vcGenero CHAR(1) 
DECLARE @pnIdPuesto INT
DECLARE @pcNumeroTrabajador VARCHAR(10)


SET @vcGenero = (SELECT TP.CGENERO FROM TBL_PERSONAS AS TP WHERE TP.NID_PERSONA = @pnIdPersona)

SET @pnIdPuesto = (SELECT NID_PUESTO FROM TBL_PUESTO_X_UR WHERE (CGENERO= @vcGenero OR CGENERO= 'A') AND NID_UNIDAD_RESPONSABLE=@pnIdUnidadResponsable) 

SET @pcNumeroTrabajador = (SELECT CASE WHEN CNUMERO_TRABAJADOR IS NULL THEN NULL
							ELSE CNUMERO_TRABAJADOR  END 
						   FROM TBL_ACADEMICOS WHERE NID_PERSONA = @pnIdPersona AND BHABILITADO = 1)

IF @pnIdPersona IS NULL 
	BEGIn --01
		SET @pnMensaje = 0
	END --01
ELSE 
	BEGIN --02
		IF @pnIdPuesto IS NULL
			BEGIN --03 
				SET @pnMensaje = 0
			END --03
		ELSE
			BEGIN --04
				IF @pnIdUnidadResponsable IS NULL
					BEGIN --06
						SET @pnMensaje = 0
					END --06
				ELSE
					BEGIN --07 ------------------------------------------------------------------------------------------------					
						IF EXISTS(SELECT NID_PERSONA FROM TBL_FUNCIONARIOS WHERE NID_PERSONA = @pnIdPersona AND BHABILITADO = 1)
							BEGIN --08
								UPDATE dbo.TBL_FUNCIONARIOS
								SET BHABILITADO = 0, DFECHA_BAJA = GETDATE()
								WHERE NID_PERSONA = @pnIdPersona
								IF @@ERROR <> 0
								BEGIN --09
									GOTO ERROR
								END --09
							END --08					
						UPDATE dbo.TBL_FUNCIONARIOS
						SET BHABILITADO = 0, DFECHA_BAJA = GETDATE()
						WHERE (NID_UNIDAD_RESPONSABLE = @pnIdUnidadResponsable AND BHABILITADO = 1)
					
						INSERT INTO dbo.TBL_FUNCIONARIOS(NID_PERSONA,NID_PUESTO,CNUMERO_TRABAJADOR,NID_UNIDAD_RESPONSABLE,BHABILITADO,DFECHA_ALTA)
						VALUES (@pnIdPersona,@pnIdPuesto,@pcNumeroTrabajador,@pnIdUnidadResponsable,1,GETDATE())
						IF @@ERROR <> 0
							BEGIN --05
								GOTO ERROR
							END --05	
						ELSE
							BEGIN --10
								SET @pnMensaje = 1
							END	--10			
					END --07 ------------------------------------------------------------------------------------------------						
			END --04
	END --02	

COMMIT TRANSACTION
RETURN
ERROR:
	BEGIN
		ROLLBACK TRANSACTION
		SET @pnMensaje = 0 
	END
	

GO

ALTER PROCEDURE [dbo].[SPD_INSERTA_NUEVO_FUNCIONARIO_UR]
(
	@pcRFC VARCHAR (10),--No acepta null [ARES]
	@pcHomoclaveRFC VARCHAR(3), 
	@pcCurp VARCHAR(18),
	@pcNombre VARCHAR (40), --No acepta null [ARES]
	@pcApellidoPaterno VARCHAR (40),--No acepta null [ARES]
	@pcApellidoMaterno VARCHAR (40),
	@pnIdTitulo INT,
	@pcFechaNacimiento VARCHAR(10),--no acepta null [ARES]
	@pcGenero CHAR(1),
	@pnIdUnidadResponsable INT, --no permite nulos [Funcionario]
	@pcMensajeErrores VARCHAR(200) OUTPUT,
	@pnIdPersonaNueva INT OUTPUT
)
AS 

BEGIN TRANSACTION

DECLARE @@vcIdPersona VARCHAR (200) -- Variable de salida de SPD_INSERTA_PERSONA_ARES
DECLARE @@vcPersonaExiste VARCHAR(200) -- Variable de salida de SPD_INSERTA_PERSONA_ARES
DECLARE @@vnMensaje INT --Variable de salida de SPD_ACTUALIZA_FUNCIONARIO
DECLARE @@vnIdPersona INT -- Variable que guarda el ID de la persona que regresa SPD_INSERTA_PERSONA_ARES si se inserto exitosamente
DECLARE @@vnIdPuesto INT -- Variable para guardar el ID del puesto del funcionario
DECLARE @@vnContadorRFC INT

IF @pcRFC IS NULL
BEGIN --01
	SET @pcMensajeErrores = 'El RFC es Obligatorio'
END--01
ELSE
BEGIN --02
	IF @pcNombre IS NULL
	BEGIN--03
		SET @pcMensajeErrores = 'El Nombre es Obligatorio'
	END--03
	ELSE
	BEGIN--04
		IF @pcApellidoPaterno IS NULL
		BEGIN--05
			SET @pcMensajeErrores = 'El Apellido paterno es Obligatorio'
		END--05
		ELSE
		BEGIN--06
			IF @pcFechaNacimiento IS NULL
			BEGIN--08
				SET @pcMensajeErrores = 'La fecha de nacimiento es obligatoria'
			END--08
			ELSE
			BEGIN--09
				IF @pnIdUnidadResponsable IS NULL
				BEGIN--10
					SET @pcMensajeErrores = 'La unidad responsable es obligatoria'
				END--10
				ELSE
				BEGIN--11-------------------------------------------------------------
					EXEC SPD_INSERTA_PERSONA_ARES
						@pcRFC,
						@pcHomoclaveRFC, 
						@pcCurp, 
						@pcNombre,
						@pcApellidoPaterno,
						@pcApellidoMaterno,
						@pnIdTitulo,
						@pcFechaNacimiento,
						@pcGenero,
						NULL,--Telefono
						NULL,--TelefonoOficina
						NULL,--Extension
						NULL,--TelefonoCelular
						NULL,--Fax 
						NULL,--LugarNacimiento
						NULL,--CorreoElectronico
						NULL,--IdEstadoCivil 
						20,--IDNacionalidad, 20 es mexicano
						NULL,--IdSituaccionMigratoria
						NULL,--IdPaisNacimiento
						NULL,--IdentificadorExtranjero
						NULL,--FOTO
						@@vcIdPersona  OUTPUT,
						@@vcPersonaExiste OUTPUT
						
					IF @@vcIdPersona = 'Ocurrio un error al insertar a la persona' OR @@vcIdPersona = 'Ocurrio un error al actualizar a la persona'
					--Si ocurrio un error de transacción en SPD_INSERTA_PERSONA_ARES
					BEGIN--20
						SET @pcMensajeErrores = @@vcIdPersona
						SET @pnIdPersonaNueva = 0
						GOTO ERROR
					END--20
					ELSE
					BEGIN--21
						IF ISNUMERIC(@@vcIdPersona)=1 AND @@vcPersonaExiste IS NULL 
						--Cuando se ingreso correctamente a la persona.
						BEGIN--12
							SET @@vnIdPersona = CAST( @@vcIdPersona AS INT)
							SET @@vnIdPuesto= (SELECT NID_PUESTO FROM TBL_PUESTO_X_UR WHERE (CGENERO= @pcGenero OR CGENERO= 'A') AND NID_UNIDAD_RESPONSABLE=@pnIdUnidadResponsable)--***
						
							EXEC SPD_ACTUALIZA_FUNCIONARIO 
								@@vnIdPersona,
								@pnIdUnidadResponsable,
								@@vnMensaje OUTPUT
						
							IF @@vnMensaje = 1
							--Cuando si inserto correctamente al funcionario
							BEGIN--13
								SET @pcMensajeErrores = 'Se inserto exitosamente al nuevo funcionario'
								SET @pnIdPersonaNueva = 1
							END--13
							ELSE
							BEGIN--14
							--Cuando no se inserto correctamente al funcionario.
								SET @pcMensajeErrores = 'Error: No se ingreso correctamente al funcionario' 
								SET @pnIdPersonaNueva = 0
								GOTO ERROR
							END--14
						END--12
						ELSE
						BEGIN--15
							SET @@vnContadorRFC = (SELECT COUNT(CRFC) FROM TBL_PERSONAS WHERE CRFC=@pcRFC  GROUP BY CRFC)
							IF @@vnContadorRFC>1
								BEGIN--V1
									IF EXISTS (SELECT TP.NID_PERSONA FROM TBL_PERSONAS AS TP WHERE TP.CRFC=@pcRFC AND TP.CNOMBRE = @pcNombre AND TP.CAPELLIDO_PATERNO = @pcApellidoPaterno AND TP.CHOMOCLAVE_RFC IS NULL)
									BEGIN --V2
										SET @pnIdPersonaNueva = (SELECT TP.NID_PERSONA FROM TBL_PERSONAS AS TP WHERE TP.CRFC=@pcRFC AND TP.CNOMBRE = @pcNombre AND TP.CAPELLIDO_PATERNO = @pcApellidoPaterno AND TP.CHOMOCLAVE_RFC IS NULL)
									END --V2
									ELSE
									BEGIN--V3
										IF EXISTS (SELECT TP.NID_PERSONA FROM TBL_PERSONAS AS TP WHERE TP.CRFC=@pcRFC AND TP.CNOMBRE = @pcNombre AND TP.CAPELLIDO_PATERNO = @pcApellidoPaterno AND TP.CHOMOCLAVE_RFC = @pcHomoclaveRFC)
										BEGIN--V4
											SET @pnIdPersonaNueva = (SELECT TP.NID_PERSONA FROM TBL_PERSONAS AS TP WHERE TP.CRFC=@pcRFC AND TP.CNOMBRE = @pcNombre AND TP.CAPELLIDO_PATERNO = @pcApellidoPaterno AND TP.CHOMOCLAVE_RFC = @pcHomoclaveRFC)
										END--V4
										ELSE
										BEGIN--V5
											SET @pnIdPersonaNueva = 0
										END--V5
									END--V3
								END--V1
							ELSE
								BEGIN--V2
									SET @pnIdPersonaNueva = (SELECT TP.NID_PERSONA FROM TBL_PERSONAS AS TP WHERE TP.CRFC=@pcRFC)
								END--V2
							IF @@vcIdPersona IS NULL AND @@vcPersonaExiste IS NULL 
							--Cuando se inserta a una persona con el mismo RFC, sin la homoclave
							BEGIN--17
								SET @pcMensajeErrores = 'Ya existe una persona con el mismo RFC.'
							END--17
							ELSE
							BEGIN--18
								IF ISNUMERIC(@@vcIdPersona)=1 AND @@vcPersonaExiste IS NOT NULL
								BEGIN--19
									SET @pcMensajeErrores = 'Ya existe una persona con el mismo RFC y nombre.'
								END--19
								ELSE
								BEGIN--22
									SET @pcMensajeErrores = @@vcIdPersona
								END--22
							END--18
						END--15
					END--21
				END--11---------------------------------------------------------------
			END--09
		END--06
	END--04
END--02

COMMIT TRANSACTION
RETURN

ERROR:
	BEGIN
		ROLLBACK TRANSACTION
	END

GO

ALTER PROCEDURE [dbo].[SPD_CONSULTA_CARGO_FUNCIONARIO]
(
	@pnIdPersona INT,
	@pnIdDependencia INT 
)
AS
DECLARE @@vcGENERO CHAR(1)

IF @pnIdPersona IS NULL
	BEGIN --001
	   SELECT 'El id_persona es obligatorio'
	END --001
ELSE 
	BEGIN --002
		IF @pnIdDependencia IS NULL 
			BEGIN --003
				SELECT 'El Identidicador de la dependencia es obligatoria'
			END--003
		
		ELSE 
			BEGIN--004 
						
						IF EXISTS( SELECT 1 FROM TBL_PERSONAS WHERE NID_PERSONA =@pnIdPersona)
							BEGIN--01
								SET @@vcGENERO= (	SELECT CGENERO FROM TBL_PERSONAS 
								WHERE NID_PERSONA =@pnIdPersona)
									
								--IF @pnIdPersona IS NULL
								--	BEGIN
								--		SELECT CA.NID_PUESTO AS NIDCARGO, CA.CPUESTO AS CCARGO
								--		FROM TBL_PUESTO_X_UR AS TPXU
								--		INNER JOIN CAT_PUESTOS AS CA
								--		ON CA.NID_PUESTO= TPXU.NID_PUESTO
								--		INNER JOIN CAT_UNIDADES_RESPONSABLES AS CUR
								--		ON TPXU.NID_UNIDAD_RESPONSABLE= CUR.NID_UNIDAD_RESPONSABLE
								--		WHERE TPXU.BHABILITADO=1 
								--		AND TPXU.NID_UNIDAD_RESPONSABLE= @pnIdDependencia
								--		END
								--ELSE
									BEGIN
										SELECT CA.NID_PUESTO AS NIDCARGO, CA.CPUESTO AS CCARGO
										FROM TBL_PUESTO_X_UR AS TPXU
										INNER JOIN CAT_PUESTOS AS CA
										ON CA.NID_PUESTO= TPXU.NID_PUESTO
										INNER JOIN CAT_UNIDADES_RESPONSABLES AS CUR
										ON TPXU.NID_UNIDAD_RESPONSABLE= CUR.NID_UNIDAD_RESPONSABLE
										WHERE (TPXU.CGENERO=@@vcGENERO OR TPXU.CGENERO= 'A') AND TPXU.BHABILITADO=1 
										AND TPXU.NID_UNIDAD_RESPONSABLE= @pnIdDependencia
										END	
								
								
	
							END--01
							
							ELSE 
							
								BEGIN--02
							
									SELECT 'La persona no se encuentra registrada'
								
								END--02
					
				
			END	--004	
		
	END --002

GO

ALTER PROCEDURE [dbo].[SPD_CONSULTA_CARGO_ANTERIOR]
(@pnIdPersonas int)

As
Begin



IF EXISTS (SELECT 1 FROM TBL_FUNCIONARIOS 
		   WHERE NID_PERSONA = @pnIdPersonas AND BHABILITADO = 1)
	BEGIN
		Select 1
	End
ELSE 
	BEGIN 
	SELECT 0 
	END

END 


GO
ALTER PROCEDURE [dbo].[SPD_CONSULTA_TITULOS]
AS
SELECT CT.NID_TITULO, CT.CDESCRIPCION_LARGA 
FROM CAT_TITULOS AS CT
WHERE CT.NID_TITULO <> 0



--------------

GRANT EXECUTE ON SPD_CONSULTA_FUNCIONARIO_X_UR TO ROL_CATALOGOS
go
GRANT EXECUTE ON SPD_CONSULTA_UNIDADES_RESPONSABLES TO ROL_CATALOGOS
GO
GRANT EXECUTE ON [SPD_LISTA_RFC_NUEVO_FUN] TO ROL_CATALOGOS
GO
GRANT EXECUTE ON [SPD_ACTUALIZA_FUNCIONARIO] TO ROL_CATALOGOS
GO
GRANT EXECUTE ON [SPD_INSERTA_NUEVO_FUNCIONARIO_UR] TO ROL_CATALOGOS
GO
GRANT EXECUTE ON [SPD_CONSULTA_CARGO_FUNCIONARIO] TO ROL_CATALOGOS
GO
GRANT EXECUTE ON [SPD_CONSULTA_CARGO_ANTERIOR] TO ROL_CATALOGOS
GO
GRANT EXECUTE ON [SPD_CONSULTA_TITULOS] TO ROL_CATALOGOS
GO
GRANT EXECUTE ON SPD_CONSULTA_FECHA_SERVIDOR TO ROL_CATALOGOS
GO
