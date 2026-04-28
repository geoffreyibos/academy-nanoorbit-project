const http = require("http");
const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const PORT = Number(process.env.PORT || 8088);
const ORACLE_CONTAINER = process.env.ORACLE_CONTAINER || "nanoorbit-oracle";
const ORACLE_CONNECT =
  process.env.ORACLE_CONNECT ||
  "NANOORBIT_ADMIN/NanoOrbit2025@localhost:1521/FREEPDB1";
const DOCKER_CONFIG_DIR = process.env.DOCKER_CONFIG || path.join(__dirname, ".docker-config");

const jsonHeaders = { "Content-Type": "application/json; charset=utf-8" };
const HEALTH_SQL = `
select json_object(
  'status' value 'ok',
  'oracle' value 'reachable',
  'container' value '${ORACLE_CONTAINER}'
  returning clob
)
from dual
`;

const SATELLITES_SQL = `
select coalesce(
  json_arrayagg(
    json_object(
      'idSatellite' value s.id_satellite,
      'nomSatellite' value s.nom_satellite,
      'statut' value case
        when regexp_like(s.statut, '^Op') then 'OPERATIONNEL'
        when regexp_like(s.statut, '^En') then 'EN_VEILLE'
        when regexp_like(s.statut, '^D.{0,4}fa') then 'DEFAILLANT'
        else 'DESORBITE'
      end,
      'formatCubesat' value s.format_cubesat,
      'idOrbite' value to_number(regexp_substr(s.id_orbite, '[0-9]+')),
      'orbiteType' value o.type_orbite,
      'dateLancement' value to_char(s.date_lancement, 'YYYY-MM-DD'),
      'masse' value s.masse_kg,
      'dureeViePrevueMois' value s.duree_vie_mois,
      'capaciteBatterie' value s.capacite_batterie_wh
      returning clob
    )
    returning clob
  ),
  to_clob('[]')
)
from satellite s
join orbite o on o.id_orbite = s.id_orbite
`;

const FENETRES_SQL = `
select coalesce(
  json_arrayagg(
    json_object(
      'idFenetre' value f.id_fenetre,
      'datetimeDebut' value to_char(f.datetime_debut, 'YYYY-MM-DD"T"HH24:MI:SS'),
      'dureeSecondes' value f.duree_secondes,
      'elevationMax' value f.elevation_max_deg,
      'statut' value case
        when regexp_like(f.statut, '^Plan') then 'PLANIFIEE'
        when regexp_like(f.statut, '^R') then 'REALISEE'
        else 'ANNULEE'
      end,
      'idSatellite' value f.id_satellite,
      'codeStation' value f.code_station,
      'volumeDonnees' value f.volume_donnees_mo
      returning clob
    )
    returning clob
  ),
  to_clob('[]')
)
from fenetre_com f
`;

const STATIONS_SQL = `
select coalesce(
  json_arrayagg(
    json_object(
      'codeStation' value s.code_station,
      'nomStation' value s.nom_station,
      'latitude' value s.latitude,
      'longitude' value s.longitude,
      'diametreAntenne' value s.diametre_antenne_m,
      'bandeFrequence' value s.bande_frequence,
      'debitMax' value s.debit_max_mbps,
      'statut' value case
        when regexp_like(s.statut, '^Act') then 'ACTIVE'
        when regexp_like(s.statut, '^Maint') then 'MAINTENANCE'
        else 'HORS_SERVICE'
      end
      returning clob
    )
    returning clob
  ),
  to_clob('[]')
)
from station_sol s
`;

