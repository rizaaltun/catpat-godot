extends SceneTree
## Synthetic registered profiles verify prospective post-commit evidence, never real child data.
const Observations=preload("res://scripts/core/observation_service.gd")
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const Docs=preload("res://scripts/core/local_document_store.gd")
const PATH="user://observation-contract-journey.json"
const SECOND="user://observation-contract-second.json"
const SEEDED="user://observation-contract-seeded.json"
const SUMMIT="user://observation-contract-summit.json"
const CAPPED="user://observation-contract-capped.json"
const FOREIGN="user://observation-contract-foreign.json"
var checks=0
var failures=0
var observer
var previous_observer
var rows={}
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func clean(path:String):
 for suffix in ["",".bak",".pending",".bak.pending",".legacy",".onboarding-v1.original"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 var folder=DirAccess.open(path.get_base_dir())
 if folder:
  for name in folder.get_files():
   if name.begins_with(path.get_file()+".damaged-") or name.begins_with(path.get_file()+".bak.damaged-"):DirAccess.remove_absolute(path.get_base_dir().path_join(name))
func add_profile(path:String,id:String):
 rows[path]={"profile_id":id,"journey_path":path,"journal_path":path+".observations"}
 clean(path);clean(path+".observations")
func by_id(id:String)->Dictionary:
 for row in rows.values():
  if row.profile_id==id:return row
 return {}
func report(id:String)->Dictionary:return observer.report_for(id)
func full_fixture()->Dictionary:
 var q=Quest.new()
 for event in Quest.HOME_EVENTS+Quest.EVENTS:q.apply(event)
 var data=Save.new().fresh();data.chapter_id="B05";data.geometry="festival-v1";data.checkpoint_id="b05.stage"
 data.quest_flags=q.flags.duplicate();data.party_ids=q.party_ids();data.ending_seen=true;data.settings.onboarding_origin="legacy-bypass-v1"
 return data
func run():
 var experience=root.get_node_or_null("CatpatExperience")
 if experience:experience.auto_observe=false
 previous_observer=root.get_node_or_null("CatpatObservations")
 if previous_observer:previous_observer.name="InactiveObservationsDuringContract"
 observer=Observations.new();observer.name="CatpatObservations";root.add_child(observer)
 observer.clock=func():return "2026-10-30T12:00:00Z"
 observer.profile_resolver=func(path):return rows.get(path,{})
 observer.profile_id_resolver=by_id
 for pair in [[PATH,"profile_contract_a"],[SECOND,"profile_contract_b"],[SEEDED,"profile_contract_seeded"],[SUMMIT,"profile_contract_summit"],[CAPPED,"profile_contract_cap"]]:add_profile(pair[0],pair[1])
 clean(FOREIGN);clean(Replay.new().replay_path(PATH))
 check(Observations.valid_journal(Observations.fresh("profile_contract_a")),"empty journal has explicit uninitialized baseline and no fabricated events")
 check(not Observations.valid_journal(Observations.fresh("../not-an-opaque-profile")),"journal profile linkage rejects path-like identifiers")
 var store=Save.new();var initial=store.fresh()
 check(store.save(PATH,initial),"canonical initial journey commits")
 var first=report("profile_contract_a")
 check(first.ok and first.events.is_empty() and first.baseline.initialized,"first committed snapshot creates baseline only")
 check(first.suggested_activities.is_empty(),"legacy or initial progress never creates observation-based suggestions")
 check(store.save(PATH,initial) and report("profile_contract_a").events.is_empty(),"idempotent primary save produces no observation")
 var accepted=initial.duplicate(true);accepted.quest_flags=[Quest.ACCEPTED]
 var bytes=FileAccess.get_file_as_bytes(PATH)
 store.fault="write"
 check(not store.save(PATH,accepted) and FileAccess.get_file_as_bytes(PATH)==bytes and report("profile_contract_a").events.is_empty(),"failed primary write cannot generate a quest observation")
 store.fault=""
 check(store.save(PATH,accepted),"real accepted-task snapshot durably commits")
 var actual=report("profile_contract_a")
 check(actual.ok and actual.events.size()==1 and actual.events[0].activity_id=="B01/"+Quest.ACCEPTED,"post-commit hook records only the actual new quest flag")
 var event=actual.events[0]
 check(Observations.valid_event(event) and event.game_id==Observations.GAME_ID and event.action=="quest_commit" and event.result=="saved" and not event.help.requested,"observation contains validated action/result and explicit non-help context")
 check(event.timestamp_utc=="2026-10-30T12:00:00Z" and not event.session_id.is_empty() and not event.attempt_id.is_empty() and not event.event_id.is_empty(),"event preserves UTC, version and opaque session/attempt/event identities")
 check(actual.context.skill_mapping_meaning=="tasarım amacı, ölçüm değil" and not actual.context.canonical_skill_ids_known,"project-local skill tags are explicitly proposed design intent, never measured development")
 check(actual.suggested_activities.size()==1 and actual.suggested_activities[0].chapter_id=="B01","suggested revisit content comes only from an actual recorded chapter")
 var journal_path=rows[PATH].journal_path
 var journal_bytes=FileAccess.get_file_as_bytes(journal_path)
 check(store.save(PATH,accepted) and FileAccess.get_file_as_bytes(journal_path)==journal_bytes and report("profile_contract_a").events.size()==1,"same snapshot cannot duplicate the event or rewrite identical journal bytes")
 var lit=accepted.duplicate(true);lit.quest_flags.append(Quest.LIGHTS[0])
 observer.documents.fault="write"
 check(store.save(PATH,lit) and store.last_error=="" and store.read_file(PATH).data.quest_flags.has(Quest.LIGHTS[0]),"journal write failure cannot reject or roll back a committed primary journey")
 check(FileAccess.get_file_as_bytes(journal_path)==journal_bytes,"failed journal write preserves prior journal bytes")
 var pending=report("profile_contract_a")
 check(not pending.ok and pending.pending==1,"journal error is visible with a bounded pending observation")
 var lit_bytes=FileAccess.get_file_as_bytes(PATH);observer.documents.fault=""
 var retried=report("profile_contract_a")
 check(retried.ok and retried.events.size()==2 and retried.pending==0 and FileAccess.get_file_as_bytes(PATH)==lit_bytes,"retry persists the original pending event without touching primary bytes")
 observer.observe_snapshot(PATH,accepted,lit)
 check(report("profile_contract_a").events.size()==2,"stable session-attempt-activity key deduplicates repeated delivery")
 check(not observer.record_help({"path":PATH,"chapter_id":"B02","task_id":"wrong_context"}).ok,"help cannot claim a different saved chapter context")
 var help={"path":PATH,"chapter_id":"B01","activity_id":"lantern_task_help","kind":"task_hint","request_id":"help-request-1"}
 var before_help=FileAccess.get_file_as_bytes(PATH)
 check(observer.record_help(help).ok and report("profile_contract_a").events.size()==3,"explicit displayed help records its real request")
 observer.record_help(help)
 check(report("profile_contract_a").events.size()==3,"same help request token is idempotent")
 help.request_id="help-request-2";observer.record_help(help)
 var help_report=report("profile_contract_a")
 check(help_report.events.size()==4 and help_report.events[-1].help.requested and help_report.events[-1].result=="shown" and FileAccess.get_file_as_bytes(PATH)==before_help,"separate actual help request is recorded without changing journey progress")
 var migrated=store.migrate_onboarding(lit)
 check(migrated.ok and migrated.migrated and store.save(PATH,migrated.data),"legacy onboarding compatibility snapshot commits")
 check(report("profile_contract_a").events.size()==4,"compatibility HOME flags never appear as performed tutorial events")
 var restarted=migrated.data.duplicate(true);restarted.quest_flags.erase(Quest.LIGHTS[0])
 store.save(PATH,restarted)
 var old_attempt=report("profile_contract_a").events[1].attempt_id
 var again=restarted.duplicate(true);again.quest_flags.append(Quest.LIGHTS[0]);store.save(PATH,again)
 var repeated=report("profile_contract_a")
 check(repeated.events.size()==5 and repeated.events[-1].attempt_id!=old_attempt,"real reset-and-repeat receives a distinct attempt context without fake failure counts")
 var seed=full_fixture()
 check(store.valid(seed) and store.save(SEEDED,seed) and report("profile_contract_seeded").events.is_empty(),"prepopulated legacy/import snapshot establishes baseline with no historical backfill")
 var skipped=store.fresh_journey();store.save(SECOND,skipped)
 skipped.quest_flags=Quest.HOME_EVENTS.duplicate();skipped.chapter_id="B01";skipped.geometry="islands-v6";skipped.checkpoint_id="b01.island.0";skipped.settings.onboarding_origin="user-skipped-v1"
 check(store.save(SECOND,skipped) and report("profile_contract_b").events.is_empty(),"explicit tutorial skip does not fabricate walking or jump observations")
 check(report("profile_contract_b").events.is_empty() and report("profile_contract_a").events.size()==5,"registered profiles retain separate observation histories")
 var count_before=report("profile_contract_a").events.size()
 store.save(FOREIGN,accepted)
 set_meta("replay_primary_path",PATH);store.save(Replay.new().replay_path(PATH),lit);remove_meta("replay_primary_path")
 check(report("profile_contract_a").events.size()==count_before and observer.observe_snapshot(FOREIGN,initial,accepted).reason=="unregistered_path","foreign/test and unregistered replay slots cannot write a primary profile journal")
 check(observer.record_help({"path":FOREIGN,"chapter_id":"B01"}).reason=="unregistered_path","foreign help is not silently attributed to an active child")
 var state=Quest.new()
 for id in Quest.EVENTS:
  if id==Quest.SUMMIT_COMPLETE:break
  state.apply(id)
 var summit=store.fresh();summit.chapter_id="B04";summit.geometry="shared-v16";summit.checkpoint_id="b04.bank.0"
 summit.quest_flags=state.flags.duplicate();summit.party_ids=state.party_ids();summit.summit=Save.Summit.fresh()
 check(store.save(SUMMIT,summit) and report("profile_contract_summit").events.is_empty(),"B04 fixture task history remains baseline only")
 var summit_next=summit.duplicate(true);summit_next.summit.lantern="accepted";store.save(SUMMIT,summit_next)
 check(report("profile_contract_summit").events.size()==1 and report("profile_contract_summit").events[0].activity_id=="B04/summit.lantern.accepted","actual B04 saved internal quest delta receives its precise task context")
 summit_next.summit.lantern="lit";store.save(SUMMIT,summit_next)
 var summit_report=report("profile_contract_summit")
 check(summit_report.events.size()==2 and not summit_report.events.any(func(row):return row.activity_id=="B04/summit.lantern.prepared"),"an observed stage jump never backfills unobserved intermediate task states")
 var corrupt_source=FileAccess.open(SECOND,FileAccess.WRITE);corrupt_source.store_string("corrupt primary");corrupt_source.close()
 var after_recovery=skipped.duplicate(true);after_recovery.quest_flags.append(Quest.ACCEPTED)
 check(store.save(SECOND,after_recovery) and report("profile_contract_b").events.size()==1 and report("profile_contract_b").events[0].activity_id=="B01/"+Quest.ACCEPTED,"validated backup supplies the previous context for a genuine post-recovery commit without tutorial backfill")
 var history_before=report("profile_contract_a").events.size()
 var before_transaction=store.read_file(PATH).data
 observer.suspend_path(PATH);observer.suspend_path(PATH)
 store.save(PATH,accepted)
 observer.resume_path(PATH)
 store.save(PATH,before_transaction)
 observer.resume_path(PATH)
 check(report("profile_contract_a").events.size()==history_before,"nested restart/rollback suppression cannot fabricate restored quest gains")
 var attempt_result=observer.begin_attempt(PATH,"B01")
 check(attempt_result.ok and attempt_result.recorded==0 and not attempt_result.attempt_id.is_empty() and report("profile_contract_a").events.size()==history_before,"successful restart can explicitly begin an attempt without emitting fake quest events")
 check(observer.begin_attempt(FOREIGN,"B01").reason=="unregistered_path","foreign or replay attempt starts remain unregistered no-ops")
 var journal=Docs.new().load_document(journal_path,Observations.valid).data
 var rebound=Observations.rebind(journal,"profile_imported_new")
 check(Observations.valid(rebound) and rebound.profile_id=="profile_imported_new" and rebound.records==journal.records and journal.profile_id=="profile_contract_a","profile import rebind preserves anonymous facts and leaves source linkage unchanged")
 var invalid=journal.duplicate(true);invalid.records[0].action="development_mastered"
 check(not Observations.valid_journal(invalid),"journal validation rejects unsupported developmental result semantics")
 invalid=journal.duplicate(true);invalid.records[0].skill_ids=["company.canonical.empathy"]
 check(not Observations.valid_journal(invalid),"unknown company skill identifiers cannot masquerade as canonical measurements")
 invalid=journal.duplicate(true);invalid.records[0].medical_score=42
 check(not Observations.valid_journal(invalid),"unknown extra child-data fields are rejected")
 invalid=journal.duplicate(true);invalid.records.append(invalid.records[0].duplicate(true))
 check(not Observations.valid_journal(invalid),"duplicate event identifiers are rejected on journal import")
 invalid=journal.duplicate(true);invalid.records[0].timestamp_utc="yesterday"
 check(not Observations.valid_journal(invalid),"journal import requires explicit UTC event timestamps")
 store.save(CAPPED,initial)
 for i in Observations.MAX_RECORDS+7:
  var synthetic=observer._event("profile_contract_cap","B01","synthetic_capacity_fixture","help_opened",{"requested":true,"kind":"task_hint","request_id":"capacity-"+str(i)})
  observer._queue("profile_contract_cap",synthetic)
 var capped=report("profile_contract_cap")
 check(capped.ok and capped.events.size()==Observations.MAX_RECORDS and capped.truncated and capped.dropped_records==7,"journal and pending capacity keep only500 observations and expose truncation")
 check(Observations.valid_journal(Docs.new().load_document(rows[CAPPED].journal_path,Observations.valid).data),"bounded journal remains checksum-valid and schema-valid")
 observer.documents.fault="write"
 observer.record_help({"path":SECOND,"chapter_id":"B01","task_id":"pending-before-delete","request_id":"delete-request"})
 observer.suspend_path(SECOND)
 check(observer._pending.has("profile_contract_b") and observer._seen.has("profile_contract_b"),"deletion fixture contains unflushed local evidence")
 rows.erase(SECOND)
 observer.forget_profile("profile_contract_b")
 check(not observer._pending.has("profile_contract_b") and not observer._pending_baselines.has("profile_contract_b") and not observer._pending_dropped.has("profile_contract_b") and not observer._seen.has("profile_contract_b") and not observer._attempts.keys().any(func(key):return str(key).begins_with("profile_contract_b/")) and not observer._suspended.has(SECOND),"profile deletion forgets pending, seen, attempts, baselines and suspended context")
 observer.documents.fault=""
 check(not observer.report_for("profile_contract_b").ok,"deleted profile cannot flush or expose cached evidence")
 var journal_before=FileAccess.get_file_as_bytes(journal_path)
 var mismatch=journal.duplicate(true);mismatch.profile_id="profile_someone_else"
 var docs=Docs.new();docs.save(journal_path,mismatch,Observations.valid)
 var primary_before=FileAccess.get_file_as_bytes(PATH)
 var wrong_profile=report("profile_contract_a")
 check(not wrong_profile.ok and wrong_profile.reason=="journal_profile_mismatch" and wrong_profile.events.is_empty(),"foreign profile linkage cannot leak journal records into another child report")
 check(FileAccess.get_file_as_bytes(PATH)==primary_before,"journal profile mismatch never changes primary journey bytes")
 var file=FileAccess.open(journal_path,FileAccess.WRITE);file.store_buffer(journal_before);file.close()
 var retry_report=report("profile_contract_a")
 check(retry_report.ok and retry_report.events.size()==history_before,"restoring validated journal bytes recovers the same factual report")
 var latest=retry_report.events.size()
 var old_journal=Docs.new().read_file(journal_path+".bak",Observations.valid)
 if old_journal.ok and old_journal.data.profile_id=="profile_contract_a":
  file=FileAccess.open(journal_path,FileAccess.WRITE);file.store_string("broken journal");file.close()
  var recovered=report("profile_contract_a")
  check(recovered.ok and recovered.recovered_from_backup and recovered.events.size()<=latest,"valid journal backup is read with an explicit recovery context")
 for row in rows.values():clean(row.journey_path);clean(row.journal_path)
 clean(SECOND);clean(SECOND+".observations")
 clean(FOREIGN);clean(Replay.new().replay_path(PATH))
 observer.queue_free();await process_frame
 if is_instance_valid(previous_observer):previous_observer.name="CatpatObservations"
 print("OBSERVATION CONTRACT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
