class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String commands = '/commands';
  static const String dashboard = '/dashboard';
  static const String commandDetails = 'details/:id'; // nested under commands
  static const String station = '/station';
  static const String profile = '/profile';
  
  // Bon de Préparation paths
  static const String bonPreparation = '/pages/bon-preparation/list';
  static const String bonPreparationDetail = '/pages/bon-preparation/detail/:id';
  static const String bonPreparationSerialNumber = '/pages/bon-preparation/serial-number';
}

class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String dashboard = 'dashboard';
  static const String commands = 'commands';
  static const String commandDetails = 'commandDetails';
  static const String station = 'station';
  static const String profile = 'profile';
  
  // Bon de Préparation names
  static const String bonPreparationList = 'bonPreparationList';
  static const String bonPreparationDetail = 'bonPreparationDetail';
  static const String bonPreparationSerialNumber = 'bonPreparationSerialNumber';
}
