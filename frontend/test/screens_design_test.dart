import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_knowledge_workspace/screens/dashboard_screen.dart';
import 'package:ai_knowledge_workspace/screens/project_overview_screen.dart';

void main() {
  testWidgets('dashboard screen renders primary dashboard sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Total Projects'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });

  testWidgets('project overview screen renders project detail sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProjectOverviewScreen()));

    expect(find.text('Customer Support Bot'), findsWidgets);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Recent Conversations'), findsOneWidget);
  });
}
