import 'package:get_it/get_it.dart';
import 'services/image_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => ImageService());
}