function satelliteByIdSql(id) {
  return `
select json_object(
  'idSatellite' value s.id_satellite,
  'nomSatellite' value s.nom_satellite,
  'statut' value case
    when regexp_like(s.statut, '^Op') then 'OPERATIONNEL'
    when regexp_like(s.statut, '^En') then 'EN_VEILLE'
    when regexp_like(s.statut, '^D.{0,4}fa') then 'DEFAILLANT'
    else 'DESORBITE'
  end,
  'formatCubesat' value s.format_cubesat,
  'idOrbite' value to_number(regexp_substr(s.id_orbite, '[0-9]+')),
  'orbiteType' value o.type_orbite,
  'dateLancement' value to_char(s.date_lancement, 'YYYY-MM-DD'),
  'masse' value s.masse_kg,
  'dureeViePrevueMois' value s.duree_vie_mois,
  'capaciteBatterie' value s.capacite_batterie_wh
  returning clob
)
from satellite s
join orbite o on o.id_orbite = s.id_orbite
where s.id_satellite = '${escapeSql(id)}'
`;
}

function orbiteBySatelliteSql(id) {
  return `
select json_object(
  'idOrbite' value to_number(regexp_substr(o.id_orbite, '[0-9]+')),
  'typeOrbite' value o.type_orbite,
  'altitude' value o.altitude_km,
  'inclinaison' value o.inclinaison_deg,
  'periodeOrbitale' value o.periode_min,
  'excentricite' value o.excentricite,
  'zoneCouverture' value o.zone_couverture
  returning clob
)
from orbite o
join satellite s on s.id_orbite = o.id_orbite
where s.id_satellite = '${escapeSql(id)}'
`;
}

function instrumentsSql(id) {
  return `
select coalesce(
  json_arrayagg(
    json_object(
      'refInstrument' value i.ref_instrument,
      'typeInstrument' value i.type_instrument,
      'modele' value i.modele,
      'resolution' value i.resolution_m,
      'consommation' value i.consommation_w,
      'masse' value i.masse_kg,
      'etatFonctionnement' value e.etat_fonctionnement
      returning clob
    )
    returning clob
  ),
  to_clob('[]')
)
from embarquement e
join instrument i on i.ref_instrument = e.ref_instrument
where e.id_satellite = '${escapeSql(id)}'
`;
}

function missionsSql(id) {
  return `
select coalesce(
  json_arrayagg(
    json_object(
      'idMission' value m.id_mission,
      'nomMission' value m.nom_mission,
      'objectif' value m.objectif,
      'dateDebut' value to_char(m.date_debut, 'YYYY-MM-DD'),
      'statutMission' value case
        when regexp_like(m.statut_mission, '^Act') then 'ACTIVE'
        else 'TERMINEE'
      end,
      'dateFin' value to_char(m.date_fin, 'YYYY-MM-DD'),
      'zoneGeoCible' value m.zone_cible,
      'roleSatellite' value p.role_satellite
      returning clob
    )
    returning clob
  ),
  to_clob('[]')
)
from participation p
join mission m on m.id_mission = p.id_mission
where p.id_satellite = '${escapeSql(id)}'
`;
}

function escapeSql(value) {
  return String(value).replace(/'/g, "''");
}

function runSql(query) {
  return new Promise((resolve, reject) => {
    ensureDockerConfig();

    const sql = [
      "set heading off",
      "set feedback off",
      "set pagesize 0",
      "set verify off",
      "set echo off",
      "set trimspool on",
      "set serveroutput off",
      "set long 1000000",
      "set longchunksize 1000000",
      "set linesize 32767",
      terminateSql(query),
      "exit"
    ].join("\n");

    const child = spawn(
      "docker",
      ["exec", "-i", ORACLE_CONTAINER, "sqlplus", "-s", ORACLE_CONNECT],
      {
        stdio: ["pipe", "pipe", "pipe"],
        env: {
          ...process.env,
          DOCKER_CONFIG: DOCKER_CONFIG_DIR
        }
      }
    );

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    child.on("error", reject);

    child.on("close", (code) => {
      const cleaned = stdout
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean)
        .join("");

      if (code !== 0 || /ORA-|SP2-/.test(stdout) || /ORA-|SP2-/.test(stderr)) {
        reject(new Error((stderr || stdout).trim()));
        return;
      }

      resolve(cleaned);
    });

    child.stdin.end(sql);
  });
}

function terminateSql(query) {
  const trimmed = query.trim();
  return trimmed.endsWith(";") ? trimmed : `${trimmed};`;
}

