enum AppRole {
  owner('OWNER', 'Owner'),
  receptionist('RECEPTIONIST', 'Receptionist');

  const AppRole(this.databaseValue, this.label);
  final String databaseValue;
  final String label;
  bool get canOperate => this == receptionist;
  String get home => this == owner ? '/owner' : '/dashboard';
  String get stationsPath => this == owner ? '/owner/operations' : '/stations';
  String get gameTerminalPath => '/game-terminal';
  String get customersPath => '/customers';
  String get expensesPath => '/expenses';
  String get transactionsPath => '/transactions';
  String get dailyReportPath => '/daily-report';
  String get stationDetailsPath => '/station-details';
  String get sessionsPath => this == owner ? '/owner/sessions' : '/sessions';
  String get bookingsPath => this == owner ? '/owner/bookings' : '/bookings';
  String get reportsPath => '/owner/reports';
  String get accountPath => this == owner ? '/owner/account' : '/account';
  bool canAccess(String path) =>
      path == home || path == stationsPath || path == sessionsPath || path == bookingsPath || path == accountPath || (this == owner && path == reportsPath) || (this == receptionist && [gameTerminalPath,customersPath,expensesPath,transactionsPath,dailyReportPath,stationDetailsPath].contains(path));
  static AppRole? parse(Object? value) => switch (value) {
    'OWNER' => owner,
    'RECEPTIONIST' => receptionist,
    _ => null,
  };
}
