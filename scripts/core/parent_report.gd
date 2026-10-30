extends RefCounted
## Saved progress and forward-only observations remain separate evidence sources.
const Quest=preload("res://scripts/core/quest_state.gd")
static func chapters()->Array:
 return [
 {"id":"B00","name":"Davet ve Ev Önü","complete":Quest.HOME_EXIT,"events":Quest.HOME_EVENTS,"purpose":"Hareketi keşfetme ve bir yönergeyi deneme","support":"Yerde güvenli bir başlangıç ve varış noktası seçin. Oraya farklı yollarla nasıl gidilebileceğini birlikte anlatın."},
 {"id":"B01","name":"Fenerli Patika","complete":Quest.COMPLETE,"events":[Quest.ACCEPTED]+Quest.LIGHTS+[Quest.JOINED],"purpose":"Bir arkadaşın ihtiyacını dinleme ve yolu planlama","support":"Bir öyküdeki karakterin neye ihtiyaç duyduğunu sorun. Çocuğun kendi sözcükleriyle anlatmasına zaman tanıyın."},
 {"id":"B02","name":"Dostluk Deresi","complete":Quest.RIVER_COMPLETE,"events":Quest.RIVER_EVENTS,"purpose":"Parçaları bir araya getirme ve ortak bir çözüm kurma","support":"Oyuncaklarla küçük bir köprü tasarlayın. Hangi parçanın nerede işe yarayacağını birlikte konuşun."},
 {"id":"B03","name":"Papatya Bahçesi","complete":Quest.GARDEN_COMPLETE,"events":Quest.GARDEN_EVENTS,"purpose":"Birden fazla adımı izleme ve çevreye özen gösterme","support":"Bir bitkiye birlikte bakın. Önce ve sonra neler yapacağınızı çocuğun anlatmasını isteyin."},
 {"id":"B04","name":"Rüzgârlı Yamaç","complete":Quest.SUMMIT_COMPLETE,"events":[Quest.SUMMIT_COMPLETE],"purpose":"Önceki yardımları yeni bir geçişte kullanma","support":"Birlikte yapılan bir işi hatırlayın. Herkesin hangi katkıyı sunduğunu konuşun; doğru yanıt aramayın."},
 {"id":"B05","name":"Festival Alanı","complete":Quest.FESTIVAL_COMPLETE,"events":Quest.FESTIVAL_EVENTS,"purpose":"Arkadaşların katkılarını ortak bir sonuçta birleştirme","support":"Küçük bir sofra ya da oyun alanını birlikte hazırlayın. Herkes kendi katkısını seçebilsin."}
]
static func build(data:Dictionary,observation:Dictionary={})->Dictionary:
 var flags=data.get("quest_flags",[])
 var rows=[]
 var current=str(data.get("chapter_id","B00"))
 for chapter in chapters():
  var count=0
  for event in chapter.events:
   if event in flags:count+=1
  var status="Tamamlandı" if chapter.complete in flags else "Devam ediyor" if count>0 else "Başlamaya hazır" if current==chapter.id else "Henüz başlanmadı"
  if chapter.id=="B00":
   var origin=str(data.get("settings",{}).get("onboarding_origin",""))
   if origin=="legacy-bypass-v1":status="Önceki sürümden devam; öğretici oynanmadı"
   elif origin=="user-skipped-v1":status="Oyuncunun seçimiyle geçildi"
  var detail="%d kayıtlı görev adımı"%count
  if chapter.id=="B01":
   var lights=Quest.LIGHTS.filter(func(id):return id in flags).size()
   var motes=data.get("collectibles",[]).filter(func(id):return str(id).begins_with("b01.mote.")).size()
   detail="%d/3 fener · %d/5 ışık izi"%[lights,motes]
  rows.append({"id":chapter.id,"title":chapter.id+" "+chapter.name+" — "+status,"status":status,"detail":detail,"purpose":chapter.purpose,"support":chapter.support})
 var events=observation.get("events",[]) if observation.get("ok",false) else []
 var observed={}
 var help_count=0
 for event in events:
  var chapter=str(event.get("chapter_id",""))
  if chapter in ["B00","B01","B02","B03","B04","B05"]:observed[chapter]=true
  if event.get("action","")=="help_opened":help_count+=1
 return {"chapters":rows,"events":events,"observed_chapters":observed.keys(),"help_count":help_count,"observation_ok":observation.get("ok",false),"truncated":observation.get("truncated",false),"limit":"Bu kayıt, beceri gelişimini veya gerçek yaşam davranışını ölçmez.","no_trend":"Karşılaştırılabilir görev ve yeterli gözlem olmadan ilerleme yorumu yapılmaz. Oynanmayan alanlar zayıflık değildir."}
