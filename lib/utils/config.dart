/// Parses the config file content and returns a map with the config values.
///
/// The config file content is a string with the following format:
///
/// ```
/// [section1]
/// key1=value1
/// key2=value2
///
/// [section2]
/// key2=value2
///
/// [section3]
/// key3=value3
/// ```
///
/// The `[overlay]` section is a special case, because it can have multiple
/// values. In this case, the returned map will have a list of maps, where each
/// map is a set of key-value pairs.
///
/// For example, the following config file content:
///
/// ```
/// [overlay]
/// key1=value1
/// key2=value2
///
/// [overlay]
/// key3=value3
/// ```
///
/// Will return the following map:
///
/// ```
/// {
///  'overlay': [
///   {'key1': 'value1', 'key2': 'value2'},
///   {'key3': 'value3'}
///  ],
/// }
/// ```
///
/// The config file content can also have comments, which are lines that start
/// with `#`. These lines are ignored. Empty lines are also ignored.
Map<String, dynamic> parseConfig(String configFileContent) {
  var config = <String, dynamic>{};
  String? currentSection;

  for (var line in configFileContent.split('\n')) {
    line = line.trim();

    if (line.startsWith('#') || line.isEmpty) continue;

    if (line.startsWith('[') && line.endsWith(']')) {
      currentSection = line.substring(1, line.length - 1).toLowerCase();
      config[currentSection] = currentSection == 'overlay' ? [{}] : {};
    } else if (currentSection != null) {
      var parts = line.split('=');
      var key = parts[0].trim().toLowerCase();
      var value = parts[1].trim();

      final dynamic parsedValue = () {
        if (bool.tryParse(value.toLowerCase()) != null) {
          return bool.parse(value);
        }
        if (int.tryParse(value) != null) return int.tryParse(value);
        if (double.tryParse(value) != null) return double.tryParse(value);
        if (value.startsWith('"') && value.endsWith('"')) {
          return value.substring(1, value.length - 1);
        }
        return value;
      }();

      if (config[currentSection] is List) {
        ((config[currentSection] as List).last as Map)
            .addAll({key: parsedValue});
      } else {
        config[currentSection][key] = parsedValue;
      }
    }
  }

  return config;
}
