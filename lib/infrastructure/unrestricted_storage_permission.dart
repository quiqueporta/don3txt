import 'package:don3txt/infrastructure/storage_permission.dart';

class UnrestrictedStoragePermission implements StoragePermission {
  @override
  Future<bool> request() async => true;
}
