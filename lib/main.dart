import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const paper = Color(0xFFEFEAE0), surf = Color(0xFFF8F5EE), ink = Color(0xFF1B1A17);
const mu = Color(0xFF5E5A50), ln = Color(0xFFD3CCBD), sg = Color(0xFF2E3B30);
const soft = Color(0xFFDDE5D6), terra = Color(0xFFA8532F);

TextStyle serif(double s, {bool it = false, FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: 'serif', fontSize: s, fontStyle: it ? FontStyle.italic : FontStyle.normal,
    fontWeight: w, color: ink, height: 1.3);

String ago(num t) {
  final m = ((DateTime.now().millisecondsSinceEpoch - t) / 60000).round();
  if (m < 1) return 'à l’instant';
  if (m < 60) return 'il y a $m min';
  if (m < 1440) return 'il y a ${(m / 60).round()} h';
  return 'il y a ${(m / 1440).round()} j';
}

void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

class R {
  final int s;
  final Map j;
  R(this.s, this.j);
  bool get ok => s >= 200 && s < 300;
  String get err => (j['err'] ?? 'Erreur').toString();
}

class Api {
  static String base = 'http://127.0.0.1:5000';
  static String cookie = '';
  static late SharedPreferences sp;

  static Future<void> init() async {
    sp = await SharedPreferences.getInstance();
    base = sp.getString('base') ?? base;
    cookie = sp.getString('cookie') ?? '';
  }

  static Future<void> setBase(String b) async {
    base = b.trim().replaceAll(RegExp(r'/+$'), '');
    await sp.setString('base', base);
  }

  static Future<void> clear() async {
    cookie = '';
    await sp.remove('cookie');
  }

  static Map<String, String> get h =>
      {'Content-Type': 'application/json', if (cookie.isNotEmpty) 'Cookie': cookie};

  static void grab(http.Response r) {
    final c = r.headers['set-cookie'];
    if (c == null) return;
    final m = RegExp(r'session=([^;]*)').firstMatch(c);
    if (m != null) {
      cookie = m.group(1)!.isEmpty ? '' : 'session=${m.group(1)}';
      sp.setString('cookie', cookie);
    }
  }

  static Future<R> call(String path, [Object? body]) async {
    try {
      final u = Uri.parse('$base/api/$path');
      final r = body == null
          ? await http.get(u, headers: h)
          : await http.post(u, headers: h, body: jsonEncode(body));
      grab(r);
      dynamic j;
      try {
        j = jsonDecode(utf8.decode(r.bodyBytes));
      } catch (_) {
        j = {};
      }
      return R(r.statusCode, j is Map ? j : {});
    } catch (_) {
      return R(0, {'err': 'Connexion impossible. Le serveur est-il lancé ?'});
    }
  }
}

Future<String?> askText(BuildContext c, String title, String hint, {bool pin = false}) {
  final t = TextEditingController();
  return showDialog<String>(
      context: c,
      builder: (d) => AlertDialog(
            title: Text(title),
            content: TextField(
                controller: t,
                autofocus: true,
                obscureText: pin,
                keyboardType: pin ? TextInputType.number : TextInputType.text,
                maxLength: pin ? 4 : 24,
                decoration: InputDecoration(hintText: hint)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(d, t.text), child: const Text('Valider')),
            ],
          ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.init();
  runApp(const SageApp());
}

class SageApp extends StatelessWidget {
  const SageApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'sage',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: paper,
          colorScheme: ColorScheme.fromSeed(seedColor: sg)
              .copyWith(primary: sg, onPrimary: paper, surface: paper, onSurface: ink),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: surf,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: ln))),
        ),
        home: const Boot(),
      );
}

class Boot extends StatelessWidget {
  const Boot({super.key});
  @override
  Widget build(BuildContext c) => FutureBuilder<R>(
      future: Api.call('me'),
      builder: (c, s) {
        if (!s.hasData) return const Scaffold(body: Center(child: Mark(80)));
        return s.data!.ok ? Home(s.data!.j) : const AuthPage();
      });
}

class Mark extends StatelessWidget {
  final double s;
  final Color ring, dot;
  const Mark(this.s, {this.ring = sg, this.dot = terra, super.key});
  @override
  Widget build(BuildContext c) => CustomPaint(size: Size(s, s), painter: _MP(ring, dot));
}

