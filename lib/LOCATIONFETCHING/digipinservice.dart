

class DigiPinService {
  static String getDigiPin(double latitude, double longitude) {
    const double minLat = 2.5;
    const double maxLat = 38.5;
    const double minLng = 63.5;
    const double maxLng = 99.5;

    if (latitude < minLat ||
        latitude > maxLat ||
        longitude < minLng ||
        longitude > maxLng) {
      return '';
    }

    const List<String> characters = [
      'F',
      'C',
      '9',
      '8',
      'J',
      '3',
      '2',
      '7',
      'K',
      '4',
      '5',
      '6',
      'L',
      'M',
      'P',
      'T',
    ];

    double currentMinLat = minLat;
    double currentMaxLat = maxLat;
    double currentMinLng = minLng;
    double currentMaxLng = maxLng;

    String digiPin = '';

    for (int level = 0; level < 10; level++) {
      final latStep =
          (currentMaxLat - currentMinLat) / 4;

      final lngStep =
          (currentMaxLng - currentMinLng) / 4;

      int row = ((currentMaxLat - latitude) / latStep).floor();

      int column =
          ((longitude - currentMinLng) / lngStep).floor();

      if (row < 0) row = 0;
      if (row > 3) row = 3;

      if (column < 0) column = 0;
      if (column > 3) column = 3;

      final index = row * 4 + column;

      digiPin += characters[index];

      currentMaxLat =
          currentMaxLat - (latStep * row);

      currentMinLat =
          currentMaxLat - latStep;

      currentMinLng =
          currentMinLng + (lngStep * column);

      currentMaxLng =
          currentMinLng + lngStep;
    }

    return digiPin;
  }
}