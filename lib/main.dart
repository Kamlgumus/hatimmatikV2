import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:home_widget/home_widget.dart';

// Standart mushaf: her surenin baslangic sayfasi (1-604)
const surahPages = [1,2,50,77,106,128,151,177,187,208,221,235,249,255,262,267,282,293,305,312,322,332,342,350,359,367,377,385,396,404,411,415,418,428,434,440,446,453,458,467,477,483,489,496,499,502,507,511,515,518,520,523,526,528,531,534,537,542,545,549,551,553,554,556,558,560,562,564,566,568,570,572,574,575,577,578,580,582,583,585,586,587,587,589,590,591,591,592,593,594,595,595,596,596,597,597,598,598,599,599,600,600,601,601,601,602,602,602,603,603,603,604,604,604];
const surahNames = ['Fatiha','Bakara','Âl-i İmrân','Nisâ','Mâide','En\u0027âm','A\u0027râf','Enfâl','Tevbe','Yûnus','Hûd','Yûsuf','Ra\u0027d','İbrâhîm','Hicr','Nahl','İsrâ','Kehf','Meryem','Tâhâ','Enbiyâ','Hac','Mü\u0027minûn','Nûr','Furkân','Şuarâ','Neml','Kasas','Ankebût','Rûm','Lokmân','Secde','Ahzâb','Sebe\u0027','Fâtır','Yâsîn','Sâffât','Sâd','Zümer','Mü\u0027min','Fussilet','Şûrâ','Zuhruf','Duhân','Câsiye','Ahkâf','Muhammed','Fetih','Hucurât','Kaf','Zâriyât','Tûr','Necm','Kamer','Rahmân','Vâkıa','Hadîd','Mücâdele','Haşr','Mümtehine','Saff','Cumu\u0027a','Münâfikûn','Tegâbün','Talâk','Tahrîm','Mülk','Kalem','Hâkka','Mââric','Nûh','Cin','Müzzemmil','Müddessir','Kıyamet','İnsân','Mürselât','Nebe','Nâziât','Abese','Tekvîr','İnfitâr','Mutaffifîn','İnşikâk','Bürûc','Târık','A\u0027lâ','Ğâşiye','Fecr','Beled','Şems','Leyl','Duhâ','İnşirâh','Tîn','Alak','Kadir','Beyyine','Zelzele','Âdiyât','Kāria','Tekâsür','Asr','Hümeze','Fîl','Kureyş','Mâûn','Kevser','Kâfirûn','Nasr','Tebbet','İhlâs','Felak','Nâs'];

int surahOfPage(int p){int s=0;for(int i=0;i<114;i++){if(surahPages[i]<=p)s=i;}return s;}

final notif = FlutterLocalNotificationsPlugin();
final player = AudioPlayer();
const kStreak='streak', kLast='last', kPage='page', kDays='days', kDone='done';
int streak=0, curPage=1, daysEvery=1;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await notif.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings()));
  await notif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  final p = await SharedPreferences.getInstance();
  streak = p.getInt(kStreak) ?? 0;
  curPage = p.getInt(kPage) ?? 1;
  daysEvery = p.getInt(kDays) ?? 0; // 0 = onboarding goster
  await checkStreak(p);
  runApp(const Hatimmatik());
}

Future<void> checkStreak(SharedPreferences p) async {
  final last = p.getString(kLast);
  final today = DateTime.now().toString().substring(0,10);
  if (p.getString(kDone) == today) return;
  if (last != null && last != today) {
    final diff = DateTime.parse(today).difference(DateTime.parse(last)).inDays;
    if (diff > daysEvery) { streak = 0; await p.setInt(kStreak, 0); await updateWidget(p); }
  }
}

Future<void> updateWidget(SharedPreferences p) async {
  await HomeWidget.saveWidgetData('streak', streak);
  await HomeWidget.saveWidgetData('page', curPage);
  await HomeWidget.updateWidget(androidName: 'HatimWidgetProvider');
}