class _MP extends CustomPainter {
  final Color r, d;
  _MP(this.r, this.d);
  @override
  void paint(Canvas c, Size z) {
    final s = z.width, ctr = Offset(s / 2, s / 2), rad = s * .38;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .07
      ..strokeCap = StrokeCap.round
      ..color = r;
    c.drawArc(Rect.fromCircle(center: ctr, radius: rad), 352 * pi / 180, 286.6 * pi / 180, false, p);
    c.drawCircle(Offset(ctr.dx + rad * cos(-pi / 4), ctr.dy + rad * sin(-pi / 4)), s * .09,
        Paint()..color = d);
  }

  @override
  bool shouldRepaint(_) => false;
}

class Av extends StatelessWidget {
  final String n;
  final double s;
  const Av(this.n, {this.s = 46, super.key});
  @override
  Widget build(BuildContext c) => CircleAvatar(
      radius: s / 2,
      backgroundColor: soft,
      child: Text(n.isEmpty ? '?' : n[0].toUpperCase(),
          style: serif(s * .35, w: FontWeight.w600).copyWith(color: sg)));
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthS();
}

class _AuthS extends State<AuthPage> {
  final nm = TextEditingController(), pw = TextEditingController();
  final sv = TextEditingController(text: Api.base);
  String? err;
  bool busy = false;

  Future<void> go(String mode) async {
    setState(() => busy = true);
    await Api.setBase(sv.text);
    final r = await Api.call('auth', {'mode': mode, 'name': nm.text.trim(), 'pw': pw.text});
    if (r.ok) {
      final m = await Api.call('me');
      if (m.ok && mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Home(m.j)));
        return;
      }
    }
    if (mounted) {
      setState(() {
        busy = false;
        err = r.ok ? 'Erreur de connexion.' : r.err;
      });
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
          body: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Mark(72),
          Text('sage', style: serif(44, it: true, w: FontWeight.w600)),
          const SizedBox(height: 24),
          TextField(controller: nm, maxLength: 24, decoration: const InputDecoration(labelText: 'Nom d’utilisateur')),
          const SizedBox(height: 8),
          TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe (6 caractères min.)')),
          const SizedBox(height: 8),
          TextField(controller: sv, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Serveur')),
          if (err != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(err!, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FilledButton(onPressed: busy ? null : () => go('login'), child: const Text('Se connecter'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: busy ? null : () => go('register'), child: const Text('Créer un compte'))),
          ]),
        ]),
      ))));
}

class PostCard extends StatelessWidget {
  final Map p;
  final VoidCallback onChange;
  final bool arch;
  const PostCard(this.p, this.onChange, {this.arch = false, super.key});

  Future<void> act(String a) async {
    await Api.call('$a/${p['id']}', {});
    onChange();
  }

  @override
  Widget build(BuildContext c) {
    final tag = p['vis'] == 'cercle' ? 'Cercle privé' : p['vis'] == 'private' ? 'Moi seul' : '';
    final n = p['likes'] as int, liked = p['liked'] == true, kept = p['kept'] == true;
    final cnt = n > 0 ? ' · $n' : '';
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ln))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Av(p['name']),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                if (p['v'] == 1) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified, size: 16, color: sg)),
              ]),
              Text('${ago(p['t'])}${tag.isEmpty ? '' : ' · $tag'}', style: const TextStyle(color: mu, fontSize: 13)),
            ])),
          ]),
          if ((p['text'] ?? '') != '')
            Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text(p['text'], style: serif(20))),
          if (p['photo'] != null)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                    borderRadius: arch
                        ? const BorderRadius.vertical(top: Radius.circular(200), bottom: Radius.circular(24))
                        : BorderRadius.circular(24),
                    child: Image.network(Api.base + p['photo'],
                        headers: {'Cookie': Api.cookie},
                        width: double.infinity,
                        height: arch ? 420 : 300,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(height: 80, child: Center(child: Text('Photo indisponible')))))),
          Row(children: [
            TextButton(onPressed: () => act('like'), child: Text(liked ? 'Apprécié$cnt' : 'Apprécier$cnt', style: TextStyle(color: liked ? sg : mu, fontWeight: liked ? FontWeight.w600 : FontWeight.w500))),
            TextButton(onPressed: () => act('keep'), child: Text(kept ? 'Gardé' : 'Garder', style: TextStyle(color: kept ? sg : mu))),
            if (p['mine'] == true) TextButton(onPressed: () => act('del'), child: const Text('Supprimer', style: TextStyle(color: mu))),
          ]),
        ]));
  }
}

