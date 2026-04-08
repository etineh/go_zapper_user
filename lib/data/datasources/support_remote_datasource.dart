import 'package:gozapper/core/network/api_client.dart';

abstract class SupportRemoteDataSource {
  Future<void> submitEnquiry({
    required String fullName,
    required String email,
    required String enquiry,
  });
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  final ApiClient apiClient;

  SupportRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<void> submitEnquiry({
    required String fullName,
    required String email,
    required String enquiry,
  }) async {
    await apiClient.post(
      '/support/',
      data: {
        'fullName': fullName,
        'email': email,
        'enquiry': enquiry,
      },
    );
  }
}
