class StorageService {
  Future<String> uploadFile(String path) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500';
  }
}
