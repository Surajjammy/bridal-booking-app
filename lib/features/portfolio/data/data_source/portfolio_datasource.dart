import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/features/portfolio/data/portfolio_model.dart';

class PortfolioDatasource {
  final FirebaseFirestore firestore;

  PortfolioDatasource(this.firestore);

  Future<List<PortfolioModel>> getPortfolio(String artistId) async {
    final response = await firestore
        .collection('artists')
        .doc(artistId)
        .collection('portfolio')
        .get();

    return response.docs.map((doc) {
      return PortfolioModel.fromMap(
        doc.data(),
      );
    }).toList();
  }
}
