import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';

// Notificatore globale per il tema (Dark/Light)
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const AgendaLegaleApp());
}

class AgendaLegaleApp extends StatelessWidget {
  const AgendaLegaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Agenda Legale',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue, 
            useMaterial3: true, 
            brightness: Brightness.light
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark, 
            primarySwatch: Colors.blue
          ),
          themeMode: currentMode,
          home: const LoginPage(),
        );
      },
    );
  }
}

// --- 1. PAGINA DI LOGIN ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _avviaBiometria() async {
    try {
      String? emailSalvata = await _storage.read(key: 'email');
      bool autenticato = await auth.authenticate(
        localizedReason: 'Autenticati per accedere',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (autenticato && mounted && emailSalvata != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AgendaPage(userEmail: emailSalvata)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore biometria')));
    }
  }

  Future<void> _effettuaLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final emailSalvata = await _storage.read(key: 'email');
    final passSalvata = await _storage.read(key: 'password_$email');

    if (emailSalvata == email && pass == passSalvata) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => AgendaPage(userEmail: email))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credenziali errate'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Legale - Accesso')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.gavel, size: 80, color: Colors.blue),
              const SizedBox(height: 40),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 20),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: ElevatedButton(onPressed: _effettuaLogin, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text('ACCEDI'))),
                  const SizedBox(width: 10),
                  IconButton(onPressed: _avviaBiometria, icon: const Icon(Icons.fingerprint, size: 40, color: Colors.blue)),
                ],
              ),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RegistrationPage())), child: const Text('Registrati qui')),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. PAGINA REGISTRAZIONE ---
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _conf = TextEditingController();
  bool _bio = false;
  final _storage = const FlutterSecureStorage();

  _registra() async {
    if (_nome.text.isEmpty || _cognome.text.isEmpty || _email.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campi obbligatori!')));
      return;
    }
    String email = _email.text.trim();
    await _storage.write(key: 'nome_$email', value: _nome.text);
    await _storage.write(key: 'cognome_$email', value: _cognome.text);
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password_$email', value: _pass.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.badge))),
            TextField(controller: _cognome, decoration: const InputDecoration(labelText: 'Cognome', prefixIcon: Icon(Icons.badge_outlined))),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
            TextField(controller: _conf, obscureText: true, decoration: const InputDecoration(labelText: 'Conferma', prefixIcon: Icon(Icons.lock_clock))),
            SwitchListTile(title: const Text('Biometria'), value: _bio, onChanged: (v) => setState(() => _bio = v)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _registra, child: const Text('REGISTRATI')),
          ],
        ),
      ),
    );
  }
}

// --- 3. AGENDA PAGE (Main Logic) ---
class AgendaPage extends StatefulWidget {
  final String userEmail;
  const AgendaPage({super.key, required this.userEmail});
  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  // Variabili per la ricerca
  bool _staCercando = false;
  String _testoCercato = "";
  final TextEditingController _searchController = TextEditingController();

  DateTime _giornoSelezionato = DateTime.now();
  final _storage = const FlutterSecureStorage();
  Map<String, List<EventoLegale>> _impegni = {};
  
  // Dati utente
  String _nomeUtente = "Avvocato";
  String? _percorsoFoto;

  String get _storageKey => 'agenda_dati_${widget.userEmail}';

  @override
  void initState() {
    super.initState();
    _caricaInfoUtente();
    _caricaImpegni();
  }

  _caricaInfoUtente() async {
    String? n = await _storage.read(key: 'nome_${widget.userEmail}');
    String? foto = await _storage.read(key: 'foto_${widget.userEmail}');
    setState(() {
      _nomeUtente = n ?? "Avvocato";
      _percorsoFoto = foto;
    });
  }

  _caricaImpegni() async {
    String? data = await _storage.read(key: _storageKey);
    if (data != null) {
      Map<String, dynamic> decoded = jsonDecode(data);
      setState(() {
        _impegni = decoded.map((k, v) => MapEntry(k, (v as List).map((e) => EventoLegale.fromMap(e)).toList()));
      });
    }
  }

  _salvaImpegni() async {
    final map = _impegni.map((k, v) => MapEntry(k, v.map((e) => e.toMap()).toList()));
    await _storage.write(key: _storageKey, value: jsonEncode(map));
  }

  // GESTIONE FOTO: Anteprima e Permessi
  void _mostraAnteprimaFoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _percorsoFoto != null
                ? Image.file(File(_percorsoFoto!), fit: BoxFit.cover, height: 250, width: double.infinity)
                : Container(height: 200, width: double.infinity, color: Colors.grey, child: const Icon(Icons.person, size: 100)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _prendiFoto(); },
                icon: const Icon(Icons.edit),
                label: const Text("Modifica Foto"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _prendiFoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        await _storage.write(key: 'foto_${widget.userEmail}', value: image.path);
        setState(() => _percorsoFoto = image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Errore accesso galleria")));
    }
  }

