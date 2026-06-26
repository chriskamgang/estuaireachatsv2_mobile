// Zones du Cameroun pour estimation de livraison

enum ShippingZone { littoral, centre, ouest, nord, sud, est, international }

const Map<String, ShippingZone> cityToZone = {
  // Littoral
  'douala': ShippingZone.littoral,
  'nkongsamba': ShippingZone.littoral,
  'edea': ShippingZone.littoral,
  'loum': ShippingZone.littoral,
  'manjo': ShippingZone.littoral,
  'mbanga': ShippingZone.littoral,
  'limbe': ShippingZone.littoral,
  'buea': ShippingZone.littoral,
  'kumba': ShippingZone.littoral,
  'tiko': ShippingZone.littoral,
  // Centre
  'yaounde': ShippingZone.centre,
  'mbalmayo': ShippingZone.centre,
  'obala': ShippingZone.centre,
  'eseka': ShippingZone.centre,
  'akonolinga': ShippingZone.centre,
  // Ouest
  'bafoussam': ShippingZone.ouest,
  'dschang': ShippingZone.ouest,
  'mbouda': ShippingZone.ouest,
  'foumban': ShippingZone.ouest,
  'bandjoun': ShippingZone.ouest,
  'bafang': ShippingZone.ouest,
  'bamenda': ShippingZone.ouest,
  'kumbo': ShippingZone.ouest,
  'wum': ShippingZone.ouest,
  // Nord
  'garoua': ShippingZone.nord,
  'maroua': ShippingZone.nord,
  'ngaoundere': ShippingZone.nord,
  'kousseri': ShippingZone.nord,
  'mokolo': ShippingZone.nord,
  'guider': ShippingZone.nord,
  // Sud
  'ebolowa': ShippingZone.sud,
  'kribi': ShippingZone.sud,
  'sangmelima': ShippingZone.sud,
  'campo': ShippingZone.sud,
  // Est
  'bertoua': ShippingZone.est,
  'batouri': ShippingZone.est,
  'yokadouma': ShippingZone.est,
  'abong-mbang': ShippingZone.est,
};

const Map<ShippingZone, List<ShippingZone>> adjacentZones = {
  ShippingZone.littoral: [ShippingZone.centre, ShippingZone.ouest, ShippingZone.sud],
  ShippingZone.centre: [ShippingZone.littoral, ShippingZone.ouest, ShippingZone.sud, ShippingZone.est],
  ShippingZone.ouest: [ShippingZone.littoral, ShippingZone.centre],
  ShippingZone.sud: [ShippingZone.centre, ShippingZone.littoral],
  ShippingZone.est: [ShippingZone.centre],
  ShippingZone.nord: [],
};

class ShippingRate {
  final String standardDays;
  final String expressDays;
  final double standardFee;
  final double expressFee;
  final String label;

  const ShippingRate({
    required this.standardDays,
    required this.expressDays,
    required this.standardFee,
    required this.expressFee,
    required this.label,
  });
}

ShippingZone _getZone(String? city, String? country) {
  if (country != null &&
      country.isNotEmpty &&
      country != 'CM' &&
      country != 'Cameroun' &&
      country != 'cameroun') {
    return ShippingZone.international;
  }
  final normalized = (city ?? '').toLowerCase().trim();
  return cityToZone[normalized] ?? ShippingZone.centre;
}

ShippingRate estimateShipping(
  String? sellerCity,
  String? sellerCountry,
  String? buyerCity,
  String? buyerCountry,
) {
  final sellerZone = _getZone(sellerCity, sellerCountry);
  final buyerZone = _getZone(buyerCity, buyerCountry);

  // International
  if (sellerZone == ShippingZone.international || buyerZone == ShippingZone.international) {
    return const ShippingRate(
      standardDays: '15-25 jours',
      expressDays: '7-12 jours',
      standardFee: 5000,
      expressFee: 12000,
      label: 'Livraison internationale',
    );
  }

  // Same zone
  if (sellerZone == buyerZone) {
    final sameCity =
        (sellerCity ?? '').toLowerCase().trim() == (buyerCity ?? '').toLowerCase().trim();
    if (sameCity) {
      return const ShippingRate(
        standardDays: '1-2 jours',
        expressDays: 'Meme jour',
        standardFee: 1000,
        expressFee: 2500,
        label: 'Livraison locale',
      );
    }
    return const ShippingRate(
      standardDays: '1-2 jours',
      expressDays: '1 jour',
      standardFee: 1500,
      expressFee: 3000,
      label: 'Livraison locale',
    );
  }

  // Adjacent zones
  final sellerAdj = adjacentZones[sellerZone] ?? [];
  final buyerAdj = adjacentZones[buyerZone] ?? [];
  if (sellerAdj.contains(buyerZone) || buyerAdj.contains(sellerZone)) {
    return const ShippingRate(
      standardDays: '1-2 jours',
      expressDays: '1 jour',
      standardFee: 2000,
      expressFee: 4000,
      label: 'Livraison intercite',
    );
  }

  // Far zones
  return const ShippingRate(
    standardDays: '2-3 jours',
    expressDays: '1-2 jours',
    standardFee: 3500,
    expressFee: 7000,
    label: 'Livraison longue distance',
  );
}
