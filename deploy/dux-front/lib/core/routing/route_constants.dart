class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String commands = '/commands';
  static const String dashboard = '/dashboard';
  static const String kpiDashboard = '/kpi-dashboard';
  static const String commandDetails = 'details/:id'; // nested under commands
  static const String station = '/station';
  static const String profile = '/profile';
  static const String gestionVente = '/gestion-vente';
  
  // Bon de Préparation paths
  static const String bonPreparation = '/pages/bon-preparation/list';
  static const String bonPreparationDetail = '/pages/bon-preparation/detail/:id';
  static const String bonPreparationSerialNumber = '/pages/bon-preparation/serial-number';
  static const String bonPreparationChecklist = '/pages/bon-preparation/checklist';
  
  // Bon de Sortie paths
  static const String bonSortie = '/pages/bon-sortie/list';
  static const String bonSortieDetail = '/pages/bon-sortie/detail/:id';

  // Client paths
  static const String clients = '/clients';
  static const String clientDetails = 'details/:id';
}

class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String dashboard = 'dashboard';
  static const String kpiDashboard = 'kpi-dashboard';
  static const String clients = 'clients';
  static const String clientDetails = 'clientDetails';
  static const String commands = 'commands';
  static const String commandDetails = 'commandDetails';
  static const String station = 'station';
  static const String profile = 'profile';
  static const String gestionVente = 'gestionVente';
  static const String activityFeed = 'activityFeed';
  
  // Bon de Préparation names
  static const String bonPreparationList = 'bonPreparationList';
  static const String bonPreparationDetail = 'bonPreparationDetail';
  static const String bonPreparationSerialNumber = 'bonPreparationSerialNumber';
  static const String bonPreparationChecklist = 'bonPreparationChecklist';
  static const String checklistAdmin = 'checklistAdmin';

  // Bon de Sortie names
  static const String bonSortieList = 'bonSortieList';
  static const String bonSortieDetail = 'bonSortieDetail';
}
