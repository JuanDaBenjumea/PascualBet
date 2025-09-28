// server/server.js
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const util = require('util');
const { sql, query, getPool } = require('./db');

// Logs globales por si algo crashea
process.on('unhandledRejection', err => console.error('UNHANDLED REJECTION:', err));
process.on('uncaughtException', err => console.error('UNCAUGHT EXCEPTION:', err));

// ===== Crear app y middlewares =====
const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// ===== Utils =====
function normalizeError(e){
  const msg  = e?.originalError?.info?.message || e?.message || String(e);
  const code = e?.code || e?.originalError?.code || e?.number || null;
  const brief = e?.originalError?.info
    ? { number: e.originalError.info.number, state: e.originalError.info.state, class: e.originalError.info.class }
    : undefined;
  return { message: msg, code, brief };
}
function isDuplicateKeyError(e){
  const num = e?.originalError?.info?.number ?? e?.number ?? null;
  const msg = (e?.originalError?.info?.message || e?.message || '').toLowerCase();
  return (
    num === 2627 || num === 2601 ||
    msg.includes('duplicate key') ||
    msg.includes('violation of primary key') ||
    msg.includes('unique index') ||
    msg.includes('unique constraint')
  );
}
function isAdult(isoDate){
  if (!isoDate) return false;
  const d = new Date(isoDate);
  const today = new Date();
  const eighteen = new Date(d.getFullYear() + 18, d.getMonth(), d.getDate());
  return eighteen <= today;
}

// ===== Ping sin DB (para saber si Express vive) =====
app.get('/api/ping', (_req, res) => res.json({ ok: true }));

// ===== Health con info de DB =====
app.get('/api/health', async (_req, res) => {
  try {
    const pool = await getPool();
    const r = await pool.request().query(`
      SELECT DB_NAME() AS db, SUSER_SNAME() AS [user], @@SERVERNAME AS srv, GETDATE() AS [now]
    `);
    res.json({ ok: true, ...r.recordset[0] });
  } catch (e) {
    const info = normalizeError(e);
    res.status(500).json({ ok:false, error: info.message, code: info.code, details: info.brief });
  }
});

// (Opcional) ver error crudo
app.get('/api/health/raw', async (_req,res)=>{
  try{
    const pool = await getPool();
    await pool.request().query('SELECT 1');
    res.send('OK');
  }catch(e){
    res.status(500).send(util.inspect(e, { depth: 5 }));
  }
});

/**
 * POST /api/signup
 * body: { uid, password, dob }  // dob: 'YYYY-MM-DD'
 */
app.post('/api/signup', async (req, res) => {
  const { uid, password, dob } = req.body || {};
  if (!uid || !password) return res.status(400).json({ ok:false, error: 'uid y password requeridos' });
  if (!dob) return res.status(400).json({ ok:false, error: 'fecha_nacimiento requerida' });
  if (!isAdult(dob)) return res.status(400).json({ ok:false, error: 'Debes ser mayor de 18 años' });

  try {
    // Pre-check para mejor UX (además del control en DB)
    const exists = await query(
      'SELECT 1 FROM dbo.CuentaUsuario WHERE id_usuario=@uid',
      [{ name:'uid', type: sql.VarChar(50), value: uid }]
    );
    if (exists.recordset.length) {
      return res.status(409).json({ ok:false, error: 'El usuario ya existe' });
    }

    const hash = await bcrypt.hash(password, 10);
    await query(`
      INSERT INTO dbo.CuentaUsuario (id_usuario, [contraseña], fecha_nacimiento)
      VALUES (@uid, @hash, @dob);
    `, [
      { name:'uid',  type: sql.VarChar(50),  value: uid },
      { name:'hash', type: sql.VarChar(255), value: hash },
      { name:'dob',  type: sql.DateTime,     value: new Date(dob) }
    ]);

    res.json({ ok:true });
  } catch (e) {
    if (isDuplicateKeyError(e)) {
      return res.status(409).json({ ok:false, error: 'El usuario ya existe' });
    }
    res.status(500).json({ ok:false, error: e.originalError?.info?.message || e.message });
  }
});