class Hatimmatik extends StatelessWidget {
  const Hatimmatik({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Hatimmatik', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3D2E)), useMaterial3: true),
    home: daysEvery == 0 ? const Onboarding() : const Home());
}

class Onboarding extends StatefulWidget { const Onboarding({super.key}); @override State<Onboarding> createState()=>_O(); }
class _O extends State<Onboarding> {
  int days=1;
  @override
  Widget build(BuildContext c)=>Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Text('🕌 Hatimmatik',style:TextStyle(fontSize:30,fontWeight:FontWeight.bold,color:Color(0xFF0B3D2E))),
    const SizedBox(height:8), const Text('Hatmini takip et, serini koru.',style:TextStyle(color:Colors.grey)),
    const SizedBox(height:28), const Text('Kaç günde bir Kur\u0027an okuyacaksın?'),
    const SizedBox(height:12),
    TextField(keyboardType:TextInputType.number,textAlign:TextAlign.center,
      decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'örn. 1'),
      onChanged:(v)=>days=int.tryParse(v)??1),
    const SizedBox(height:16),
    FilledButton(onPressed:()async{
      final p=await SharedPreferences.getInstance();
      await p.setInt(kDays,days); daysEvery=days;
      await scheduleNotif(days);
      if(c.mounted) Navigator.pushReplacement(c,MaterialPageRoute(builder:(_)=>const Home()));
    }, child:const Text('Başla 🚀'))]))));}

Future<void> scheduleNotif(int d) async {
  await notif.zonedSchedule(0,'🕌 Hatimmatik','Okuma zamanı! Serini koru 🔥',
    _next(d), const NotificationDetails(android:AndroidNotificationDetails('hatim','Hatimmatik',importance:Importance.high)),
    androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents:DateTimeComponents.time);
}
tz.TZDateTime _next(int d){final n=tz.TZDateTime.now(tz.local);var t=tz.TZDateTime(tz.local,n.year,n.month,n.day,20,0);
  if(!t.isAfter(n)) t=t.add(Duration(days:d)); return t;}

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState()=>_H(); }
class _H extends State<Home> {
  final ctrl = TextEditingController();
  bool playing=false;
  Future<void> save(int pg) async { final p=await SharedPreferences.getInstance();
    await p.setInt(kPage,pg); curPage=pg; await updateWidget(p); setState((){}); }
  Future<void> markRead() async { final p=await SharedPreferences.getInstance();
    final today=DateTime.now().toString().substring(0,10);
    if(p.getString(kDone)==today) return;
    await p.setString(kDone,today); await p.setString(kLast,today);
    streak++; await p.setInt(kStreak,streak); await updateWidget(p); setState((){}); }
  Future<void> togglePlay() async { final s=surahOfPage(curPage);
    if(!playing){ await player.setUrl('https://server8.mp3quran.net/afs/${(s+1).toString().padLeft(3,'0')}.mp3'); player.play(); }
    else player.pause(); setState(()=>playing=!playing); }
  @override
  Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('🕌 Hatimmatik'),backgroundColor:const Color(0xFF0B3D2E),foregroundColor:Colors.white),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(color:const Color(0xFF0B3D2E),child:Padding(padding:const EdgeInsets.all(20),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$streak',style:const TextStyle(fontSize:44,fontWeight:FontWeight.bold,color:Color(0xFFC9A227))),const Text('gün aralıksız seri 🔥',style:TextStyle(color:Colors.white70))]),
        const Text('📿',style:TextStyle(fontSize:44))]))),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('📖 Kaldığın Sayfa',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
        Text('Şu an ${curPage}. sayfadasın.',style:const TextStyle(color:Colors.grey)),
        const SizedBox(height:10), Row(children:[
          Expanded(child:TextField(controller:ctrl,keyboardType:TextInputType.number,textAlign:TextAlign.center,decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'Sayfa no (1-604)'))),
          const SizedBox(width:8),
          FilledButton(onPressed:()async{final pg=int.tryParse(ctrl.text)??0;
            if(pg<1||pg>604){ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('1-604 arası gir')));return;}
            await save(pg); ctrl.clear();},child:const Text('İşaretle'))])]))),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('🎧 Oku / Dinlet',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
        Text('Hoca: Mishary Rashid Alafasy — ${surahNames[surahOfPage(curPage)]} suresi',style:const TextStyle(color:Colors.grey,fontSize:12)),
        const SizedBox(height:10), Row(children:[
          Expanded(child:FilledButton.tonal(onPressed:togglePlay,child:Text(playing?'⏸ Durdur':'▶ Dinlemeyi Başlat'))),
          const SizedBox(width:8),
          Expanded(child:FilledButton(onPressed:markRead,child:const Text('✅ Bugün Okudum')))]),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:()=>launchUrl(Uri.parse('https://webdosya.diyanet.gov.tr/kuran/kuranikerim/dosyalar/document/kuran.pdf')),icon:const Icon(Icons.menu_book),label:const Text('Diyanet Mushaf PDF')))]))) ])));}