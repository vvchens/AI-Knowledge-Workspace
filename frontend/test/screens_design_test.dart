import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_knowledge_workspace/screens/dashboard_screen.dart';
import 'package:ai_knowledge_workspace/screens/login_screen.dart';
import 'package:ai_knowledge_workspace/screens/project_overview_screen.dart';
import 'package:ai_knowledge_workspace/screens/users_screen.dart';

void main() {
  testWidgets('dashboard screen renders primary dashboard sections',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Total Projects'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });

  testWidgets(
      'login screen renders the workspace sign-in design with social sign in options',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Welcome to Workspace'), findsOneWidget);
    expect(
        find.text('Sign in to manage projects and datasets'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign in with Apple'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('project overview screen renders project detail sections',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProjectOverviewScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Missing project ID'), findsOneWidget);
  });

  testWidgets('users screen renders workspace user management sections',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UsersScreen(loadData: false)),
    );

    expect(find.text('Users'), findsWidgets);
    expect(find.text('Manage workspace access and project permissions.'),
        findsOneWidget);
    expect(find.text('Search users...'), findsOneWidget);
    expect(find.text('Invite user'), findsOneWidget);
    expect(find.text('No users found'), findsOneWidget);
  });
}
