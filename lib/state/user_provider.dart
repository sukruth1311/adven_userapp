// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:user_app/core/services/firestore_service.dart';
// import '../../data/models/app_user.dart';
// import 'auth_provider.dart';
// import 'firestore_service_provider.dart';

// final appUserProvider = StreamProvider<AppUser?>((ref) {
//   final authAsync = ref.watch(authStateProvider);

//   return authAsync.when(
//     data: (User? user) {
//       if (user == null) {
//         return const Stream.empty();
//       }

//       return ref.read(firestoreServiceProvider).streamUser(user.uid);
//     },
//     loading: () => const Stream.empty(),
//     error: (_, __) => const Stream.empty(),
//   );
// });