class Home extends StatefulWidget {
  final Map me;
  const Home(this.me, {super.key});
  @override
  State<Home> createState() => _HomeS();
}

class _HomeS extends State<Home> {
  int tab = 0;
  String flt = 'all';
  List posts = [], instants = [], chats = [];
  Timer? t;
  late Map me;

  @override
  void initState() {
    super.initState();
    me = widget.me;
    load();
    t = Timer.periodic(const Duration(seconds: 20), (_) => load());
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final f = await Api.call('feed');
    final c = await Api.call('chats');
    if (!mounted) return;
    if (f.s == 401) {
      logout();
      return;
    }
    setState(() {
      if (f.ok) {
        posts = f.j['posts'];
        instants = f.j['instants'];
      }
      if (c.ok) chats = c.j['chats'];
    });
  }

  Future<void> logout() async {
    await Api.call('logout', {});
    await Api.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthPage()));
  }

  Future<void> publish([String mode = 'post']) async {
    await showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: paper, builder: (_) => PublishSheet(mode));
    load();
  }

  void space() => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      builder: (_) => SpaceSheet(me, logout));

  Future<void> openChat(int id, String name) async {
    var r = await Api.call('chat/$id?after=0');
    while (r.s == 423) {
      if (!mounted) return;
      final v = await askText(context, 'Entrez votre code', 'Code à 4 chiffres', pin: true);
      if (v == null) return;
      final u = await Api.call('chat/$id/unlock', {'pin': v});
      if (!u.ok) {
        if (mounted) snack(context, u.err);
        if (u.s == 429) return;
        continue;
      }
      r = await Api.call('chat/$id?after=0');
    }
    if (!mounted) return;
    if (!r.ok) {
      snack(context, r.err);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatPage(id, name, List<Map>.from(r.j['msgs']), r.j['locked'] == true, me)));
    load();
  }

  Future<void> newChat() async {
    final v = await askText(context, 'Nouvelle discussion', 'Nom d’utilisateur');
    if (v == null || v.trim().isEmpty) return;
    final r = await Api.call('chat/new', {'name': v.trim()});
    if (!mounted) return;
    if (!r.ok) {
      snack(context, r.err);
      return;
    }
    openChat(r.j['id'], r.j['name']);
  }

  void showInstant(Map p) => showDialog(
      context: context,
      builder: (d) => AlertDialog(
            title: Text(p['name']),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(ago(p['t']), style: const TextStyle(color: mu)),
              if ((p['text'] ?? '') != '') Padding(padding: const EdgeInsets.only(top: 12), child: Text(p['text'], style: serif(20))),
              if (p['photo'] != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Image.network(Api.base + p['photo'], headers: {'Cookie': Api.cookie})),
            ]),
            actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Fermer'))],
          ));

  static const pad = EdgeInsets.fromLTRB(20, 0, 20, 130);
  static const phys = AlwaysScrollableScrollPhysics();

  Widget fil() {
    final a = posts.where((p) => flt == 'all' || (flt == 'cercle' && p['vis'] == 'cercle') || (flt == 'calm' && p['photo'] == null)).toList();
    return ListView(physics: phys, padding: pad, children: [
      Wrap(spacing: 8, children: [
        for (final k in [['all', 'Pour vous'], ['cercle', 'Mes cercles'], ['calm', 'Silence']])
          ChoiceChip(
              label: Text(k[1]),
              selected: flt == k[0],
              showCheckmark: false,
              selectedColor: sg,
              labelStyle: TextStyle(color: flt == k[0] ? paper : mu),
              onSelected: (_) => setState(() => flt = k[0])),
      ]),
      const SizedBox(height: 8),
      if (a.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Rien ici pour l’instant. Touchez + pour publier.', style: TextStyle(color: mu))),
      for (final p in a) PostCard(p, load),
    ]);
  }

  Widget ring(String label, String name, bool on, VoidCallback tap) => Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
          onTap: tap,
          child: Column(children: [
            Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? terra : ln, width: 2)),
                child: Av(label, s: 52)),
            const SizedBox(height: 4),
            Text(name.length > 10 ? name.substring(0, 10) : name, style: const TextStyle(color: mu, fontSize: 12)),
          ])));

  Widget gal() {
    final seen = <String>{};
    final ins = instants.where((p) => seen.add(p['name'])).toList();
    final ph = posts.where((p) => p['photo'] != null).toList();
    return ListView(physics: phys, padding: pad, children: [
      const Text('INSTANTS · 24 H', style: TextStyle(color: mu, fontWeight: FontWeight.w600, letterSpacing: 1, fontSize: 13)),
      const SizedBox(height: 10),
      SizedBox(
          height: 96,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            ring('+', 'Vous', false, () => publish('instant')),
            for (final p in ins) ring(p['name'], p['name'], true, () => showInstant(p)),
          ])),
      if (ph.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Aucune photo pour l’instant.', style: TextStyle(color: mu))),
      for (final p in ph) PostCard(p, load, arch: true),
    ]);
  }

  Widget msg() => ListView(physics: phys, padding: pad, children: [
        Row(children: [
          Text('Messages', style: serif(30, it: true)),
          const Spacer(),
          OutlinedButton(onPressed: newChat, child: const Text('Nouvelle')),
        ]),
        const SizedBox(height: 8),
        if (chats.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Aucune discussion. Touchez Nouvelle.', style: TextStyle(color: mu))),
        for (final c in chats)
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Av(c['name'], s: 50),
              title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(c['locked'] == true ? '••••••••  VERROUILLÉE' : (c['last'] ?? ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mu)),
              onTap: () => openChat(c['id'], c['name'])),
        Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(24), border: Border.all(color: ln)),
            child: Text('Ouvrez une conversation puis touchez « Verrouiller ». Elle demandera votre code et n’affichera aucun aperçu.', style: serif(15))),
      ]);

  Widget tabBtn(String label, int i) => Expanded(
      child: TextButton(
          style: TextButton.styleFrom(
              backgroundColor: tab == i ? paper : Colors.transparent,
              foregroundColor: tab == i ? sg : soft,
              minimumSize: const Size(0, 48),
              shape: const StadiumBorder()),
          onPressed: () => setState(() => tab = i),
          child: Text(label, style: TextStyle(fontWeight: tab == i ? FontWeight.w600 : FontWeight.w500))));

  @override
  Widget build(BuildContext c) {
    final pages = [fil(), gal(), msg()];
    return Scaffold(
        body: SafeArea(
            child: Stack(children: [
      Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(children: [
              const Mark(34),
              const SizedBox(width: 10),
              Text('sage', style: serif(32, it: true, w: FontWeight.w600)),
              const Spacer(),
              InkWell(onTap: space, customBorder: const CircleBorder(), child: Padding(padding: const EdgeInsets.all(4), child: Av(me['name'], s: 40))),
            ])),
        Expanded(child: RefreshIndicator(color: sg, onRefresh: load, child: pages[tab])),
      ]),
      Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: sg, borderRadius: BorderRadius.circular(36)),
              child: Row(children: [
                tabBtn('Fil', 0),
                tabBtn('Galerie', 1),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: IconButton.filled(
                        tooltip: 'Publier',
                        onPressed: () => publish(),
                        icon: const Icon(Icons.add, size: 30),
                        style: IconButton.styleFrom(backgroundColor: terra, foregroundColor: Colors.white, fixedSize: const Size(56, 56)))),
                tabBtn('Messages', 2),
              ]))),
    ])));
  }
}

