'use strict';
// Produces SQL and rehearses it only in a disposable local PostgreSQL database.
const assert=require('node:assert/strict'),{createRequire}=require('node:module');
const {fs,path,args,read,save,hash}=require('./lib.cjs');
const v=args(),out=path.resolve(v.out),website=path.resolve(v.website),squid=path.join(website,'apps/squid');
const live=read(path.join(out,'backend-live-readonly-result.json'));
assert.equal(live.changesMade,false);assert.deepEqual(live.checks.legacyRequests,[]);
const expected=['Data1749079541557','Data1749080326985','Data1756344326859'];
assert.deepEqual(live.checks['migrationLedger:squid.migrations'].map(x=>x.name),expected);
const inputs=['nursery-1791158400000/up.sql','nursery-1792368000000/up.sql'].map(x=>fs.readFileSync(path.join(squid,'db/migrations',x),'utf8'));
const readFunctions=['evos_filtered.sql','evos_sorted.sql','get_evos.sql'].map(x=>fs.readFileSync(path.join(squid,'src/sql/functions',x),'utf8'));
const sql=`-- REVIEW CANDIDATE ONLY. Requires separate production database-change approval.
-- Execute once as the existing database owner, before starting the new indexer.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '120s';
SET LOCAL search_path = squid, public;
SELECT pg_advisory_xact_lock(hashtext('evoverses-nursery-migration-20261020'));
LOCK TABLE squid.migrations IN EXCLUSIVE MODE;
DO $readiness$
BEGIN
 IF current_user <> 'postgres' THEN RAISE EXCEPTION 'Existing database owner required'; END IF;
 IF NOT has_schema_privilege(current_user,'squid','CREATE') OR NOT has_schema_privilege(current_user,'metadata','CREATE')
 THEN RAISE EXCEPTION 'Owner connection lacks required schema privileges'; END IF;
 IF (SELECT array_agg(name::text ORDER BY timestamp) FROM squid.migrations)
    IS DISTINCT FROM ARRAY['Data1749079541557','Data1749080326985','Data1756344326859']::text[]
 THEN RAISE EXCEPTION 'Migration ledger changed: regenerate and review'; END IF;
 IF to_regclass('squid.nursery_evo') IS NOT NULL THEN RAISE EXCEPTION 'Nursery registry already exists'; END IF;
 IF EXISTS (SELECT 1 FROM squid.breeding_request) THEN RAISE EXCEPTION 'Legacy requests require reconciliation'; END IF;
END $readiness$;
${inputs.join('\n')}
-- Reinstall the frozen list-query helpers against the same canonical view.
${readFunctions.join('\n')}
-- Keep DDL ownership with the database owner; grant only required runtime access.
GRANT SELECT, INSERT, UPDATE, DELETE ON squid.nursery_evo TO squid;
GRANT SELECT ON squid.nursery_evo TO graphql;
GRANT SELECT ON metadata.evos_aggregated_view TO graphql;
INSERT INTO squid.migrations(timestamp,name) VALUES
 (1791158400000,'NurseryMetadata1791158400000'),
 (1792368000000,'NurseryProvenanceDates1792368000000');
COMMIT;
`.replace(/\r\n/g,'\n');
fs.writeFileSync(path.join(out,'database-owner-migration.sql'),sql);
async function main(){
 const runtime=createRequire(path.join(squid,'package.json')),{PGlite}=runtime('@electric-sql/pglite'),db=new PGlite();
 try{
  await db.exec('CREATE ROLE squid; CREATE ROLE graphql; CREATE SCHEMA squid AUTHORIZATION squid; SET search_path=squid,public;');
  for(const file of ['1749079541557-Data.js','1749080326985-Data.js','1756344326859-Data.js'])await new(require(path.join(squid,'db/migrations',file)))().up({query:sql=>db.exec(sql)});
  await db.exec('CREATE TABLE squid.migrations (id serial PRIMARY KEY,timestamp bigint NOT NULL,name varchar NOT NULL);');
  for(const [i,name] of expected.entries())await db.query('INSERT INTO squid.migrations(timestamp,name) VALUES ($1,$2)',[[1749079541557,1749080326985,1756344326859][i],name]);
  await db.exec(fs.readFileSync(path.join(website,'packages/database/drizzle/0000_rapid_mad_thinker.sql'),'utf8'));
  // Match the live function interfaces before replacement; no live row data is copied.
  await db.exec("CREATE FUNCTION metadata.get_evo(_tokenId text) RETURNS TABLE(tokenId text,chainId text,address text,owner text,metadata jsonb,offers jsonb[],listings jsonb[],auctions jsonb[]) LANGUAGE sql AS $$ SELECT null::text,null::text,null::text,null::text,null::jsonb,null::jsonb[],null::jsonb[],null::jsonb[] WHERE false $$; CREATE FUNCTION metadata.get_evos(_limit int,_page int,_sort text,_owners text[] DEFAULT null,_listed boolean DEFAULT null,_attributes jsonb DEFAULT null) RETURNS jsonb LANGUAGE sql AS $$ SELECT null::jsonb $$;");
  await db.exec("GRANT USAGE ON SCHEMA squid,metadata TO graphql; GRANT SELECT ON ALL TABLES IN SCHEMA squid,metadata TO graphql; ALTER TABLE squid.migrations OWNER TO squid;");
  const signatures=(await db.query("SELECT p.proname AS name,pg_get_function_identity_arguments(p.oid) AS arguments,pg_get_function_result(p.oid) AS result FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='metadata' AND p.proname IN ('get_evo','get_evos') ORDER BY 1")).rows;
  for(const actual of live.checks.functionSignatures){if(!['get_evo','get_evos'].includes(actual.name))continue;const local=signatures.find(x=>x.name===actual.name);assert.ok(local,actual.name);assert.equal(local.arguments,actual.arguments);assert.equal(local.result,actual.result);}
  await db.exec('SET ROLE squid;');
  let denied=false;try{await db.exec('SELECT * FROM metadata.evo LIMIT 0');}catch(e){denied=e.code==='42501';}assert.equal(denied,true,'Reproduce restricted live indexer role');
  await db.exec('RESET ROLE;');
  await db.exec(sql);
  assert.equal((await db.query('SELECT count(*)::int AS total FROM squid.migrations')).rows[0].total,5);
  await db.exec('SET ROLE squid; INSERT INTO squid.nursery_evo VALUES (\'probe\',\'local\',1,\'local\',\'{}\'); DELETE FROM squid.nursery_evo WHERE id=\'probe\'; RESET ROLE;');
  await db.exec('SET ROLE graphql; SELECT * FROM metadata.get_evo(\'0\'); SELECT metadata.get_evos(48,0,\'PRICE_LOW_TO_HIGH\',null,null,null); SELECT * FROM squid.nursery_evo LIMIT 0; RESET ROLE;');
  await db.exec('SET ROLE graphql;');let readerWriteDenied=false;try{await db.exec("DELETE FROM squid.nursery_evo WHERE id='probe'");}catch(e){readerWriteDenied=e.code==='42501';}assert.equal(readerWriteDenied,true);await db.exec('RESET ROLE;');
  let rerunRejected=false;try{await db.exec(sql);}catch(e){rerunRejected=/Migration ledger changed/.test(e.message);await db.exec('ROLLBACK');}assert.equal(rerunRejected,true);
  const result={passed:true,localDatabaseOnly:true,productionDatabaseWrites:0,liveFunctionSignaturesMatch:true,restrictedIndexerRoleReproduced:true,ownerMigrationPassed:true,indexerRegistryWritePassed:true,graphqlReadPassed:true,graphqlWriteDenied:true,repeatExecutionRejected:true,migrationLedgerCount:5,sqlSha256:hash(sql),migrationInputSha256:inputs.map(hash),readFunctionInputSha256:readFunctions.map(hash),approvalRequired:true};
  save(path.join(out,'database-owner-rehearsal.json'),result);console.log(JSON.stringify(result));
 }finally{await db.close();}
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
