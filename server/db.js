// server/db.js
const useWindowsAuth = process.env.SQL_AUTH === 'windows';
const sql = useWindowsAuth ? require('mssql/msnodesqlv8') : require('mssql');

// Normaliza valores del .env
const rawServer = (process.env.SQL_SERVER || '').replace(/^"|"$/g, ''); // e.g. DESKTOP-PKVC4GL\\MSSQLSERVER01
const dbName    = process.env.SQL_DB || '';
const portPart  = process.env.SQL_PORT ? `,${process.env.SQL_PORT}` : '';

const cfg = useWindowsAuth
  ? {
      // Windows Authentication con ODBC Driver 18 y cifrado explícito
      connectionString:
        `Server=${rawServer}${portPart};` +
        `Database=${dbName};` +
        `Trusted_Connection=Yes;` +
        `Driver={ODBC Driver 18 for SQL Server};` +
        `Encrypt=Yes;` +
        `TrustServerCertificate=Yes;`,
      pool: { max: 10, min: 0, idleTimeoutMillis: 30000 }
    }
  : (() => {
      // SQL Authentication (driver 'mssql')
      // Si viene HOST\\INSTANCIA, separamos para usar instanceName
      let host = rawServer, instanceName;
      if (rawServer.includes('\\')) {
        [host, instanceName] = rawServer.split('\\');
      }
      return {
        user: process.env.SQL_USER,
        password: process.env.SQL_PASSWORD,
        server: host,
        port: process.env.SQL_PORT ? parseInt(process.env.SQL_PORT, 10) : undefined,
        database: dbName,
        options: {
          encrypt: process.env.SQL_ENCRYPT === 'true',
          trustServerCertificate: process.env.SQL_TRUST === 'true',
          instanceName
        },
        pool: { max: 10, min: 0, idleTimeoutMillis: 30000 }
      };
    })();

let pool;
async function getPool() {
  if (pool) return pool;
  pool = await sql.connect(cfg);
  return pool;
}

async function query(text, params = []) {
  const p = await getPool();
  const req = p.request();
  params.forEach(({ name, type, value }) => req.input(name, type ?? sql.NVarChar, value));
  return req.query(text);
}

module.exports = { sql, query, getPool };