class PublishSheet extends StatefulWidget {
  final String mode;
  const PublishSheet(this.mode, {super.key});
  @override
  State<PublishSheet> createState() => _PS();
}

class _PS extends State<PublishSheet> {
  late String mode = widget.mode;
  String vis = 'public';
  String? photo, err;
  bool busy = false;
  final tc = TextEditingController();

  Future<void> pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (x == null) return;
    var im = img.decodeImage(await x.readAsBytes());
    if (im == null) {
      setState(() => err = 'Image illisible.');
      return;
    }
    if (im.width > 900) im = img.copyResize(im, width: 900);
    final jpg = img.encodeJpg(im, quality: 72);
    setState(() {
      photo = 'data:image/jpeg;base64,${base64Encode(jpg)}';
      err = null;
    });
  }

  Future<void> send() async {
    if (tc.text.trim().isEmpty && photo == null) {
      setState(() => err = 'Écrivez un texte ou ajoutez une photo.');
      return;
    }
    setState(() => busy = true);
    final ins = mode == 'instant';
    final r = await Api.call('post', {'text': tc.text, 'photo': photo, 'vis': ins ? 'public' : vis, 'instant': ins});
    if (!mounted) return;
    if (r.ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        busy = false;
        err = r.err;
      });
    }
  }

  Widget chip(String label, bool on, VoidCallback f) => ChoiceChip(
      label: Text(label),
      selected: on,
      showCheckmark: false,
      selectedColor: sg,
      labelStyle: TextStyle(color: on ? paper : mu),
      onSelected: (_) => f());

  @override
  Widget build(BuildContext c) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Que souhaitez-vous partager ?', style: serif(26, it: true)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, children: [
          chip('Écrire', mode == 'post', () => setState(() => mode = 'post')),
          chip('Instant', mode == 'instant', () => setState(() => mode = 'instant')),
        ]),
        const SizedBox(height: 12),
        TextField(controller: tc, maxLines: 4, maxLength: 1000, style: serif(20), decoration: const InputDecoration(hintText: 'Votre texte…')),
        if (photo != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(base64Decode(photo!.split(',')[1]), height: 160, fit: BoxFit.cover))),
        Row(children: [
          TextButton(onPressed: pick, child: Text(photo == null ? 'Ajouter une photo' : 'Changer la photo')),
          if (photo != null) TextButton(onPressed: () => setState(() => photo = null), child: const Text('Retirer')),
        ]),
        if (mode == 'instant')
          const Text('Un instant disparaît après 24 h.', style: TextStyle(color: mu))
        else ...[
          const Text('QUI PEUT VOIR ?', style: TextStyle(color: mu, fontWeight: FontWeight.w600, letterSpacing: 1, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            chip('Public', vis == 'public', () => setState(() => vis = 'public')),
            chip('Mon cercle', vis == 'cercle', () => setState(() => vis = 'cercle')),
            chip('Moi seul', vis == 'private', () => setState(() => vis = 'private')),
          ]),
        ],
        if (err != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(err!, style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : send, child: const Text('Publier'))),
      ])));
}