static func activity_label(event:Dictionary)->String:
 var activity=str(event.get("activity_id","")).get_slice("/",1)
 var labels={Quest.INVITATION:"Davetin açılması",Quest.WALK:"Ev önünde yürüyüş",Quest.SHORT_JUMP:"Kısa sıçrama denemesi",Quest.LONG_JUMP:"Basılı tutarak sıçrama denemesi",Quest.TUTORIAL_JUMP:"Öğretici geçişi",Quest.HOME_EXIT:"Ev önünden patikaya geçiş",Quest.ACCEPTED:"Porsuk ile ilk konuşmanın tamamlanması","light.A":"İlk fenerin yakılması","light.B":"Üst dal fenerinin yakılması","light.C":"Hareketli dal fenerinin yakılması",Quest.JOINED:"Porsuk'un yolculuğa katılması",Quest.COMPLETE:"Fenerli Patika çıkışı",Quest.RIVER_ACCEPTED:"Maymun ile ilk konuşmanın tamamlanması",Quest.PLANK:"Tahtanın taşınması",Quest.ROPE:"Halatın taşınması",Quest.SUPPLIED:"Köprü parçalarının birleştirilmesi",Quest.READY:"Köprünün hazırlanması",Quest.MONKEY:"Maymun'un yolculuğa katılması",Quest.RIVER_COMPLETE:"Dostluk Deresi çıkışı",Quest.GARDEN_ACCEPTED:"Pıtpıt ile ilk konuşmanın tamamlanması",Quest.TIE:"Bağın taşınması",Quest.RELEASED:"Sepetin serbest bırakılması",Quest.LOWERED:"Sepetin indirilmesi",Quest.BASKET:"Sepetin taşınması",Quest.GARDEN_SUPPLIED:"Bahçe parçalarının birleştirilmesi",Quest.PROTECTED:"Çiçeklerin korunması",Quest.RABBIT:"Pıtpıt'ın yolculuğa katılması",Quest.GARDEN_COMPLETE:"Papatya Bahçesi çıkışı",Quest.SUMMIT_COMPLETE:"Rüzgârlı Yamaç geçişi",Quest.FESTIVAL_LIGHT:"Festival ışıklarının hazırlanması",Quest.FESTIVAL_FLAGS:"Flamaların hazırlanması",Quest.FESTIVAL_FLOWERS:"Festival çiçeklerinin hazırlanması",Quest.FESTIVAL_COMPLETE:"Ortak festival finali"}
 return "Bölüm görevi için yardım ekranı" if event.get("action","")=="help_opened" else str(labels.get(activity,"Kaydedilmiş bölüm etkinliği"))
static func event_context(event:Dictionary,events:Array)->String:
 var sessions=[];var attempts=[]
 for record in events:
  if record.session_id not in sessions:sessions.append(record.session_id)
  if record.chapter_id==event.chapter_id and record.attempt_id not in attempts:attempts.append(record.attempt_id)
 return "Bu listede oturum %d · %s için deneme %d"%[sessions.find(event.session_id)+1,event.chapter_id,attempts.find(event.attempt_id)+1]
