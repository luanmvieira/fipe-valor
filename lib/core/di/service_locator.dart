import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../data/repository/fipe_repository.dart';
import '../../data/repository/photo_repository.dart';
import '../../module/vehicle_search/viewmodel/vehicle_search_view_model.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<Dio>(
    () => Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    )),
  );

  getIt.registerLazySingleton<PhotoRepository>(() => PhotoRepository(getIt()));
  getIt.registerLazySingleton<FipeRepository>(() => FipeRepository(getIt()));

  getIt.registerFactory<VehicleSearchViewModel>(
    () => VehicleSearchViewModel(getIt(), getIt()),
  );
}