class SpaceSheet extends StatefulWidget {
  final Map me;
  final Future<void> Function() onLogout;
  const SpaceSheet(this.me, this.onLogout, {super.key});
  @override
  State<SpaceSheet> createState() => _SS();
}

class _SS extends State<SpaceSheet> {
  List members = [];
  String? err;
  final cn = TextEditingController(), sv = TextEditingController(text: Api.base);

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final r = await Api.call('circle');
    if (mounted && r.ok) setState(() => members = r.j['members']);
  }

  Future<void> setC(String n, bool add) async {
    final r = await Api.call('circle', {'name': n, 'add': add});
    if (!mounted) return;
    if (!r.ok) {
      setState(() => err = r.err);
      return;
    }
    cn.clear();
    setState(() => err = null);
    refresh();
  }

  @override
  Widget build(BuildContext c) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Votre espace', style: serif(26, it: true)),
        Text('Connecté en tant que ${widget.me['name']}', style: const TextStyle(color: mu)),
        const SizedBox(height: 16),
        const Text('MON CERCLE', style: TextStyle(color: mu, fontWeight: FontWeight.w600, letterSpacing: 1, fontSize: 13)),
        if (members.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Personne pour l’instant. Les publications « Mon cercle » ne sont vues que par ces personnes.', style: TextStyle(color: mu))),
        for (final m in members)
          Row(children: [Text(m), const Spacer(), TextButton(onPressed: () => setC(m, false), child: const Text('Retirer'))]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: cn, maxLength: 24, decoration: const InputDecoration(hintText: 'Nom d’utilisateur', counterText: ''))),
          const SizedBox(width: 8),
          FilledButton(onPressed: () => setC(cn.text, true), child: const Text('Ajouter')),
        ]),
        if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(height: 16),
        const Text('SERVEUR', style: TextStyle(color: mu, fontWeight: FontWeight.w600, letterSpacing: 1, fontSize: 13)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: sv, keyboardType: TextInputType.url)),
          const SizedBox(width: 8),
          OutlinedButton(
              onPressed: () async {
                await Api.setBase(sv.text);
                if (mounted) snack(c, 'Serveur enregistré.');
              },
              child: const Text('Enregistrer')),
        ]),
        const SizedBox(height: 20),
        OutlinedButton(
            onPressed: () {
              Navigator.pop(c);
              widget.onLogout();
            },
            child: const Text('Se déconnecter')),
      ])));
}

