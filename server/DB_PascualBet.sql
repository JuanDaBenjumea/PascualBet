create database DB_PascualBet
use DB_PascualBet

--Bloque para eliminar base de datos
use master
drop database DB_PascualBet

-- ======================
-- TABLA CUENTA USUARIO 
-- ======================
CREATE TABLE CuentaUsuario (
    id_usuario VARCHAR(50) PRIMARY KEY,   -- Clave primaria
    contraseña VARCHAR(255) NOT NULL,
    saldo_actual DECIMAL(12,2) DEFAULT 0,
    rol VARCHAR(20) Default 'Usuario',
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
-- TABLA APUESTA
-- ======================
CREATE TABLE Apuesta (
    id_sesion INT PRIMARY KEY IDENTITY(1,1),
    id_usuario VARCHAR(50) NOT NULL,
    id_juego INT NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NULL,
    resultado VARCHAR(50) NULL,
    FOREIGN KEY (id_usuario) REFERENCES CuentaUsuario(id_usuario),
    FOREIGN KEY (id_juego) REFERENCES Juego(id_juego)
);

-- ======================
-- TABLA TRANSACCION
-- ======================
CREATE TABLE Transaccion (
    id_transaccion INT PRIMARY KEY IDENTITY(1,1),
    id_usuario VARCHAR(50) NOT NULL,
    tipo_transaccion VARCHAR(50) NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_transaccion DATETIME DEFAULT GETDATE(),
    estado VARCHAR(20) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES CuentaUsuario(id_usuario)
);

-- ======================
-- TABLA HISTORIAL JUEGO
-- ======================
CREATE TABLE HistorialJuego (
    id_actividad INT PRIMARY KEY IDENTITY(1,1),
    id_usuario VARCHAR(50) NOT NULL,
    tipo_actividad VARCHAR(50) NOT NULL,
    fecha_hora DATETIME DEFAULT GETDATE(),
    ip_origen VARCHAR(50),
    FOREIGN KEY (id_usuario) REFERENCES CuentaUsuario(id_usuario)
);

-- ======================
-- TABLA BONIFICACION
-- ======================
CREATE TABLE Bonificacion (
    id_bonificacion INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255),
    monto DECIMAL(12,2) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL
);

-- ======================
-- TABLA BONIFICACION_USUARIO
-- ======================
CREATE TABLE Bonificacion_Usuario (
    id_usuario VARCHAR(50) NOT NULL,
    id_bonificacion INT NOT NULL,
    estado VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_usuario, id_bonificacion),
    FOREIGN KEY (id_usuario) REFERENCES CuentaUsuario(id_usuario),
    FOREIGN KEY (id_bonificacion) REFERENCES Bonificacion(id_bonificacion)
);

-- ======================
-- SUPER ADMIN TEXTO PLANO PARA PRUEBAS
-- ======================
INSERT INTO CuentaUsuario (id_usuario, contraseña, rol, saldo_actual, fecha_nacimiento)
VALUES ('admin', 'admin123', 'ADMIN', 999999.99,'2004-10-04' );

select * from CuentaUsuario
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
  @contrasena       VARCHAR(255),      -- Recomendado: hash (bcrypt) generado en el backend
  @fecha_nacimiento DATE,
  @rol              VARCHAR(20) = NULL -- Opcional (si no se env�a, usa DEFAULT 'Usuario')
AS
BEGIN
  SET NOCOUNT ON;

  -- Validaciones b�sicas
  IF @id_usuario IS NULL OR LTRIM(RTRIM(@id_usuario)) = ''
    THROW 50010, 'id_usuario es requerido', 1;

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
    INSERT INTO dbo.CuentaUsuario (id_usuario, [contraseña], fecha_nacimiento)
    VALUES (@id_usuario, @contrasena, @fecha_nacimiento);
  ELSE
    INSERT INTO dbo.CuentaUsuario (id_usuario, [contraseña], fecha_nacimiento, rol)
    VALUES (@id_usuario, @contrasena, @fecha_nacimiento, @rol);
END
GO

/* ==================================================
   SP: LOGIN (modo recomendado: devolver HASH al app)
   ================================================== */
IF OBJECT_ID('dbo.usp_CuentaUsuario_Login_GetHash','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_CuentaUsuario_Login_GetHash;
GO
CREATE PROCEDURE dbo.usp_CuentaUsuario_Login_GetHash
  @id_usuario VARCHAR(50),
  @hash       VARCHAR(255)   OUTPUT,  -- contrase�a almacenada (p.ej. bcrypt)
  @rol        VARCHAR(20)    OUTPUT,
  @saldo      DECIMAL(12,2)  OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
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
  @contrasena  VARCHAR(255),
  @login_ok    BIT           OUTPUT,
  @rol         VARCHAR(20)   OUTPUT,
  @saldo       DECIMAL(12,2) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @stored VARCHAR(255);

  SELECT TOP 1
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