function ensureDockerConfig() {
  if (process.env.DOCKER_CONFIG) {
    return;
  }

  fs.mkdirSync(DOCKER_CONFIG_DIR, { recursive: true });
  const configPath = path.join(DOCKER_CONFIG_DIR, "config.json");
  if (!fs.existsSync(configPath)) {
    fs.writeFileSync(configPath, "{}\n");
  }
}

async function runJsonQuery(query, fallback) {
  const raw = await runSql(query);
  if (!raw) {
    return fallback;
  }
  return JSON.parse(raw);
}

async function getSatelliteDetail(id) {
  const [satellite, orbite, instruments, missions] = await Promise.all([
    runJsonQuery(satelliteByIdSql(id), null),
    runJsonQuery(orbiteBySatelliteSql(id), null),
    runJsonQuery(instrumentsSql(id), []),
    runJsonQuery(missionsSql(id), [])
  ]);

  if (!satellite) {
    return null;
  }

  return {
    satellite,
    orbite,
    instruments: instruments.map((item) => ({
      instrument: {
        refInstrument: item.refInstrument,
        typeInstrument: item.typeInstrument,
        modele: item.modele,
        resolution: item.resolution,
        consommation: item.consommation,
        masse: item.masse
      },
      etatFonctionnement: item.etatFonctionnement
    })),
    missions: missions.map((item) => ({
      mission: {
        idMission: item.idMission,
        nomMission: item.nomMission,
        objectif: item.objectif,
        dateDebut: item.dateDebut,
        statutMission: item.statutMission,
        dateFin: item.dateFin,
        zoneGeoCible: item.zoneGeoCible
      },
      roleSatellite: item.roleSatellite
    }))
  };
}

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, jsonHeaders);
  response.end(JSON.stringify(payload));
}

const server = http.createServer(async (request, response) => {
  try {
    const url = new URL(request.url, `http://${request.headers.host}`);
    const path = url.pathname;

    if (request.method === "GET" && path === "/health") {
      sendJson(response, 200, await runJsonQuery(HEALTH_SQL, { status: "ok" }));
      return;
    }

    if (request.method === "GET" && path === "/satellites") {
      sendJson(response, 200, await runJsonQuery(SATELLITES_SQL, []));
      return;
    }

    if (request.method === "GET" && path === "/fenetres") {
      sendJson(response, 200, await runJsonQuery(FENETRES_SQL, []));
      return;
    }

    if (request.method === "GET" && path === "/stations") {
      sendJson(response, 200, await runJsonQuery(STATIONS_SQL, []));
      return;
    }

    const instrumentMatch = path.match(/^\/satellites\/([^/]+)\/instruments$/);
    if (request.method === "GET" && instrumentMatch) {
      const satelliteId = decodeURIComponent(instrumentMatch[1]);
      const instruments = await runJsonQuery(instrumentsSql(satelliteId), []);
      sendJson(
        response,
        200,
        instruments.map((item) => ({
          refInstrument: item.refInstrument,
          typeInstrument: item.typeInstrument,
          modele: item.modele,
          resolution: item.resolution,
          consommation: item.consommation,
          masse: item.masse
        }))
      );
      return;
    }

    const detailMatch = path.match(/^\/satellites\/([^/]+)\/detail$/);
    if (request.method === "GET" && detailMatch) {
      const satelliteId = decodeURIComponent(detailMatch[1]);
      const detail = await getSatelliteDetail(satelliteId);
      if (!detail) {
        sendJson(response, 404, { error: "Satellite introuvable" });
        return;
      }
      sendJson(response, 200, detail);
      return;
    }

    sendJson(response, 404, { error: "Route introuvable" });
  } catch (error) {
    sendJson(response, 500, { error: error.message || "Erreur serveur" });
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`NanoOrbit local API listening on http://0.0.0.0:${PORT}`);
  console.log(`Android emulator URL: http://10.0.2.2:${PORT}`);
});

server.on("error", (error) => {
  console.error(`NanoOrbit local API failed: ${error.message}`);
  process.exitCode = 1;
});