/**
 * POST /api/login
 * body: { uid, password }
 */
app.post('/api/login', async (req, res) => {
  const { uid, password } = req.body || {};
  if (!uid || !password) return res.status(400).json({ ok:false, error: 'uid y password requeridos' });

  try {
    const r = await query(`
      SELECT TOP 1 [contraseña] AS passhash, rol, saldo_actual, fecha_nacimiento
      FROM dbo.CuentaUsuario WHERE id_usuario=@uid;
    `, [{ name:'uid', type: sql.VarChar(50), value: uid }]);

    if (!r.recordset.length) return res.status(401).json({ ok:false, error: 'credenciales inválidas' });

    const row = r.recordset[0];
    let ok = false;
    try { ok = await bcrypt.compare(password, row.passhash); } catch {}

    // Fallback (por si tienes un seed en texto plano)
    if (!ok && row.passhash === password) ok = true;

    if (!ok) return res.status(401).json({ ok:false, error: 'credenciales inválidas' });

    res.json({ ok: true, rol: row.rol, saldo: row.saldo_actual, dob: row.fecha_nacimiento });
  } catch (e) {
    res.status(500).json({ ok:false, error:e.message });
  }
});

/**
 * POST /api/balance/deposit
 * body: { uid, monto }
 */
app.post('/api/balance/deposit', async (req, res) => {
  const { uid, monto } = req.body || {};
  if (!uid || !monto || Number(monto) <= 0) return res.status(400).json({ ok:false, error: 'monto inválido' });

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  try {
    await tx.begin();
    await new sql.Request(tx)
      .input('uid', sql.VarChar(50), uid)
      .input('monto', sql.Decimal(12,2), Number(monto))
      .query(`UPDATE dbo.CuentaUsuario SET saldo_actual = saldo_actual + @monto WHERE id_usuario=@uid;`);
    await new sql.Request(tx)
      .input('uid', sql.VarChar(50), uid)
      .input('monto', sql.Decimal(12,2), Number(monto))
      .query(`INSERT INTO dbo.Transaccion (id_usuario, tipo_transaccion, monto, estado)
              VALUES (@uid, 'DEPOSITO', @monto, 'APROBADA');`);
    await tx.commit();
    res.json({ ok:true });
  } catch (e) {
    try { await tx.rollback(); } catch {}
    res.status(500).json({ ok:false, error:e.message });
  }
});

/**
 * POST /api/balance/withdraw
 * body: { uid, monto }
 */
app.post('/api/balance/withdraw', async (req, res) => {
  const { uid, monto } = req.body || {};
  if (!uid || !monto || Number(monto) <= 0) return res.status(400).json({ ok:false, error: 'monto inválido' });

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  try {
    await tx.begin();
    const r = await new sql.Request(tx)
      .input('uid', sql.VarChar(50), uid)
      .query(`SELECT saldo_actual FROM dbo.CuentaUsuario WHERE id_usuario=@uid;`);
    if (!r.recordset.length) throw new Error('usuario no existe');
    const saldo = Number(r.recordset[0].saldo_actual);
    if (saldo < Number(monto)) throw new Error('fondos insuficientes');

    await new sql.Request(tx)
      .input('uid', sql.VarChar(50), uid)
      .input('monto', sql.Decimal(12,2), Number(monto))
      .query(`UPDATE dbo.CuentaUsuario SET saldo_actual = saldo_actual - @monto WHERE id_usuario=@uid;`);

    await new sql.Request(tx)
      .input('uid', sql.VarChar(50), uid)
      .input('monto', sql.Decimal(12,2), Number(monto))
      .query(`INSERT INTO dbo.Transaccion (id_usuario, tipo_transaccion, monto, estado)
              VALUES (@uid, 'RETIRO', @monto, 'APROBADA');`);

    await tx.commit();
    res.json({ ok:true });
  } catch (e) {
    try { await tx.rollback(); } catch {}
    res.status(400).json({ ok:false, error:e.message });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`API: http://localhost:${PORT}`));