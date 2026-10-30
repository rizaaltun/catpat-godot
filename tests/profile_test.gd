extends SceneTree
const Profiles=preload("res://scripts/core/profile_service.gd")
const Documents=preload("res://scripts/core/local_document_store.gd")
const Store=preload("res://scripts/core/save_service.gd")
const BASE="user://profile-contract-fictional"
const LEGACY=BASE+"/legacy.json"
var checks=0
var failures=0
var service
class ObserverFake extends Node:
 var forgotten:Array=[]
 func forget_profile(id:String):forgotten.append(id)
func _initialize():
 set_meta("journey_save_path",BASE+"/explicit-host.json")
 call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func remove_directory(path:String):
 var directory=DirAccess.open(path)
 if not directory:return
 for name in directory.get_files():DirAccess.remove_absolute(path+"/"+name)
 for name in directory.get_directories():remove_directory(path+"/"+name)
 DirAccess.remove_absolute(path)
func raw(path:String)->PackedByteArray:return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
func index_bytes()->PackedByteArray:return raw(service.index_path())
func journey_files()->Array:
 var directory=DirAccess.open(BASE+"/profiles")
 return [] if not directory else Array(directory.get_files()).filter(func(file):return file.ends_with("-journey.json") or file.ends_with("-journal.json"))