class ChatPage extends StatefulWidget {
  final int id;
  final String name;
  final List<Map> msgs0;
  final bool locked0;
  final Map me;
  const ChatPage(this.id, this.name, this.msgs0, this.locked0, this.me, {super.key});
  @override
  State<ChatPage> createState() => _CP();
}

class _CP extends State<ChatPage> {
  late List<Map> msgs = widget.msgs0;
  late bool locked = widget.locked0;
  Timer? t;
  final tc = TextEditingController(), sc = ScrollController();

  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 4), (_) => tick());
    down();
  }

  @override
  void dispose() {
    t?.cancel();
    Api.call('chat/${widget.id}/relock', {});
    tc.dispose();
    sc.dispose();
    super.dispose();
  }

  void down() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (sc.hasClients) sc.jumpTo(sc.position.maxScrollExtent);
      });

  Future<void> tick() async {
    final last = msgs.isEmpty ? 0 : msgs.last['id'];
    final r = await Api.call('chat/${widget.id}?after=$last');
    if (!mounted) return;
    if (r.s == 423) {
      Navigator.pop(context);
      return;
    }
    if (r.ok) {
      final n = List<Map>.from(r.j['msgs']);
      if (n.isNotEmpty) {
        setState(() => msgs.addAll(n));
        down();
      }
    }
  }

  Future<void> send() async {
    final v = tc.text.trim();
    if (v.isEmpty) return;
    tc.clear();
    final r = await Api.call('chat/${widget.id}/send', {'body': v});
    if (!r.ok) {
      if (mounted) snack(context, r.err);
      tc.text = v;
      return;
    }
    tick();
  }

  Future<void> lock() async {
    if (locked) {
      final r = await Api.call('chat/${widget.id}/lock', {'on': false});
      if (r.ok && mounted) {
        setState(() => locked = false);
        snack(context, 'Verrouillage retiré.');
      }
      return;
    }
    String? p;
    if (widget.me['hasPin'] != true) {
      p = await askText(context, 'Créez un code à 4 chiffres', 'Code à 4 chiffres', pin: true);
      if (p == null) return;
    }
    final r = await Api.call('chat/${widget.id}/lock', {'on': true, 'pin': p});
    if (!mounted) return;
    if (r.ok) {
      widget.me['hasPin'] = true;
      setState(() => locked = true);
      snack(context, 'Discussion verrouillée.');
    } else {
      snack(context, r.err);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(
          backgroundColor: paper,
          title: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          actions: [
            Padding(
                padding: const EdgeInsets.only(right: 12),
                child: OutlinedButton(onPressed: lock, child: Text(locked ? 'Déverrouiller' : 'Verrouiller')))
          ]),
      body: SafeArea(
          child: Column(children: [
        Expanded(
            child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i], me = m['me'] == true;
                  return Align(
                      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(c).size.width * .78),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                              color: me ? sg : soft,
                              borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(22),
                                  topRight: const Radius.circular(22),
                                  bottomLeft: Radius.circular(me ? 22 : 6),
                                  bottomRight: Radius.circular(me ? 6 : 22))),
                          child: Text(m['x'], style: TextStyle(color: me ? paper : ink, fontSize: 16))));
                })),
        Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(children: [
              Expanded(child: TextField(controller: tc, maxLength: 2000, onSubmitted: (_) => send(), decoration: const InputDecoration(hintText: 'Message', counterText: ''))),
              const SizedBox(width: 8),
              FilledButton(onPressed: send, child: const Text('Envoyer')),
            ])),
      ])));
}
