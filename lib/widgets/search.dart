import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

mixin Searchable<T extends StatefulWidget> on State<T> {
  bool _searchVisible = false;
  bool get searchVisible => _searchVisible;
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  String searchQuery = '';

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
  }

  void toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
    });
    if (_searchVisible) {
      searchFocusNode.requestFocus();
    } else {
      searchFocusNode.unfocus();
    }
  }

  void onSearchChanged(String text) {
    setState(() => searchQuery = text);
  }
}

class SearchToggleButton extends StatelessWidget {
  final Searchable searchable;

  final double iconSize;

  const SearchToggleButton({
    super.key,
    required this.searchable,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SquaredIconButton(
      icon: Icon(
        searchable.searchVisible ? Icons.search_off : Icons.search,
        size: iconSize,
      ),
      tooltip: searchable.searchVisible
          ? loc.disableSearch
          : MaterialLocalizations.of(context).searchFieldLabel,
      onPressed: searchable.toggleSearch,
    );
  }
}

class ToggleSearchBar extends StatelessWidget {
  final Searchable searchable;

  final bool showBottomDivider;

  const ToggleSearchBar({
    super.key,
    required this.searchable,
    this.showBottomDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: kThemeChangeDuration,
      curve: Curves.easeInOut,
      child: Builder(builder: (context) {
        if (!searchable.searchVisible) return const SizedBox.shrink();
        return Column(children: [
          const Divider(height: 1.0),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchable.searchController,
              focusNode: searchable.searchFocusNode,
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
              onChanged: searchable.onSearchChanged,
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