func valid_sample(data:Dictionary)->bool:return data.size()==1 and data.get("value") is String
func run():
 remove_directory(BASE);DirAccess.make_dir_recursive_absolute(BASE)
 var documents=Documents.new();var path=BASE+"/atomic.json"
 check(documents.save(path,{"value":"first"},valid_sample),"generic atomic JSON stores checksum-validated document")
 var first=raw(path)
 check(documents.save(path,{"value":"second"},valid_sample) and raw(path+".bak")==first,"atomic document backs up valid previous bytes")
 var second=raw(path)
 for fault in ["write","verify","backup","rename"]:
  documents.fault=fault
  check(not documents.save(path,{"value":"rejected"},valid_sample) and raw(path)==second,"atomic "+fault+" failure preserves primary bytes")
 documents.fault="";documents.write_text(path,"fictional-corrupt-primary")
 var recovered=documents.load_document(path,valid_sample)
 check(recovered.ok and recovered.recovered and recovered.data.value=="second","valid backup recovers after failed rename then corrupt primary")
 check(documents.save(path,{"value":"restored"},valid_sample),"recovered document can be committed")
 var damaged=Array(DirAccess.get_files_at(BASE)).filter(func(file):return file.begins_with("atomic.json.damaged-"))
 check(damaged.size()==1 and FileAccess.get_file_as_string(BASE+"/"+damaged[0])=="fictional-corrupt-primary","corrupt source bytes remain in immutable hash-named copy")
 check(not documents.decode('{"payload":{"value":"x"},"sha256":"wrong"}',valid_sample).ok and not documents.save(path,{"unexpected":true},valid_sample),"checksum and semantic payload mismatches are rejected")
 var uninitialized=Profiles.new();uninitialized.configure(BASE+"/lookup-only",BASE+"/lookup-legacy.json")
 check(uninitialized.profile_for_path(BASE+"/lookup-legacy.json").is_empty() and uninitialized.profile_by_id("0".repeat(32)).is_empty() and not DirAccess.dir_exists_absolute(BASE+"/lookup-only"),"observer profile lookup is read-only and never bootstraps a missing index")
 uninitialized.free()
 var existing_observer=root.get_node_or_null("CatpatObservations")
 if existing_observer:existing_observer.name="OriginalObservationAutoloadForProfileTest"
 var initializing=Profiles.new();initializing.configure(BASE+"/initializing",BASE+"/no-legacy.json");root.add_child(initializing)
 var live_observer=load("res://scripts/core/observation_service.gd").new();live_observer.name="CatpatObservations"
 var lookup_probe={"count":0,"reentrant_guard":false}
 live_observer.profile_resolver=func(path):
  lookup_probe.count+=1
  lookup_probe.reentrant_guard=initializing.ensure_loaded().get("reason","")=="initializing"
  return initializing.profile_for_path(path)
 live_observer.profile_id_resolver=initializing.profile_by_id
 root.add_child(live_observer)
 var initialized=initializing.ensure_loaded()
 var initialized_rows=initializing.list_profiles()
 check(initialized.ok and initialized_rows.size()==1 and lookup_probe.count==1 and lookup_probe.reentrant_guard and not FileAccess.file_exists(initialized_rows[0].journal_path),"live observer during initial journey commit performs one guarded lookup without recursion, extra travellers or historical observations")
 var generated=Array(DirAccess.get_files_at(BASE+"/initializing")).filter(func(file):return file.ends_with("-journey.json"))
 check(generated.size()==1,"reentrant initialization writes exactly one fictional journey file")
 root.remove_child(live_observer);live_observer.free();initializing.queue_free()
 if existing_observer:existing_observer.name="CatpatObservations"
 var store=Store.new();var legacy=store.fresh()
 # Canonical event spelling comes from the production registry.
 var quest=preload("res://scripts/core/quest_state.gd").new();quest.apply(quest.ACCEPTED);quest.apply(quest.LIGHTS[0]);legacy.quest_flags=quest.flags
 check(store.save(LEGACY,legacy),"fictional existing legacy journey saves")
 var legacy_bytes=raw(LEGACY)
 set_meta("journey_save_path",BASE+"/explicit-host.json")
 service=Profiles.new();service.configure(BASE+"/profiles",LEGACY);root.add_child(service)
 var observer=ObserverFake.new();root.add_child(observer)
 service.observations_resolver=func():return observer
 check(str(get_meta("journey_save_path"))==BASE+"/explicit-host.json" and not FileAccess.file_exists(service.index_path()),"autoload ready preserves explicit host path without initializing unrelated data")
 check(service.ensure_loaded().ok,"profile index initializes around existing legacy journey")
 var original=service.active_profile();var original_id=original.profile_id
 check(original.journey_path==LEGACY and raw(LEGACY)==legacy_bytes and original.label=="Yolcu 1","opaque first profile maps legacy path without copying or resetting bytes")
 check(service.profile_by_id(original_id)==original and service.profile_for_path(LEGACY)==original,"host and journal resolve canonical profile by ID or journey path")
 check(not service.activate_profile("../../arbitrary").ok and not service.delete_profile("missing").ok and not service.export_bundle("missing").ok,"unknown IDs cannot switch or delete arbitrary files")
 var before=index_bytes();var before_files=journey_files()
 for fault in ["journey_write","index_write","index_rename","index_backup"]:
  service.fault=fault
  check(not service.create_profile().ok and index_bytes()==before and service.list_profiles().size()==1 and journey_files()==before_files,"create "+fault+" rollback leaves canonical index and existing journey isolated")
 service.fault=""
 var created=service.create_profile()
 check(created.ok and created.profile.profile_id!=original_id and created.profile.label=="Yolcu 2","new traveller receives fresh opaque ID and automatic local label")
 var second_profile=created.profile;var second_bytes=raw(second_profile.journey_path)
 check(store.load_progress(second_profile.journey_path).data.chapter_id=="B00" and raw(LEGACY)==legacy_bytes,"new traveller starts at real B00 without changing legacy progress")
 check(service.active_profile().profile_id==second_profile.profile_id and str(get_meta("journey_save_path"))==second_profile.journey_path,"explicit create switches active context without changing scenes")
 check(service.activate_profile(original_id).ok and raw(second_profile.journey_path)==second_bytes and raw(LEGACY)==legacy_bytes,"profile switch preserves both isolated journey bytes")
 var index_record=service.index.duplicate(true);index_record.profiles[0].journey_path="user://unrelated.json"
 check(not service.valid_index(index_record),"index rejects non-owned journey path injection")
 index_record=service.index.duplicate(true);index_record.profiles[0].label="A child's name"
 check(not service.valid_index(index_record),"profile schema accepts automatic traveller labels only")
 check(not service._timestamp_valid("2026-02-31T00:00:00"),"invalid calendar timestamp cannot enter index or bundle")
 if not ResourceLoader.exists("res://scripts/core/observation_service.gd"):
  check(false,"production observation schema dependency is available")
  service.queue_free();await process_frame;remove_directory(BASE);quit(1);return
 var export_result=service.export_bundle(original_id)
 check(export_result.ok and export_result.bundle.journal.records.is_empty() and not export_result.bundle.journal.baseline.initialized,"exporting legacy journey never fabricates past observations")
 var bundle=export_result.bundle
 var observations=load("res://scripts/core/observation_service.gd").new()
 var observed=observations._event(original_id,"B01","controls_hint","help_opened",{"requested":true,"kind":"controls_hint","request_id":"fictional-request-1"})
 bundle.journal.baseline={"initialized":true,"chapter_id":"B01","content_version":"fictional-v1","timestamp_utc":"2026-10-30T10:00:00Z"}
 bundle.journal.records=[observed];observations.free()
 for field in ["profile_id","journey","journal","exported_at"]:
  var invalid=bundle.duplicate(true)
  if field=="profile_id":invalid[field]="0".repeat(32)
  elif field=="journey":invalid[field].chapter_id="UNKNOWN"
  elif field=="journal":invalid[field].records=[{"invented":"observation"}]
  else:invalid[field]="not-a-timestamp"
  before=index_bytes()
  check(not service.import_bundle(invalid).ok and index_bytes()==before,"import rejects invalid "+field+" without overwriting profile index")
 var injected=bundle.duplicate(true);injected.journey_path="user://unrelated.json"
 check(not service.import_bundle(injected).ok,"bundle cannot inject source or destination filesystem paths")
 before=index_bytes();before_files=journey_files()
 for fault in ["journey_write","journal_write","index_write","index_rename","index_backup"]:
  service.fault=fault
  check(not service.import_bundle(bundle).ok and index_bytes()==before and journey_files()==before_files,"import "+fault+" failure rolls back newly allocated files without touching source")
 service.fault=""
 var imported=service.import_bundle(bundle)
 check(imported.ok and imported.profile.profile_id!=original_id and imported.profile.profile_id!=second_profile.profile_id,"import creates a third opaque traveller rather than overwriting source ID")
 var exported_import=service.export_bundle(imported.profile.profile_id)
 check(exported_import.ok and exported_import.bundle.journey==bundle.journey and exported_import.bundle.journal.profile_id==imported.profile.profile_id and exported_import.bundle.journal.records==bundle.journal.records and exported_import.bundle.journal.baseline==bundle.journal.baseline,"import preserves event/session/attempt IDs and baseline facts while rebinding only profile identity")
 check(raw(LEGACY)==legacy_bytes and raw(second_profile.journey_path)==second_bytes,"export/import leaves both original journey files byte-identical")
 check(service.import_json("[]").reason=="invalid_bundle" and service.export_json(original_id).ok,"bounded JSON import/export API rejects non-object input")
 before=index_bytes();var imported_bytes=raw(imported.profile.journey_path)
 service.fault="delete_stage"
 check(not service.delete_profile(imported.profile.profile_id).ok and index_bytes()==before and raw(imported.profile.journey_path)==imported_bytes and service.profile_by_id(imported.profile.profile_id)==imported.profile,"delete staging failure restores index, active profile and existing files")
 service.fault="delete_stage_after_first"
 check(not service.delete_profile(imported.profile.profile_id).ok and index_bytes()==before and raw(imported.profile.journey_path)==imported_bytes and service.export_bundle(imported.profile.profile_id).ok,"partial staged delete restores journey and journal before rolling index back")
 service.fault="index_backup"
 check(not service.delete_profile(imported.profile.profile_id).ok and index_bytes()==before and raw(imported.profile.journey_path)==imported_bytes,"delete index failure preserves original data before removal")
 check(observer.forgotten.is_empty(),"failed index and staged delete never erase observation caches for a restored traveller")
 service.fault=""
 check(service.delete_profile(imported.profile.profile_id).ok and service.profile_by_id(imported.profile.profile_id).is_empty() and not FileAccess.file_exists(imported.profile.journey_path) and not FileAccess.file_exists(imported.profile.journal_path),"confirmed delete removes profile journey and journal after durable index commit")
 check(observer.forgotten==[imported.profile.profile_id],"successful durable delete notifies observation service exactly once with opaque profile ID")
 var backup_index=documents.read_file(service.index_path()+".bak",service.valid_index)
 check(backup_index.ok and not backup_index.data.profiles.any(func(profile):return profile.profile_id==imported.profile.profile_id),"backup index cannot resurrect deleted traveller")
 var pending_profile=service.import_bundle(bundle).profile
 service.fault="cleanup_unlink_after_first"
 var pending_delete=service.delete_profile(pending_profile.profile_id)
 check(pending_delete.ok and pending_delete.cleanup_pending and pending_delete.pending_count==1 and service.profile_by_id(pending_profile.profile_id).is_empty(),"partial final unlink failure removes profile from index but reports durable cleanup pending")
 check(observer.forgotten==[imported.profile.profile_id,pending_profile.profile_id],"cleanup-pending deletion still forgets removed traveller caches before any retry")
 var tombstones=documents.load_document(service.cleanup_path(),service.valid_cleanup)
 check(tombstones.ok and tombstones.data.entries.size()==1 and not tombstones.data.entries[0].has("path"),"cleanup tombstone persists opaque identity instead of arbitrary delete paths")
 var startup=Profiles.new();startup.configure(BASE+"/profiles",LEGACY);startup.fault="cleanup_unlink"
 remove_meta("journey_save_path");root.add_child(startup)
 check(startup.retry_cleanup().pending_count==1,"restarted service retains cleanup instructions while unlink remains unavailable")
 startup.fault=""
 check(startup.retry_cleanup().ok and startup.retry_cleanup().pending_count==0 and not startup._owned_paths(pending_profile).size(),"successful idempotent retry removes staged files and clears durable tombstone")
 check(raw(LEGACY)==legacy_bytes and raw(second_profile.journey_path)==second_bytes,"cleanup retry preserves other travellers' journey bytes")
 var clean_cleanup=raw(service.cleanup_path())
 documents.write_text(service.cleanup_path(),"fictional-malformed-cleanup")
 documents.write_text(service.cleanup_path()+".bak","fictional-malformed-cleanup-backup")
 var safe_bytes=raw(second_profile.journey_path)
 check(not service.retry_cleanup().ok and raw(second_profile.journey_path)==safe_bytes and not service.delete_profile(second_profile.profile_id).ok,"malformed cleanup copies block deletion and never touch unrelated profile data")
 documents.write_text(service.cleanup_path(),clean_cleanup.get_string_from_utf8());documents.write_text(service.cleanup_path()+".bak",clean_cleanup.get_string_from_utf8())
 var injected_cleanup={"schema_version":1,"entries":[{"profile_id":original_id,"legacy_journey":true,"token":"0".repeat(16),"created_at":"2026-10-30T10:00:00"}]}
 check(documents.save(service.cleanup_path(),injected_cleanup,service.valid_cleanup) and not service.retry_cleanup().ok and raw(LEGACY)==legacy_bytes,"stale tombstone cannot delete a traveller still present in canonical index")
 documents.save(service.cleanup_path(),{"schema_version":1,"entries":[]},service.valid_cleanup)
 startup.queue_free();await process_frame
 while service.list_profiles().size()<Profiles.MAX_PROFILES:check(service.create_profile().ok,"additional traveller fits bounded local profile capacity")
 before=index_bytes()
 check(service.create_profile().reason=="profile_limit" and service.import_bundle(bundle).reason=="profile_limit" and index_bytes()==before,"six-profile limit blocks new/import allocation without mutation")
 var all=service.list_profiles()
 for profile in all:
  var deleted=service.delete_profile(profile.profile_id)
  check(deleted.ok,"profile removal succeeds within fictional fixture")
 check(service.list_profiles().size()==1 and service.active_profile().profile_id not in all.map(func(profile):return profile.profile_id) and store.load_progress(service.active_profile().journey_path).data.chapter_id=="B00","deleting final traveller creates an isolated fresh B00 replacement")
 var active=service.active_profile();var valid_index_bytes=index_bytes()
 documents.write_text(service.index_path(),"fictional-index-corruption")
 var reload=Profiles.new();reload.configure(BASE+"/profiles",LEGACY)
 check(reload.ensure_loaded().ok and reload.active_profile()==active,"profile index recovers latest active traveller from validated mirrored backup")
 documents.write_text(service.index_path()+".bak","fictional-both-corrupt")
 var broken=Profiles.new();broken.configure(BASE+"/profiles",LEGACY)
 check(not broken.ensure_loaded().ok and raw(service.index_path())=="fictional-index-corruption".to_utf8_buffer(),"two invalid index copies block initialization and preserve corrupt bytes")
 # Actual _ready entry points use only the fictional fixture tree context.
 remove_meta("journey_save_path")
 set_meta("profile_context_error","stale-fictional-error")
 var corrupt_before=raw(service.index_path());var corrupt_backup_before=raw(service.index_path()+".bak")
 var blocked=Profiles.new();blocked.configure(BASE+"/profiles",LEGACY);root.add_child(blocked)
 check(has_meta("profile_context_error") and str(get_meta("profile_context_error"))=="no_valid_document" and not has_meta("journey_save_path") and raw(service.index_path())==corrupt_before and raw(service.index_path()+".bak")==corrupt_backup_before,"corrupt primary and backup block autoload context, expose error and preserve all index bytes")
 documents.write_text(service.index_path()+".bak",valid_index_bytes.get_string_from_utf8())
 var recovering=Profiles.new();recovering.configure(BASE+"/profiles",LEGACY);root.add_child(recovering)
 check(not has_meta("profile_context_error") and str(get_meta("journey_save_path"))==active.journey_path and recovering.active_profile()==active and raw(service.index_path())==corrupt_before,"autoload restores valid backup context and clears stale error without rewriting invalid primary")
 set_meta("journey_save_path",BASE+"/foreign-host.json");set_meta("profile_context_error","foreign-host-owned-error")
 var foreign=Profiles.new();foreign.configure(BASE+"/foreign-profiles",BASE+"/foreign-legacy.json");root.add_child(foreign)
 check(str(get_meta("journey_save_path"))==BASE+"/foreign-host.json" and str(get_meta("profile_context_error"))=="foreign-host-owned-error" and not FileAccess.file_exists(foreign.index_path()),"explicit foreign host context skips profile initialization and leaves host path and error untouched")
 blocked.queue_free();recovering.queue_free();foreign.queue_free()
 documents.write_text(service.index_path(),valid_index_bytes.get_string_from_utf8())
 service.queue_free();observer.queue_free();reload.free();broken.free();await process_frame
 for key in ["journey_save_path","journal_save_path","active_profile_id","profile_context_error"]:
  if has_meta(key):remove_meta(key)
 remove_directory(BASE)
 print("PROFILE CONTRACT: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
