part of 'settings.dart';

class DateFormatSection extends StatelessWidget {
  const DateFormatSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return LayoutBuilder(builder: (context, consts) {
      final formats = [
        'dd MMMM yyyy',
        'EEEE, dd MMMM yyyy',
        'EE, dd MMMM yyyy',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'MM-dd-yyyy',
        'dd-MM-yyyy',
        'yyyy-MM-dd'
      ];

      if (consts.maxWidth >= 800) {
        final crossAxisCount = consts.maxWidth >= 870 ? 4 : 3;
        return Wrap(
          children: formats.map((format) {
            return SizedBox(
              width: consts.maxWidth / crossAxisCount,
              child: RadioListTile(
                value: format,
                groupValue: settings.dateFormat.pattern,
                onChanged: (value) {
                  settings.dateFormat = DateFormat(format, 'en_US');
                },
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(
                  DateFormat(format, 'en_US')
                      .format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
                ),
              ),
            );
          }).toList(),
        );
      } else {
        return Column(
          children: formats.map((format) {
            return RadioListTile(
              value: format,
              groupValue: settings.dateFormat.pattern,
              onChanged: (value) {
                settings.dateFormat = DateFormat(format, 'en_US');
              },
              controlAffinity: ListTileControlAffinity.trailing,
              title: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8.0),
                child: Text(
                  DateFormat(format, 'en_US')
                      .format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
                ),
              ),
            );
          }).toList(),
        );
      }
    });
  }
}
