import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const AgendaLegaleApp());
}

class AgendaLegaleApp extends StatelessWidget {
  const AgendaLegaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Legale',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
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
  
  // Istanza per la biometria
  final LocalAuthentication auth = LocalAuthentication();

  // La logica dell'impronta viene attivata solo premendo il tasto manuale
  Future<void> _avviaBiometria() async {
    try {
      bool autenticato = await auth.authenticate(
        localizedReason: 'Autenticati per accedere all\'Agenda Legale',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (autenticato && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AgendaPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autenticazione biometrica non riuscita')),
      );
    }
  }

  Future<void> _effettuaLogin() async {
    final emailInserita = _emailController.text;
    final passwordInserita = _passwordController.text;

    final emailSalvata = await _storage.read(key: 'email');
    final passwordSalvata = await _storage.read(key: 'password');

    if (emailSalvata == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun utente trovato. Registrati prima!'), 
          backgroundColor: Colors.orange
        ),
      );
      return;
    }

    if (emailInserita == emailSalvata && passwordInserita == passwordSalvata) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AgendaPage()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email o Password errati'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Legale - Accesso')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gavel, size: 80, color: Colors.blue),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.email)
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.lock)
                ),
              ),
              const SizedBox(height: 30),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _effettuaLogin,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)
                      ),
                      child: const Text('ACCEDI', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _avviaBiometria,
                    icon: const Icon(Icons.fingerprint, size: 40, color: Colors.blue),
                    tooltip: "Usa Biometria",
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  _emailController.clear();
                  _passwordController.clear();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationPage()),
                  );
                },
                child: const Text('Non hai un account? Registrati qui'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. PAGINA DI REGISTRAZIONE ---
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _useBiometrics = false;
  final _storage = const FlutterSecureStorage();

  Future<void> _effettuaRegistrazione() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le password non coincidono!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi'), backgroundColor: Colors.orange),
      );
      return;
    }

    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
    await _storage.write(key: 'use_biometrics', value: _useBiometrics.toString());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrazione completata! Inserisci le credenziali per accedere.'), backgroundColor: Colors.green),
    );

    Navigator.pop(context); // Torna al Login (che sarà vuoto)
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo Utente')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text('Crea il tuo profilo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_add)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Conferma Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 30),
              SwitchListTile(
                title: const Text('Abilita Accesso Biometrico'),
                subtitle: const Text('Usa impronta per i futuri accessi'),
                secondary: const Icon(Icons.fingerprint, size: 30),
                value: _useBiometrics,
                onChanged: (bool value) {
                  setState(() {
                    _useBiometrics = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _effettuaRegistrazione,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('REGISTRATI', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3. PAGINA AGENDA (Dinamica e Navigabile) ---
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _giornoSelezionato = DateTime.now();
  final _storage = const FlutterSecureStorage();

  // Ora la mappa non contiene semplici stringhe, ma oggetti "EventoLegale"
  Map<String, List<EventoLegale>> _impegni = {};

  @override
  void initState() {
    super.initState();
    _caricaImpegni(); // Appena apri la pagina, carichiamo i dati salvati
  }

  // --- 1. SALVATAGGIO E CARICAMENTO ---
  String _chiaveData(DateTime data) {
    return "${data.year}-${data.month}-${data.day}";
  }

  Future<void> _salvaImpegni() async {
    // Trasformiamo la mappa di oggetti in un testo JSON salvabile
    // È un po' tecnico, ma serve a convertire "Oggetti" in "Testo"
    final jsonMap = _impegni.map((key, value) => MapEntry(
        key,
        value.map((e) => e.toMap()).toList(),
    ));
    
    String jsonString = jsonEncode(jsonMap);
    await _storage.write(key: 'agenda_dati', value: jsonString);
  }

  Future<void> _caricaImpegni() async {
    String? jsonString = await _storage.read(key: 'agenda_dati');
    if (jsonString != null) {
      try {
        Map<String, dynamic> decodedMap = jsonDecode(jsonString);
        setState(() {
          _impegni = decodedMap.map((key, value) => MapEntry(
            key,
            (value as List).map((e) => EventoLegale.fromMap(e)).toList(),
          ));
        });
      } catch (e) {
        print("Errore nel caricamento dati: $e");
      }
    }
  }

  void _cambiaGiorno(int giorniDaAggiungere) {
    setState(() {
      _giornoSelezionato = _giornoSelezionato.add(Duration(days: giorniDaAggiungere));
    });
  }

  // --- 2. INTERFACCIA AGGIUNTA EVENTO (Multi-campo) ---
  void _aggiungiEvento() {
    // Controller per i 4 campi richiesti
    final clienteController = TextEditingController();
    final faseController = TextEditingController();
    final oraController = TextEditingController();
    final luogoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuovo Impegno", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    TextField(
      controller: clienteController,
      decoration: const InputDecoration(
        labelText: "Cliente", // Questo resta sempre
        hintText: "es. Rossi", // Questo scompare quando scrivi
        icon: Icon(Icons.person),
      ),
    ),
    TextField(
      controller: faseController,
      decoration: const InputDecoration(
        labelText: "Fase",
        hintText: "es. Udienza",
        icon: Icon(Icons.gavel),
      ),
    ),
    TextField(
      controller: oraController,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: "Ora",
        hintText: "es. 09:30",
        icon: Icon(Icons.access_time),
      ),
    ),
    TextField(
      controller: luogoController,
      decoration: const InputDecoration(
        labelText: "Luogo",
        hintText: "es. Trib. Milano",
        icon: Icon(Icons.place),
      ),
    ),
  ],
),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              if (clienteController.text.isNotEmpty) {
                setState(() {
                  String key = _chiaveData(_giornoSelezionato);
                  if (_impegni[key] == null) {
                    _impegni[key] = [];
                  }
                  
                  // Creiamo il nuovo oggetto EventoLegale
                  EventoLegale nuovoEvento = EventoLegale(
                    cliente: clienteController.text,
                    fase: faseController.text,
                    ora: oraController.text,
                    luogo: luogoController.text,
                  );

                  _impegni[key]!.add(nuovoEvento);
                  _salvaImpegni(); // Salviamo subito dopo l'aggiunta!
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }
  // --- NUOVA FUNZIONE PER MODIFICARE ---
void _modificaEvento(EventoLegale evento, int index) {
  final clienteController = TextEditingController(text: evento.cliente);
  final faseController = TextEditingController(text: evento.fase);
  final oraController = TextEditingController(text: evento.ora);
  final luogoController = TextEditingController(text: evento.luogo);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Modifica Impegno"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: clienteController, decoration: const InputDecoration(labelText: "Cliente")),
            TextField(controller: faseController, decoration: const InputDecoration(labelText: "Fase")),
            TextField(
              controller: oraController,
              readOnly: true, // Come abbiamo impostato per l'orologio
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (pickedTime != null) {
                  setState(() { oraController.text = pickedTime.format(context); });
                }
              },
              decoration: const InputDecoration(labelText: "Ora"),
            ),
            TextField(controller: luogoController, decoration: const InputDecoration(labelText: "Luogo")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
        ElevatedButton(
          onPressed: () {
            setState(() {
              // Aggiorniamo l'oggetto esistente
              evento.cliente = clienteController.text;
              evento.fase = faseController.text;
              evento.ora = oraController.text;
              evento.luogo = luogoController.text;
              _salvaImpegni(); // Salviamo la modifica
            });
            Navigator.pop(context);
          },
          child: const Text("Aggiorna"),
        ),
      ],
    ),
  );
}

  // --- 3. CONFERMA ELIMINAZIONE ---
  void _confermaElimina(List<EventoLegale> listaGiornaliera, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminare l'evento?"),
        content: const Text("Questa azione non può essere annullata."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Chiudi senza fare nulla
            child: const Text("No, mantieni"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                listaGiornaliera.removeAt(index);
                _salvaImpegni(); // Aggiorniamo il salvataggio
              });
              Navigator.pop(context); // Chiudi il dialog
            },
            child: const Text("Sì, elimina"),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _mostraDettagliEvento(EventoLegale evento, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Dettagli Impegno", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rigaDettaglio(Icons.person, "Cliente", evento.cliente),
            const SizedBox(height: 10),
            _rigaDettaglio(Icons.gavel, "Fase", evento.fase),
            const SizedBox(height: 10),
            _rigaDettaglio(Icons.access_time, "Ora", evento.ora),
            const SizedBox(height: 10),
            _rigaDettaglio(Icons.place, "Luogo", evento.luogo),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Chiudi"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("Modifica"),
            onPressed: () {
              Navigator.pop(context); // Chiude i dettagli
              _apriDialogEvento(eventoEsistente: evento, index: index); // Apre l'editor
            },
          ),
        ],
      ),
    );
  }

  // Funzione di supporto grafica per i dettagli
  Widget _rigaDettaglio(IconData icona, String etichetta, String valore) {
    return Row(
      children: [
        Icon(icona, color: Colors.blue, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "$etichetta: $valore",
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // 1. Funzione per Aprire il Dialog (sia per Aggiungere che per Modificare)
  void _apriDialogEvento({EventoLegale? eventoEsistente, int? index}) {
    // Se passiamo un evento esistente, i campi saranno già compilati
    final clienteController = TextEditingController(text: eventoEsistente?.cliente);
    final faseController = TextEditingController(text: eventoEsistente?.fase);
    final oraController = TextEditingController(text: eventoEsistente?.ora);
    final luogoController = TextEditingController(text: eventoEsistente?.luogo);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(eventoEsistente == null ? "Nuovo Impegno" : "Modifica Impegno"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clienteController, 
                decoration: const InputDecoration(labelText: "Cliente", hintText: "es. Rossi")
              ),
              TextField(
                controller: faseController, 
                decoration: const InputDecoration(labelText: "Fase", hintText: "es. Udienza")
              ),
              TextField(
                controller: oraController,
                readOnly: true,
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context, 
                    initialTime: TimeOfDay.now()
                  );
                  if (picked != null) {
                    setState(() => oraController.text = picked.format(context));
                  }
                },
                decoration: const InputDecoration(labelText: "Ora", hintText: "Seleziona orario"),
              ),
              TextField(
                controller: luogoController, 
                decoration: const InputDecoration(labelText: "Luogo", hintText: "es. Trib. Milano")
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                String key = _chiaveData(_giornoSelezionato);
                EventoLegale nuovo = EventoLegale(
                  cliente: clienteController.text,
                  fase: faseController.text,
                  ora: oraController.text,
                  luogo: luogoController.text,
                );

                if (eventoEsistente == null) {
                  // Aggiunta nuovo
                  if (_impegni[key] == null) _impegni[key] = [];
                  _impegni[key]!.add(nuovo);
                } else {
                  // Modifica esistente
                  _impegni[key]![index!] = nuovo;
                }
                _salvaImpegni(); // Salva su disco
              });
              Navigator.pop(context);
            },
            child: Text(eventoEsistente == null ? "Salva" : "Aggiorna"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final impegniDelGiorno = _impegni[_chiaveData(_giornoSelezionato)] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Legale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => _cambiaGiorno(-1)),
                Column(
                  children: [
                    Text("${_giornoSelezionato.day}/${_giornoSelezionato.month}/${_giornoSelezionato.year}",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("${impegniDelGiorno.length} Impegni", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () => _cambiaGiorno(1)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: impegniDelGiorno.isEmpty
                ? const Center(child: Text("Nessun impegno.\nPremi + per aggiungere.", textAlign: TextAlign.center))
                : ListView.builder(
          itemCount: impegniDelGiorno.length,
          itemBuilder: (context, index) {
            final evento = impegniDelGiorno[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              child: ListTile(
                onTap: () => _mostraDettagliEvento(evento, index),
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue, size: 20),
                    Text(
                      evento.ora,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                title: Text(
                  evento.cliente,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fase: ${evento.fase}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        Text(
                          " ${evento.luogo}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confermaElimina(impegniDelGiorno, index),
                ),
              ),
            );
          },
        ),
),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _aggiungiEvento,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- NUOVA CLASSE MODELLO (Da mettere alla fine del file) ---
class EventoLegale {
  String cliente;
  String fase;
  String ora;
  String luogo;

  EventoLegale({
    required this.cliente,
    required this.fase,
    required this.ora,
    required this.luogo,
  });

  // Metodo per convertire l'oggetto in una mappa (per salvarlo in JSON)
  Map<String, dynamic> toMap() {
    return {
      'cliente': cliente,
      'fase': fase,
      'ora': ora,
      'luogo': luogo,
    };
  }

  // Metodo per creare l'oggetto partendo dai dati salvati
  factory EventoLegale.fromMap(Map<String, dynamic> map) {
    return EventoLegale(
      cliente: map['cliente'] ?? '',
      fase: map['fase'] ?? '',
      ora: map['ora'] ?? '',
      luogo: map['luogo'] ?? '',
    );
  }
}