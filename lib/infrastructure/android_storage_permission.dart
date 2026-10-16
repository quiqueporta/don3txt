import 'package:permission_handler/permission_handler.dart';
import 'package:don3txt/infrastructure/storage_permission.dart';

class AndroidStoragePermission implements StoragePermission {
  @override
  Future<bool> request() async {
    if (await Permission.manageExternalStorage.isGranted) return true;

    final status = await Permission.manageExternalStorage.request();

    return status.isGranted;
  }
}
