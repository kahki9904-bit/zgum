import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/alert/models/partner_event.dart';

final partnerMyEventsProvider = StateProvider<List<PartnerEvent>>((ref) => []);
