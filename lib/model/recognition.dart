
class Recognition {
  String id;
  String title;
  double confidence;
  Location location;

  Recognition.fromMap(Map map) {
    id = map['id'];
    title = map['title'];
    confidence = map['confidence'];
    location = map['location'] != null ? Location.fromMap(map['location']) : null;
  }
}

class Location {
  double left;
  double top;
  double right;
  double bottom;

  Location.fromMap(Map map) {
    left = map['left'];
    top = map['top'];
    right = map['right'];
    bottom = map['bottom'];
  }
}