import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  Future<void> _effettuaLogin() async {
    final emailInserita = _emailController.text;
    final passwordInserita = _passwordController.text;

    final emailSalvata = await _storage.read(key: 'email');
    final passwordSalvata = await _storage.read(key: 'password');

    if (emailSalvata == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun utente trovato. Registrati prima!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (emailInserita == emailSalvata && passwordInserita == passwordSalvata) {
      if (!mounted) return;
      // LOGICA DI SUCCESSO:
      // Usiamo pushReplacement per non poter tornare indietro al login col tasto back
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AgendaPage()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email o Password errati'), backgroundColor: Colors.red),
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
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _effettuaLogin,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('ACCEDI', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // MODIFICA RICHIESTA: Puliamo i campi prima di andare alla registrazione
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

// --- 3. NUOVA PAGINA: AGENDA (Home) ---
// --- 3. PAGINA AGENDA (Dinamica e Navigabile) ---
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  // 1. Variabile per tenere traccia del giorno che stiamo guardando
  DateTime _giornoSelezionato = DateTime.now();

  // 2. Il nostro "Database" locale.
  // Chiave: Stringa della data (es. "2023-10-27")
  // Valore: Lista di cose da fare (es. ["Udienza", "Riunione"])
  final Map<String, List<String>> _impegni = {};

  // Funzione per trasformare la data in una stringa semplice (senza ore/minuti)
  // Serve come "chiave" per trovare gli impegni di quel giorno specifico
  String _chiaveData(DateTime data) {
    return "${data.year}-${data.month}-${data.day}";
  }

  // Funzione per cambiare giorno (avanti o indietro)
  void _cambiaGiorno(int giorniDaAggiungere) {
    setState(() {
      _giornoSelezionato = _giornoSelezionato.add(Duration(days: giorniDaAggiungere));
    });
  }

  // Funzione per aggiungere un nuovo evento
  void _aggiungiEvento() {
    TextEditingController eventoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuovo Impegno"),
        content: TextField(
          controller: eventoController,
          decoration: const InputDecoration(hintText: "Es: Udienza preliminare..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Annulla
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              if (eventoController.text.isNotEmpty) {
                setState(() {
                  // 1. Calcoliamo la chiave del giorno corrente
                  String key = _chiaveData(_giornoSelezionato);
                  
                  // 2. Se non esiste ancora una lista per oggi, creiamola
                  if (_impegni[key] == null) {
                    _impegni[key] = [];
                  }
                  
                  // 3. Aggiungiamo l'evento alla lista
                  _impegni[key]!.add(eventoController.text);
                });
                Navigator.pop(context); // Chiudi la finestra
              }
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }

  // Funzione per fare Logout
  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context, // Qui dovresti avere importato la LoginPage o averla nello stesso file
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Recuperiamo la lista degli impegni per il giorno selezionato
    // Se non ce ne sono, usiamo una lista vuota []
    final impegniDelGiorno = _impegni[_chiaveData(_giornoSelezionato)] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('La Mia Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Column(
        children: [
          // --- BARRA DI NAVIGAZIONE GIORNI ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Freccia Indietro
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => _cambiaGiorno(-1),
                ),
                
                // Testo della Data
                Column(
                  children: [
                    const Text(
                      "Data Selezionata",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      // Mostriamo la data in formato giorno/mese/anno
                      "${_giornoSelezionato.day}/${_giornoSelezionato.month}/${_giornoSelezionato.year}",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Freccia Avanti
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _cambiaGiorno(1),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // --- LISTA DEGLI IMPEGNI ---
          Expanded(
            child: impegniDelGiorno.isEmpty
                ? const Center(
                    child: Text(
                      "Nessun impegno per questa data.\nPremi + per aggiungerne uno.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: impegniDelGiorno.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.event_note, color: Colors.blue),
                          title: Text(impegniDelGiorno[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                // Rimuovi l'evento
                                impegniDelGiorno.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // --- TASTO PER AGGIUNGERE ---
      floatingActionButton: FloatingActionButton(
        onPressed: _aggiungiEvento,
        child: const Icon(Icons.add),
      ),
    );
  }
}