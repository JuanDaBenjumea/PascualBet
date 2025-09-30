create database DB_PascualBet
use DB_PascualBet

--Bloque para eliminar base de datos
use master
drop database DB_PascualBet

-- ======================
-- TABLA CUENTA USUARIO 
-- ======================
CREATE TABLE CuentaUsuario (
    id_usuario VARCHAR(50) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    contraseña VARCHAR(255) NOT NULL,
    saldo_actual DECIMAL(12,2) DEFAULT 0,
    rol VARCHAR(20) DEFAULT 'Usuario',
    fecha_nacimiento DATETIME,
    fecha_registro DATETIME DEFAULT GETDATE()
);

-- ======================
-- TABLA JUEGO
-- ======================
CREATE TABLE Juego (
    id_juego INT PRIMARY KEY IDENTITY(1,1),
    nombre_juego VARCHAR(100) NOT NULL,
    tipo_juego VARCHAR(50) NOT NULL,
    estado VARCHAR(20) NOT NULL
);

-- ======================
-- TABLA APUESTA (con CASCADE)
-- ======================
CREATE TABLE Apuesta (
    id_sesion INT PRIMARY KEY IDENTITY(1,1),
    id_usuario VARCHAR(50) NOT NULL,
    id_juego INT NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NULL,
    resultado VARCHAR(50) NULL,
    monto DECIMAL(12,2) NOT NULL,
    CONSTRAINT FK_Apuesta_Usuario 
        FOREIGN KEY (id_usuario) REFERENCES CuentaUsuario(id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_Apuesta_Juego 
        FOREIGN KEY (id_juego) REFERENCES Juego(id_juego)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ======================
-- TABLA TRANSACCION (con CASCADE)
-- ======================
CREATE TABLE Transaccion (
    id_transaccion INT PRIMARY KEY IDENTITY(1,1),
    id_usuario VARCHAR(50) NOT NULL,
    tipo_transaccion VARCHAR(50) NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_transaccion DATETIME DEFAULT GETDATE(),
    banco VARCHAR(80),
    cuenta_cliente VARCHAR(16),
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT FK_Transaccion_Usuario 
        FOREIGN KEY (id_usuario) REFERENCES CuentaUsuario(id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ======================
-- TABLA HISTORIAL SESSION (con CASCADE)
-- ======================
CREATE TABLE HistorialSession (
    id_actividad INT PRIMARY KEY IDENTITY(1,1),
    id_usuario VARCHAR(50) NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME,
    CONSTRAINT FK_HistorialSession_Usuario 
        FOREIGN KEY (id_usuario) REFERENCES CuentaUsuario(id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ======================
-- TABLA BONIFICACION (con CASCADE)
-- ======================
CREATE TABLE Bonificacion (
    id_bonificacion INT PRIMARY KEY IDENTITY(1,1),
    id_usuario VARCHAR(50) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255),
    monto DECIMAL(12,2) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    fecha DATE NOT NULL,
    CONSTRAINT FK_Bonificacion_Usuario 
        FOREIGN KEY (id_usuario) REFERENCES CuentaUsuario(id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE
);


-- ======================
-- SUPER ADMIN TEXTO PLANO PARA PRUEBAS
-- ======================
INSERT INTO CuentaUsuario (id_usuario,nombre, contraseña, rol, saldo_actual, fecha_nacimiento)
VALUES ('admin','andres', 'admin123', 'ADMIN', 999999.99,'2004-10-04' );

select * from CuentaUsuario
select * from Transaccion
---PROCEDIMIENTOS ALMACENADOS
USE DB_PascualBet;
GO

/* ============================
   TRIGGER: BLOQUEA MENORES 18
   ============================ */
IF OBJECT_ID('dbo.trg_CuentaUsuario_BloqueaMenores','TR') IS NOT NULL
  DROP TRIGGER dbo.trg_CuentaUsuario_BloqueaMenores;
GO
CREATE TRIGGER dbo.trg_CuentaUsuario_BloqueaMenores
ON dbo.CuentaUsuario
AFTER INSERT, UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (
    SELECT 1
    FROM inserted
    WHERE fecha_nacimiento IS NULL
       OR DATEADD(YEAR,18,fecha_nacimiento) > SYSDATETIME()
  )
  BEGIN
    RAISERROR('El usuario debe ser mayor de 18 años (fecha_nacimiento invalida).',16,1);
    ROLLBACK TRANSACTION;
    RETURN;
  END
END
GO

/* =========================================
   SP: CREAR USUARIO (con validacion edad)
   ========================================= */
IF OBJECT_ID('dbo.usp_CuentaUsuario_Crear','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_CuentaUsuario_Crear;
GO

CREATE PROCEDURE dbo.usp_CuentaUsuario_Crear
  @id_usuario       VARCHAR(50),
  @nombre			VARCHAR(150),
  @contrasena       VARCHAR(255),      -- Recomendado: hash (bcrypt) generado en el backend
  @fecha_nacimiento DATE,
  @rol              VARCHAR(20) = NULL -- Opcional (si no se env�a, usa DEFAULT 'Usuario')
AS
BEGIN
  SET NOCOUNT ON;

  -- Validaciones b�sicas
  IF @id_usuario IS NULL OR LTRIM(RTRIM(@id_usuario)) = ''
    THROW 50010, 'id_usuario es requerido', 1;

	IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    THROW 50010, 'nombre es requerido', 1;

  IF @contrasena IS NULL OR LEN(@contrasena) = 0
    THROW 50011, 'contrase�a es requerida', 1;

  IF @fecha_nacimiento IS NULL
    THROW 50012, 'fecha_nacimiento es requerida', 1;

  -- Mayor de 18 a�os
  IF DATEADD(YEAR, 18, @fecha_nacimiento) > SYSDATETIME()
    THROW 50013, 'El usuario debe ser mayor de 18 a�os', 1;

  -- No duplicado
  IF EXISTS (SELECT 1 FROM dbo.CuentaUsuario WHERE id_usuario = @id_usuario)
    THROW 50014, 'El usuario ya existe', 1;

  -- Insert (deja que apliquen DEFAULTs: rol, saldo_actual, fecha_registro)
  IF @rol IS NULL
    INSERT INTO dbo.CuentaUsuario (id_usuario, nombre, [contraseña], fecha_nacimiento)
    VALUES (@id_usuario,@nombre, @contrasena, @fecha_nacimiento);
  ELSE
    INSERT INTO dbo.CuentaUsuario (id_usuario, nombre , [contraseña], fecha_nacimiento, rol)
    VALUES (@id_usuario,@nombre, @contrasena, @fecha_nacimiento, @rol);
END
GO

GO
CREATE PROCEDURE dbo.usp_CuentaUsuario_Login_GetHash
  @id_usuario VARCHAR(50),
  @nombre	  VARCHAR(150)   OUTPUT,
  @hash       VARCHAR(255)   OUTPUT,  -- contrase�a almacenada (p.ej. bcrypt)
  @rol        VARCHAR(20)    OUTPUT,
  @saldo      DECIMAL(12,2)  OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
	@nombre= nombre, 
    @hash  = [contraseña],
    @rol   = rol,
    @saldo = saldo_actual
  FROM dbo.CuentaUsuario
  WHERE id_usuario = @id_usuario;

  IF @hash IS NULL
    THROW 50020, 'Usuario no existe', 1;
END
GO

/* ==========================================================
   SP: LOGIN PLAIN (solo para pruebas si guardas texto plano)
   ========================================================== */
IF OBJECT_ID('dbo.usp_CuentaUsuario_Login_Plain','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_CuentaUsuario_Login_Plain;
GO
CREATE PROCEDURE dbo.usp_CuentaUsuario_Login_Plain
  @id_usuario  VARCHAR(50),
  @nombre	  VARCHAR(150) OUTPUT,
  @contrasena  VARCHAR(255),
  @login_ok    BIT           OUTPUT,
  @rol         VARCHAR(20)   OUTPUT,
  @saldo       DECIMAL(12,2) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @stored VARCHAR(255);

  SELECT TOP 1
	@nombre = nombre,
    @stored = [contraseña],
    @rol    = rol,
    @saldo  = saldo_actual
  FROM dbo.CuentaUsuario
  WHERE id_usuario = @id_usuario;

  IF @stored IS NULL
  BEGIN
    SET @login_ok = 0;
    RETURN;
  END

  SET @login_ok = CASE WHEN @stored = @contrasena THEN 1 ELSE 0 END;
END
GO


/* ===========================================
   SP: ACTUALIZAR PERFIL DE USUARIO
   =========================================== */
IF OBJECT_ID('dbo.usp_CuentaUsuario_ActualizarPerfil','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_CuentaUsuario_ActualizarPerfil;
GO
CREATE PROCEDURE dbo.usp_CuentaUsuario_ActualizarPerfil
  @id_usuario       VARCHAR(50),
  @nombre           VARCHAR(150) = NULL,
  @nueva_contrasena VARCHAR(255) = NULL,
  @fecha_nacimiento DATETIME = NULL
AS
BEGIN
  SET NOCOUNT ON;
  
  -- Verificar que el usuario existe
  IF NOT EXISTS (SELECT 1 FROM dbo.CuentaUsuario WHERE id_usuario = @id_usuario)
    THROW 50030, 'Usuario no existe', 1;
  
  -- Si se proporciona fecha de nacimiento, validar edad
  IF @fecha_nacimiento IS NOT NULL AND DATEADD(YEAR, 18, @fecha_nacimiento) > SYSDATETIME()
    THROW 50031, 'El usuario debe ser mayor de 18 años', 1;
  
  -- Actualizar solo los campos que no sean NULL
  UPDATE dbo.CuentaUsuario 
  SET 
    nombre = ISNULL(@nombre, nombre),
    [contraseña] = ISNULL(@nueva_contrasena, [contraseña]),
    fecha_nacimiento = ISNULL(@fecha_nacimiento, fecha_nacimiento)
  WHERE id_usuario = @id_usuario;
  
  SELECT 'Perfil actualizado exitosamente' AS Mensaje;
END
GO

/* ===========================================
   SP: ACTUALIZAR SALDO
   =========================================== */
IF OBJECT_ID('dbo.usp_CuentaUsuario_ActualizarSaldo','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_CuentaUsuario_ActualizarSaldo;
GO
CREATE PROCEDURE dbo.usp_CuentaUsuario_ActualizarSaldo
  @id_usuario    VARCHAR(50),
  @nuevo_saldo   DECIMAL(12,2),
  @permitir_negativo BIT = 0  -- Por defecto no permite saldo negativo
AS
BEGIN
  SET NOCOUNT ON;
  
  -- Verificar que el usuario existe
  IF NOT EXISTS (SELECT 1 FROM dbo.CuentaUsuario WHERE id_usuario = @id_usuario)
    THROW 50040, 'Usuario no existe', 1;
  
  -- Validar saldo negativo si no está permitido
  IF @permitir_negativo = 0 AND @nuevo_saldo < 0
    THROW 50041, 'No se permite saldo negativo', 1;
  
  -- Actualizar saldo
  UPDATE dbo.CuentaUsuario 
  SET saldo_actual = @nuevo_saldo
  WHERE id_usuario = @id_usuario;
  
  SELECT 'Saldo actualizado exitosamente' AS Mensaje, @nuevo_saldo AS NuevoSaldo;
END
GO

/* ===========================================
   SP: OBTENER INFORMACIÓN DE USUARIO
   =========================================== */
IF OBJECT_ID('dbo.usp_CuentaUsuario_ObtenerInfo','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_CuentaUsuario_ObtenerInfo;
GO
CREATE PROCEDURE dbo.usp_CuentaUsuario_ObtenerInfo
  @id_usuario VARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  
  SELECT 
    id_usuario,
    nombre,
    saldo_actual,
    rol,
    fecha_nacimiento,
    fecha_registro,
    DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) AS edad
  FROM dbo.CuentaUsuario
  WHERE id_usuario = @id_usuario;
  
  IF @@ROWCOUNT = 0
    THROW 50050, 'Usuario no encontrado', 1;
END
GO



/* ========================================================================
   PROCEDIMIENTO: MODIFICAR ID_USUARIO
   ======================================================================== */
IF OBJECT_ID('dbo.usp_CuentaUsuario_ModificarID','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_CuentaUsuario_ModificarID;
GO

CREATE PROCEDURE dbo.usp_CuentaUsuario_ModificarID
  @id_usuario_actual VARCHAR(50),
  @id_usuario_nuevo  VARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRANSACTION;
  
  BEGIN TRY
    -- Validar que el usuario actual existe
    IF NOT EXISTS (SELECT 1 FROM dbo.CuentaUsuario WHERE id_usuario = @id_usuario_actual)
      THROW 50100, 'El usuario actual no existe', 1;
    
    -- Validar que el nuevo ID no existe
    IF EXISTS (SELECT 1 FROM dbo.CuentaUsuario WHERE id_usuario = @id_usuario_nuevo)
      THROW 50101, 'El nuevo ID de usuario ya existe', 1;
    
    -- Validar que el nuevo ID no esté vacío
    IF @id_usuario_nuevo IS NULL OR LTRIM(RTRIM(@id_usuario_nuevo)) = ''
      THROW 50102, 'El nuevo ID no puede estar vacío', 1;
    
    -- Actualizar el ID (CASCADE actualizará automáticamente las tablas relacionadas)
    UPDATE dbo.CuentaUsuario 
    SET id_usuario = @id_usuario_nuevo
    WHERE id_usuario = @id_usuario_actual;
    
    COMMIT TRANSACTION;
    SELECT 'ID de usuario actualizado exitosamente. Todas las relaciones fueron actualizadas.' AS Mensaje;
  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END
GO

/* ========================================================================
   PROCEDIMIENTO: CREAR TRANSACCIÓN (con validación de saldo)
   ======================================================================== */
IF OBJECT_ID('dbo.usp_Transaccion_Crear','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Transaccion_Crear;
GO

CREATE PROCEDURE dbo.usp_Transaccion_Crear
  @id_usuario        VARCHAR(50),
  @tipo_transaccion  VARCHAR(50),     -- 'DEPOSITO', 'RETIRO', 'GANANCIA', 'PERDIDA'
  @monto             DECIMAL(12,2),
  @banco             VARCHAR(80) = NULL,
  @cuenta_cliente    VARCHAR(16) = NULL,
  @estado            VARCHAR(20) = 'APROBADO'
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRANSACTION;
  
  BEGIN TRY
    DECLARE @saldo_actual DECIMAL(12,2);
    
    -- Validar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM dbo.CuentaUsuario WHERE id_usuario = @id_usuario)
      THROW 50200, 'Usuario no existe', 1;
    
    -- Validar monto positivo
    IF @monto <= 0
      THROW 50201, 'El monto debe ser mayor a cero', 1;
    
    -- Obtener saldo actual
    SELECT @saldo_actual = saldo_actual 
    FROM dbo.CuentaUsuario 
    WHERE id_usuario = @id_usuario;
    
    -- Si es RETIRO, validar saldo suficiente
    IF @tipo_transaccion = 'RETIRO' AND @saldo_actual < @monto
      THROW 50202, 'Saldo insuficiente para el retiro', 1;
    
    -- Insertar transacción
    INSERT INTO dbo.Transaccion (id_usuario, tipo_transaccion, monto, banco, cuenta_cliente, estado)
    VALUES (@id_usuario, @tipo_transaccion, @monto, @banco, @cuenta_cliente, @estado);
    
    COMMIT TRANSACTION;
    SELECT SCOPE_IDENTITY() AS id_transaccion, 'Transacción creada exitosamente' AS Mensaje;
  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END
GO

/* ========================================================================
   TRIGGER: ACTUALIZAR SALDO AL APROBAR TRANSACCIÓN
   ======================================================================== */
IF OBJECT_ID('dbo.trg_Transaccion_ActualizarSaldo','TR') IS NOT NULL
  DROP TRIGGER dbo.trg_Transaccion_ActualizarSaldo;
GO

CREATE TRIGGER dbo.trg_Transaccion_ActualizarSaldo
ON dbo.Transaccion
AFTER INSERT, UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  
  -- Solo procesar transacciones APROBADAS
  IF EXISTS (SELECT 1 FROM inserted WHERE estado = 'APROBADO')
  BEGIN
    DECLARE @id_usuario VARCHAR(50);
    DECLARE @tipo VARCHAR(50);
    DECLARE @monto DECIMAL(12,2);
    
    -- Cursor para procesar cada transacción aprobada
    DECLARE cur CURSOR FOR
      SELECT i.id_usuario, i.tipo_transaccion, i.monto
      FROM inserted i
      LEFT JOIN deleted d ON i.id_transaccion = d.id_transaccion
      WHERE i.estado = 'APROBADO' 
        AND (d.estado IS NULL OR d.estado <> 'APROBADO');
    
    OPEN cur;
    FETCH NEXT FROM cur INTO @id_usuario, @tipo, @monto;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
      -- DEPOSITO y GANANCIA suman al saldo
      IF @tipo IN ('DEPOSITO', 'GANANCIA')
      BEGIN
        UPDATE dbo.CuentaUsuario
        SET saldo_actual = saldo_actual + @monto
        WHERE id_usuario = @id_usuario;
      END
      
      -- RETIRO y PERDIDA restan del saldo
      IF @tipo IN ('RETIRO', 'PERDIDA')
      BEGIN
        UPDATE dbo.CuentaUsuario
        SET saldo_actual = saldo_actual - @monto
        WHERE id_usuario = @id_usuario;
      END
      
      FETCH NEXT FROM cur INTO @id_usuario, @tipo, @monto;
    END
    
    CLOSE cur;
    DEALLOCATE cur;
  END
END
GO

/* ========================================================================
   PROCEDIMIENTO: CREAR APUESTA
   ======================================================================== */
IF OBJECT_ID('dbo.usp_Apuesta_Crear','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Apuesta_Crear;
GO

CREATE PROCEDURE dbo.usp_Apuesta_Crear
  @id_usuario  VARCHAR(50),
  @id_juego    INT,
  @monto       DECIMAL(12,2)
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRANSACTION;
  
  BEGIN TRY
    DECLARE @saldo_actual DECIMAL(12,2);
    
    -- Validar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM dbo.CuentaUsuario WHERE id_usuario = @id_usuario)
      THROW 50300, 'Usuario no existe', 1;
    
    -- Validar que el juego existe
    IF NOT EXISTS (SELECT 1 FROM dbo.Juego WHERE id_juego = @id_juego)
      THROW 50301, 'Juego no existe', 1;
    
    -- Validar monto positivo
    IF @monto <= 0
      THROW 50302, 'El monto debe ser mayor a cero', 1;
    
    -- Obtener saldo actual
    SELECT @saldo_actual = saldo_actual 
    FROM dbo.CuentaUsuario 
    WHERE id_usuario = @id_usuario;
    
    -- Validar saldo suficiente
    IF @saldo_actual < @monto
      THROW 50303, 'Saldo insuficiente para realizar la apuesta', 1;
    
    -- Restar el monto del saldo (se apuesta inmediatamente)
    UPDATE dbo.CuentaUsuario
    SET saldo_actual = saldo_actual - @monto
    WHERE id_usuario = @id_usuario;
    
    -- Insertar apuesta
    INSERT INTO dbo.Apuesta (id_usuario, id_juego, fecha_inicio, monto)
    VALUES (@id_usuario, @id_juego, GETDATE(), @monto);
    
    COMMIT TRANSACTION;
    SELECT SCOPE_IDENTITY() AS id_sesion, 'Apuesta creada exitosamente' AS Mensaje;
  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END
GO
/* ========================================================================
   PROCEDIMIENTO: FINALIZAR APUESTA (con premio si ganó)
   ======================================================================== */
IF OBJECT_ID('dbo.usp_Apuesta_Finalizar','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Apuesta_Finalizar;
GO

CREATE PROCEDURE dbo.usp_Apuesta_Finalizar
  @id_sesion       INT,
  @resultado       VARCHAR(50),     -- 'GANADO', 'PERDIDO'
  @multiplicador   DECIMAL(5,2) = 2.0  -- Por defecto duplica la apuesta si gana
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRANSACTION;
  
  BEGIN TRY
    DECLARE @id_usuario VARCHAR(50);
    DECLARE @monto DECIMAL(12,2);
    DECLARE @premio DECIMAL(12,2);
    
    -- Validar que la apuesta existe y no está finalizada
    IF NOT EXISTS (SELECT 1 FROM dbo.Apuesta WHERE id_sesion = @id_sesion AND fecha_fin IS NULL)
      THROW 50400, 'Apuesta no existe o ya fue finalizada', 1;
    
    -- Obtener datos de la apuesta
    SELECT @id_usuario = id_usuario, @monto = monto
    FROM dbo.Apuesta
    WHERE id_sesion = @id_sesion;
    
    -- Actualizar la apuesta
    UPDATE dbo.Apuesta
    SET fecha_fin = GETDATE(),
        resultado = @resultado
    WHERE id_sesion = @id_sesion;
    
    -- Si ganó, sumar el premio
    IF @resultado = 'GANADO'
    BEGIN
      SET @premio = @monto * @multiplicador;
      
      UPDATE dbo.CuentaUsuario
      SET saldo_actual = saldo_actual + @premio
      WHERE id_usuario = @id_usuario;
      
      SELECT 'Apuesta finalizada - GANASTE!' AS Mensaje, @premio AS Premio;
    END
    ELSE
    BEGIN
      SELECT 'Apuesta finalizada - Perdiste' AS Mensaje, 0 AS Premio;
    END
    
    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END
GO
/* ========================================================================
   PROCEDIMIENTO: APROBAR TRANSACCIÓN (cambiar estado a APROBADO)
   ======================================================================== */
IF OBJECT_ID('dbo.usp_Transaccion_Aprobar','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Transaccion_Aprobar;
GO

CREATE PROCEDURE dbo.usp_Transaccion_Aprobar
  @id_transaccion INT
AS
BEGIN
  SET NOCOUNT ON;
  
  -- Validar que la transacción existe
  IF NOT EXISTS (SELECT 1 FROM dbo.Transaccion WHERE id_transaccion = @id_transaccion)
    THROW 50500, 'Transacción no existe', 1;
  
  -- Actualizar estado (el trigger se encargará de actualizar el saldo)
  UPDATE dbo.Transaccion
  SET estado = 'APROBADO'
  WHERE id_transaccion = @id_transaccion;
  
  SELECT 'Transacción aprobada. El saldo fue actualizado automáticamente.' AS Mensaje;
END
GO

/* ========================================================================
   TRIGGER: BONIFICACIÓN DE BIENVENIDA (10,000)
   Este trigger se ejecuta automáticamente cuando se inserta un nuevo usuario
   ======================================================================== */
IF OBJECT_ID('dbo.trg_CuentaUsuario_BonificacionBienvenida','TR') IS NOT NULL
  DROP TRIGGER dbo.trg_CuentaUsuario_BonificacionBienvenida;
GO

CREATE TRIGGER dbo.trg_CuentaUsuario_BonificacionBienvenida
ON dbo.CuentaUsuario
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE @id_usuario VARCHAR(50);
  DECLARE @monto_bono DECIMAL(12,2) = 10000.00;
  
  -- Cursor para procesar cada usuario nuevo insertado
  DECLARE cur CURSOR FOR
    SELECT id_usuario FROM inserted;
  
  OPEN cur;
  FETCH NEXT FROM cur INTO @id_usuario;
  
  WHILE @@FETCH_STATUS = 0
  BEGIN
    -- Crear registro de bonificación
    INSERT INTO dbo.Bonificacion (id_usuario, nombre, descripcion, monto, estado, fecha)
    VALUES (
      @id_usuario,
      'Bono de Bienvenida',
      'Bonificación automática por registro de nuevo usuario',
      @monto_bono,
      'APLICADO',
      GETDATE()
    );
    
    -- Sumar el bono al saldo actual del usuario
    UPDATE dbo.CuentaUsuario
    SET saldo_actual = saldo_actual + @monto_bono
    WHERE id_usuario = @id_usuario;
    
    FETCH NEXT FROM cur INTO @id_usuario;
  END
  
  CLOSE cur;
  DEALLOCATE cur;
END
GO 