  // GESTIONE EVENTI: Dialog e Logica
  void _mostraDettagliEvento(EventoLegale evento, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Dettagli Impegno"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _rigaInfo(Icons.person, "Cliente: ${evento.cliente}"),
            _rigaInfo(Icons.gavel, "Fase: ${evento.fase}"),
            _rigaInfo(Icons.access_time, "Ora: ${evento.ora}"),
            _rigaInfo(Icons.place, "Luogo: ${evento.luogo}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Chiudi")),
          ElevatedButton(onPressed: () { Navigator.pop(context); _apriDialogEvento(eventoEsistente: evento, index: index); }, child: const Text("Modifica")),
        ],
      ),
    );
  }

  Widget _rigaInfo(IconData icon, String testo) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Icon(icon, size: 20, color: Colors.blue), const SizedBox(width: 10), Text(testo)]));

  void _apriDialogEvento({EventoLegale? eventoEsistente, int? index}) {
    final c = TextEditingController(text: eventoEsistente?.cliente);
    final f = TextEditingController(text: eventoEsistente?.fase);
    final o = TextEditingController(text: eventoEsistente?.ora);
    final l = TextEditingController(text: eventoEsistente?.luogo);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(eventoEsistente == null ? "Nuovo Impegno" : "Modifica"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: c, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: "Cliente", icon: Icon(Icons.person))),
                TextField(controller: f, decoration: const InputDecoration(labelText: "Fase", icon: Icon(Icons.gavel))),
                TextField(controller: o, readOnly: true, decoration: const InputDecoration(labelText: "Ora", icon: Icon(Icons.access_time)), onTap: () async {
                  TimeOfDay? p = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (p != null) setState(() => o.text = p.format(context));
                }),
                TextField(controller: l, decoration: const InputDecoration(labelText: "Luogo", icon: Icon(Icons.place))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () { FocusScope.of(context).unfocus(); Navigator.pop(context); }, child: const Text("Annulla")),
          ElevatedButton(onPressed: () {
            if (c.text.isEmpty) return;
            FocusScope.of(context).unfocus();
            setState(() {
              String key = "${_giornoSelezionato.year}-${_giornoSelezionato.month}-${_giornoSelezionato.day}";
              EventoLegale ev = EventoLegale(cliente: c.text.trim(), fase: f.text.trim(), ora: o.text, luogo: l.text.trim());
              if (eventoEsistente == null) { _impegni.putIfAbsent(key, () => []).add(ev); }
              else { _impegni[key]![index!] = ev; }
              _salvaImpegni();
            });
            Navigator.pop(context);
          }, child: const Text("Salva")),
        ],
      ),
    );
  }

  void _confermaEliminaAttivita(List<EventoLegale> lista, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminare?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () {
            setState(() { lista.removeAt(index); _salvaImpegni(); });
            Navigator.pop(context);
          }, child: const Text("Sì", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String chiaveGiorno = "${_giornoSelezionato.year}-${_giornoSelezionato.month}-${_giornoSelezionato.day}";
    final List<EventoLegale> impegniGiorno = _impegni[chiaveGiorno] ?? [];

    final impegniFiltrati = impegniGiorno.where((evento) {
      if (!_staCercando) return true;
      final query = _testoCercato.toLowerCase();
      return evento.cliente.toLowerCase().contains(query) || evento.fase.toLowerCase().contains(query) || evento.luogo.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: _staCercando
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: "Cerca...", hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none),
                onChanged: (val) => setState(() => _testoCercato = val),
              )
            : const Text('Agenda Legale'),
        backgroundColor: _staCercando ? Colors.blue.shade700 : null,
        actions: [
          IconButton(
            icon: Icon(_staCercando ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _staCercando = !_staCercando;
                if (!_staCercando) { _testoCercato = ""; _searchController.clear(); }
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: GestureDetector(
                onTap: _mostraAnteprimaFoto,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: _percorsoFoto != null ? FileImage(File(_percorsoFoto!)) : null,
                  child: _percorsoFoto == null ? const Icon(Icons.camera_alt, color: Colors.blue) : null,
                ),
              ),
              accountName: Text(_nomeUtente, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.userEmail),
            ),
            ExpansionTile(
              leading: const Icon(Icons.settings),
              title: const Text("Impostazioni"),
              children: [
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  secondary: const Icon(Icons.dark_mode),
                  value: themeNotifier.value == ThemeMode.dark,
                  onChanged: (val) => setState(() => themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light),
                ),
              ],
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Esci", style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginPage())),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_staCercando)
            CalendarDatePicker(
              initialDate: _giornoSelezionato,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              onDateChanged: (d) => setState(() => _giornoSelezionato = d),
            ),
          const Divider(height: 1),
          Expanded(
            child: impegniFiltrati.isEmpty
                ? Center(child: Text(_testoCercato.isEmpty ? "Nessun impegno." : "Nessun risultato."))
                : ListView.builder(
                    itemCount: impegniFiltrati.length,
                    itemBuilder: (context, index) {
                      final ev = impegniFiltrati[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          onTap: () => _mostraDettagliEvento(ev, index),
                          leading: Text(ev.ora, style: const TextStyle(fontWeight: FontWeight.bold)),
                          title: Text(ev.cliente),
                          subtitle: Text(ev.fase),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confermaEliminaAttivita(impegniGiorno, index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _apriDialogEvento(), child: const Icon(Icons.add)),
    );
  }
}

// --- CLASSE MODELLO ---
class EventoLegale {
  String cliente, fase, ora, luogo;
  EventoLegale({required this.cliente, required this.fase, required this.ora, required this.luogo});
  Map<String, dynamic> toMap() => {'cliente': cliente, 'fase': fase, 'ora': ora, 'luogo': luogo};
  factory EventoLegale.fromMap(Map<String, dynamic> map) => EventoLegale(cliente: map['cliente'], fase: map['fase'], ora: map['ora'], luogo: map['luogo']);
}