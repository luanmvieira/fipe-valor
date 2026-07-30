import '../../../core/mvvm/base_view_model.dart';
import '../../../core/util/network_error_message.dart';
import '../../../data/model/fipe_option.dart';
import '../../../data/model/vehicle_result_data.dart';
import '../../../data/model/vehicle_type.dart';
import '../../../data/repository/fipe_repository.dart';
import '../../../data/repository/photo_repository.dart';

enum _FailedStage { brands, models, years, search }

class VehicleSearchViewModel extends BaseViewModel {
  final FipeRepository _fipeRepository;
  final PhotoRepository _photoRepository;

  VehicleType vehicleType = VehicleType.carros;
  List<FipeOption> brands = [];
  List<FipeOption> models = [];
  List<FipeOption> years = [];

  FipeOption? selectedBrand;
  FipeOption? selectedModel;
  FipeOption? selectedYear;

  bool loadingBrands = false;
  bool loadingModels = false;
  bool loadingYears = false;

  VehicleResultData? result;

  _FailedStage? _failedStage;
  bool get canRetry => _failedStage != null;

  VehicleSearchViewModel(this._fipeRepository, this._photoRepository);

  Future<void> loadBrands() async {
    if (brands.isNotEmpty || loadingBrands) return;
    await _fetchBrands();
  }

  Future<void> changeVehicleType(VehicleType type) async {
    if (type == vehicleType) return;

    vehicleType = type;
    selectedBrand = null;
    selectedModel = null;
    selectedYear = null;
    brands = [];
    models = [];
    years = [];
    notifyListeners();

    await _fetchBrands();
  }

  Future<void> retry() async {
    final stage = _failedStage;
    if (stage == _FailedStage.brands) {
      await _fetchBrands();
    } else if (stage == _FailedStage.models && selectedBrand != null) {
      await selectBrand(selectedBrand!);
    } else if (stage == _FailedStage.years && selectedModel != null) {
      await selectModel(selectedModel!);
    } else if (stage == _FailedStage.search) {
      await search();
    }
  }

  Future<void> _fetchBrands() async {
    loadingBrands = true;
    setError(null);
    try {
      brands = await _fipeRepository.getBrands(vehicleType);
      _failedStage = null;
    } catch (error) {
      _failedStage = _FailedStage.brands;
      setError('Não foi possível carregar as marcas. ${networkErrorCause(error)}');
    } finally {
      loadingBrands = false;
      notifyListeners();
    }
  }

  Future<void> selectBrand(FipeOption brand) async {
    selectedBrand = brand;
    selectedModel = null;
    selectedYear = null;
    models = [];
    years = [];
    loadingModels = true;
    setError(null);
    notifyListeners();

    try {
      models = await _fipeRepository.getModels(vehicleType, brand.code);
      _failedStage = null;
    } catch (error) {
      _failedStage = _FailedStage.models;
      setError('Não foi possível carregar os modelos. ${networkErrorCause(error)}');
    } finally {
      loadingModels = false;
      notifyListeners();
    }
  }

  Future<void> selectModel(FipeOption model) async {
    selectedModel = model;
    selectedYear = null;
    years = [];
    loadingYears = true;
    setError(null);
    notifyListeners();

    try {
      years = await _fipeRepository.getYears(vehicleType, selectedBrand!.code, model.code);
      _failedStage = null;
    } catch (error) {
      _failedStage = _FailedStage.years;
      setError('Não foi possível carregar os anos. ${networkErrorCause(error)}');
    } finally {
      loadingYears = false;
      notifyListeners();
    }
  }

  void selectYear(FipeOption year) {
    selectedYear = year;
    notifyListeners();
  }

  bool get canSearch => selectedBrand != null && selectedModel != null && selectedYear != null;

  Future<void> search() async {
    if (!canSearch) return;

    setError(null);
    setLoading(true);
    try {
      final fipeValue = await _fipeRepository.getValue(
        vehicleType,
        selectedBrand!.code,
        selectedModel!.code,
        selectedYear!.code,
      );
      final photoUrl = await _photoRepository.searchPhoto(
        fipeValue.brand,
        fipeValue.model,
        vehicleType,
      );
      result = VehicleResultData(fipeValue: fipeValue, photoUrl: photoUrl);
      _failedStage = null;
      notifyListeners();
    } catch (error) {
      _failedStage = _FailedStage.search;
      setError('Não foi possível consultar o valor FIPE. ${networkErrorCause(error)}');
    } finally {
      setLoading(false);
    }
  }

  void clearResult() {
    result = null;
  }
}
