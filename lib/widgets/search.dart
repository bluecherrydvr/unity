import 'package:bluecherry_client/utils/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchToggleButton extends StatelessWidget {
  final bool searchVisible;
  final VoidCallback onPressed;

  final double iconSize;

  const SearchToggleButton({
    super.key,
    required this.searchVisible,
    required this.onPressed,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SquaredIconButton(
      icon: Icon(
        searchVisible ? Icons.search_off : Icons.search,
        size: iconSize,
      ),
      tooltip: searchVisible
          ? loc.disableSearch
          : MaterialLocalizations.of(context).searchFieldLabel,
      onPressed: onPressed,
    );
  }
}

class ToggleSearchBar extends StatelessWidget {
  final bool searchVisible;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;

  final bool showBottomDivider;

  const ToggleSearchBar({
    super.key,
    required this.searchVisible,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    this.showBottomDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: kThemeChangeDuration,
      curve: Curves.easeInOut,
      child: Builder(builder: (context) {
        if (!searchVisible) return const SizedBox.shrink();
        return Column(children: [
          const Divider(height: 1.0),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              decoration: InputDecoration(
                hintText: MaterialLocalizations.of(context).searchFieldLabel,
                isDense: true,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          if (showBottomDivider) ...[
            const Divider(height: 1.0),
            const SizedBox(height: 8.0),
          ],
        ]);
      }),
    );
  }
}
