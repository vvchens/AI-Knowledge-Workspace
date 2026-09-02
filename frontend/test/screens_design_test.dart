import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_knowledge_workspace/screens/dashboard_screen.dart';
import 'package:ai_knowledge_workspace/screens/login_screen.dart';
import 'package:ai_knowledge_workspace/screens/project_overview_screen.dart';

void main() {
  testWidgets('dashboard screen renders primary dashboard sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Total Projects'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });

  testWidgets('login screen renders the workspace sign-in design with social sign in options', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Welcome to Workspace'), findsOneWidget);
    expect(find.text('Sign in to manage projects and datasets'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign in with Apple'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('project overview screen renders project detail sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProjectOverviewScreen()));

    expect(find.text('Customer Support Bot'), findsWidgets);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Recent Conversations'), findsOneWidget);
  });
}
