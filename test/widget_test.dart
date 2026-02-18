import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_legale/main.dart';

void main() {
  testWidgets('Verifica caricamento pagina login', (WidgetTester tester) async {
    // Carica l'app usando il nome corretto della classe
    await tester.pumpWidget(const AgendaLegaleApp());

    // Verifica che nella schermata iniziale ci sia il testo "Agenda Legale - Accesso"
    expect(find.text('Agenda Legale - Accesso'), findsOneWidget);

    // Verifica che ci sia il pulsante ACCEDI
    expect(find.text('ACCEDI'), findsOneWidget);
    
    // Verifica che non ci siano testi casuali come il vecchio contatore
    expect(find.text('0'), findsNothing);
  });
}