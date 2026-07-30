import 'package:go_router/go_router.dart';

import '../../data/model/vehicle_result_data.dart';
import '../../module/vehicle_result/view/vehicle_result_page.dart';
import '../../module/vehicle_search/view/vehicle_search_page.dart';
import '../di/service_locator.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => VehicleSearchPage(viewModel: getIt()),
    ),
    GoRoute(
      path: '/resultado',
      builder: (context, state) {
        final data = state.extra as VehicleResultData;
        return VehicleResultPage(data: data);
      },
    ),
  ],
);
