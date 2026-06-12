import '../../models/admin/account_status_flag.dart';

abstract interface class AccountManagementRepository {
  Future<AccountStatusFlag> fetchUserStatus(String userId);
  Future<AccountStatusFlag> fetchPartnerStatus(String partnerId);
  Future<void> updateUserStatus(String userId, AccountStatusFlag status, {String? note});
  Future<void> updatePartnerStatus(String partnerId, AccountStatusFlag status, {String? note});
  Future<List<String>> fetchSuspendedUserIds();
  Future<List<String>> fetchSuspendedPartnerIds();
}
