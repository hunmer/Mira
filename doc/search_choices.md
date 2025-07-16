# search_choices

Highly customizable Widget to search through a single or multiple choices list in a dialog box or a menu. Supports pagination and future/network/API/webservice searches with sort and filter. Each release is thoroughly tested through automated integrated testing with Flutster.

## Platforms

This widget has been successfully tested on iOS, Android, Linux and [Chrome](https://lcuis.github.io/search_choices/demo/). It is expected to work fine on MacOS and Windows.

## Examples

The following examples are extracted from the [example project available in the repository](https://github.com/lcuis/search_choices/tree/master/example).
More examples are available in this project.

### Gallery

See code below.

| Example name                                                                                | Demonstration                                                                                                                                  |
|---------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| [Single dialog](#Single-dialog)                                                             | ![Single dialog](https://searchchoices.jod.li/Single%20dialog.gif)                                                                             |
| [Multi dialog](#Multi-dialog)                                                               | ![Multi dialog](https://searchchoices.jod.li/Multi%20dialog.gif)                                                                               |
| [Single done button<br>dialog](#Single-done-button-dialog)                                  | ![Single done button dialog](https://searchchoices.jod.li/Single%20done%20button%20dialog.gif)                                                 |
| [Multi custom display<br>dialog](#Multi-custom-display-dialog)                              | ![Multi custom display dialog](https://searchchoices.jod.li/Multi%20custom%20display%20dialog.gif)                                             |
| [Multi select 3 dialog](#Multi-select-3-dialog)                                             | ![Multi select 3 dialog](https://searchchoices.jod.li/Multi%20select%203%20dialog.gif)                                                         |
| [Single menu](#Single-menu)                                                                 | ![Single menu](https://searchchoices.jod.li/Single%20menu.gif)                                                                                 |
| [Multi menu](#Multi-menu)                                                                   | ![Multi menu](https://searchchoices.jod.li/Multi%20menu.gif)                                                                                   |
| [Multi menu select<br>all/none](#Multi-menu-select-allnone)                                 | ![Multi menu select all or none](https://searchchoices.jod.li/Multi%20menu%20select%20all%20or%20none.gif)                                     |
| [Multi dialog select<br>all/none without clear](#Multi-dialog-select-allnone-without-clear) | ![Multi dialog select all or none without clear](https://searchchoices.jod.li/Multi%20dialog%20select%20all%20or%20none%20without%20clear.gif) |
| [Single dialog custom<br>keyboard](#Single-dialog-custom-keyboard)                          | ![Single dialog custom keyboard](https://searchchoices.jod.li/Single%20dialog%20custom%20keyboard.gif)                                         |
| [Single dialog object](#Single-dialog-object)                                               | ![Single dialog object](https://searchchoices.jod.li/Single%20dialog%20object.gif)                                                             |
| [Single dialog overflow](#Single-dialog-overflow)                                           | ![Single dialog overflow](https://searchchoices.jod.li/Single%20dialog%20overflow.gif)                                                         |
| [Single dialog readOnly](#Single-dialog-readOnly)                                           | ![Single dialog readOnly](https://searchchoices.jod.li/Single%20dialog%20readOnly.png)                                                         |
| [Single dialog disabled](#Single-dialog-disabled)                                           | ![Single dialog disabled](https://searchchoices.jod.li/Single%20dialog%20disabled.png)                                                         |
| [Single dialog<br>editable items](#Single-dialog-editable-items)                            | ![Single dialog editable items](https://searchchoices.jod.li/Single%20dialog%20editable%20items.gif)                                           |
| [Single menu<br>editable items](#Single-menu-editable-items)                                | ![Single menu editable items](https://searchchoices.jod.li/Single%20menu%20editable%20items.gif)                                               |
| [Multi dialog<br>editable items](#Multi-dialog-editable-items)                              | ![Multi dialog editable items](https://searchchoices.jod.li/Multi%20dialog%20editable%20items.gif)                                             |
| [Single dialog dark<br>mode](#Single-dialog-dark-mode)                                      | ![Single dialog dark mode](https://searchchoices.jod.li/Single%20dialog%20dark%20mode.gif)                                                     |
| [Single dialog ellipsis](#Single-dialog-ellipsis)                                           | ![Single dialog ellipsis](https://searchchoices.jod.li/Single%20dialog%20ellipsis.gif)                                                         |
| [Single dialog right<br>to left](#Single-dialog-right-to-left)                              | ![Single dialog right to left](https://searchchoices.jod.li/Single%20dialog%20right%20to%20left.gif)                                           |
| [Update value from<br>outside the plugin](#Update-value-from-outside-the-plugin)            | ![Update value from outside the plugin](https://searchchoices.jod.li/Update%20value%20from%20outside%20the%20plugin.gif)                       |
| [Multi select 3 menu<br>no-autofocus](#Multi-select-3-menu-no-autofocus)                    | ![Multi select 3 menu no-autofocus](https://searchchoices.jod.li/Multi%20select%203%20menu%20no-autofocus.gif)                                 |
| [Multi dialog with<br>count and wrap](#Multi-dialog-with-count-and-wrap)                    | ![Multi dialog with count and wrap](https://searchchoices.jod.li/Multi%20dialog%20with%20count%20and%20wrap.gif)                               |
| [Single dialog open<br>and set search terms](#Single-dialog-open-and-set-search-terms)      | ![Single dialog open and set search terms](https://searchchoices.jod.li/Single%20dialog%20open%20and%20set%20search%20terms.gif)               |
| [Single dialog custom<br>dialog](#Single-dialog-custom-dialog)                              | ![Single dialog custom dialog](https://searchchoices.jod.li/Single%20dialog%20custom%20dialog.gif)                                             |
| [Single dialog custom<br>decorations](#Single-dialog-custom-decorations)                    | ![Single dialog custom decorations](https://searchchoices.jod.li/Single%20dialog%20custom%20decorations.gif)                                   |
| [Single dialog paged](#Single-dialog-paged)                                                 | ![Single dialog paged](https://searchchoices.jod.li/Single%20dialog%20paged.gif)                                                               |
| [Multi dialog paged<br>rtl](#Multi-dialog-paged-rtl)                                        | ![Multi dialog paged rtl](https://searchchoices.jod.li/Multi%20dialog%20paged%20rtl.gif)                                                       |
| [Single dialog paged<br>custom pagination](#Single-dialog-paged-custom-pagination)          | ![Single dialog paged custom pagination](https://searchchoices.jod.li/Single%20dialog%20paged%20custom%20pagination.gif)                       |
| [Single menu paged](#Single-menu-paged)                                                     | ![Single menu paged](https://searchchoices.jod.li/Single%20menu%20paged.gif)                                                                   |
| [Single dialog<br>paged future](#Single-dialog-paged-future)                                | ![Single dialog paged future](https://searchchoices.jod.li/Single%20dialog%20paged%20future.gif)                                               |
| [Multi menu paged<br>future](#Multi-menu-paged-future)                                      | ![Multi menu paged future](https://searchchoices.jod.li/Multi%20menu%20paged%20future.gif)                                                     |
| [Single dialog<br>custom empty list](#Single-dialog-custom-empty-list)                      | ![Single dialog custom empty list](https://searchchoices.jod.li/Single%20dialog%20custom%20empty%20list.gif)                                   |
| [Single dialog future<br>custom empty list](#Single-dialog-future-custom-empty-list)        | ![Single dialog future custom empty list](https://searchchoices.jod.li/Single%20dialog%20future%20custom%20empty%20list.gif)                   |
| [Single dialog onTap](#Single-dialog-onTap)                                                 | ![Single dialog onTap](https://searchchoices.jod.li/Single%20dialog%20onTap.gif)                                                               |
| [Multi dialog paged<br>future](#Multi-dialog-paged-future)                                  | ![Multi dialog paged future](https://searchchoices.jod.li/Multi%20dialog%20paged%20future.gif)                                                 |
| [Single dialog future<br>custom error button](#Single-dialog-future-custom-error-button)    | ![Single dialog future custom error button](https://searchchoices.jod.li/Single%20dialog%20future%20custom%20error%20button.gif)               |
| [Single dialog paged<br>delayed](#Single-dialog-paged-delayed)                              | ![Single dialog paged delayed](https://searchchoices.jod.li/Single%20dialog%20paged%20delayed.gif)                                             |
| [Single dialog paged<br>future delayed](#Single-dialog-paged-future-delayed)                | ![Single dialog paged future delayed](https://searchchoices.jod.li/Single%20dialog%20paged%20future%20delayed.gif)                             |
| [Single dialog custom<br>field presentation](#Single-dialog-custom-field-presentation)      | ![Single dialog custom field presentation](https://searchchoices.jod.li/Single%20dialog%20custom%20field%20presentation.gif)                   |
| [Single custom showDialogFn](#Single-custom-showDialogFn)                                   | ![Single custom showDialogFn](https://searchchoices.jod.li/Single%20custom%20showDialogFn.gif)                                                 |
| [Validator in form](#Validator-in-form)                                                     | ![Validator in form](https://searchchoices.jod.li/Validator%20in%20form.gif)                                                                   |

### Code

#### Plugin usage

Add to your `pubspec.yaml` in the `dependencies` section:
```
  search_choices:
```

Get packages with command:
```
flutter packages get
```

Import:
```dart
import 'package:search_choices/search_choices.dart';
```

Call either the single choice or the multiple choice constructor.

#### Single choice constructor

Search choices Widget with a single choice that opens a dialog or a menu to let the user do the selection conveniently with a search.

```dart
  factory SearchChoices.single({
    Key? key,
    required List<DropdownMenuItem<T>> items,
    Function? onChanged,
    T? value,
    TextStyle? style,
    dynamic searchHint,
    dynamic hint,
    dynamic disabledHint,
    dynamic icon = const Icon(Icons.arrow_drop_down),
    dynamic underline,
    dynamic doneButton,
    dynamic label,
    dynamic closeButton = "Close",
    bool displayClearIcon = true,
    Icon clearIcon = const Icon(Icons.clear),
    Color? iconEnabledColor,
    Color? iconDisabledColor,
    double iconSize = 24.0,
    bool isExpanded = false,
    bool isCaseSensitiveSearch = false,
    Function? searchFn,
    Function? onClear,
    Function? selectedValueWidgetFn,
    TextInputType keyboardType = TextInputType.text,
    Function? validator,
    Function? displayItem,
    bool dialogBox = true,
    BoxConstraints? menuConstraints,
    bool readOnly = false,
    Color? menuBackgroundColor,
    bool? rightToLeft,
    bool autofocus = true,
    Function? selectedAggregateWidgetFn,
    dynamic padding = 10.0,
    Function? setOpenDialog,
    Widget Function  (Widget titleBar,Widget searchBar, Widget list, Widget closeButton, BuildContext dropDownContext,)? buildDropDownDialog,
    EdgeInsets? dropDownDialogPadding,
    InputDecoration searchInputDecoration = const InputDecoration(
      prefixIcon: Icon(
        Icons.search,
        size: 24,
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 12),
    ),
    int? itemsPerPage,
    PointerThisPlease<int>? currentPage,
    Widget Function(Widget listWidget, int totalFilteredItemsNb,
            Function updateSearchPage)?
        customPaginationDisplay,
    Future<Tuple2<List<DropdownMenuItem>, int>> Function(
            String? keyword,
            String? orderBy,
            bool? orderAsc,
            List<Tuple2<String, String>>? filters,
            int? pageNb)?
        futureSearchFn,
    Map<String, Map<String, dynamic>>? futureSearchOrderOptions,
    Map<String, Map<String, Object>>? futureSearchFilterOptions,
    dynamic emptyListWidget,
    Function? onTap,
    Function? futureSearchRetryButton,
    int? searchDelay,
    Widget Function(Widget fieldWidget,{bool selectionIsValid})? fieldPresentationFn,
    Decoration? fieldDecoration,
    Widget? clearSearchIcon,
    Future<void> Function(
      BuildContext context,
      Widget Function({
        String searchTerms,
      })
          menuWidget,
      String searchTerms,
    )?
        showDialogFn,
    FormFieldSetter<T>? onSaved,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
    String? restorationId,
    Function(Function pop)? giveMeThePop,
    Widget Function({
      required bool filter,
      required BuildContext context,
      required Function onPressed,
      int? nbFilters,
      bool? orderAsc,
      String? orderBy,
    })?
        buildFutureFilterOrOrderButton,
    Widget Function({
        required List<Tuple3<int, DropdownMenuItem, bool>> itemsToDisplay,
        required ScrollController scrollController,
        required bool thumbVisibility,
        required Widget emptyListWidget,
        required void Function(int index, T value, bool itemSelected) itemTapped,
        required Widget Function(DropdownMenuItem item, bool isItemSelected)
        displayItem,
    })?
      searchResultDisplayFn,
})
```

* items with child: Widget displayed ; value: any object with .toString() used to match search keyword.
* onChanged Function with parameter: value not returning executed after the selection is done.
* value value to be preselected.
* style used for the hint if it is given is String.
* searchHint String|Widget|Function with no parameter returning String|Widget displayed at the top of the search dialog box.
* hint String|Widget|Function with no parameter returning String|Widget displayed before any value is selected or after the selection is cleared.
* disabledHint String|Widget|Function with no parameter returning String|Widget displayed instead of hint when the widget is displayed.
* icon String|Widget|Function with parameter: value returning String|Widget displayed next to the selected item or the hint if none.
* underline String|Widget|Function with parameter: value returning String|Widget displayed below the selected item or the hint if none.
* doneButton String|Widget|Function with parameter: value returning String|Widget displayed at the top of the search dialog box.
* label String|Widget|Function with parameter: value returning String|Widget displayed above the selected item or the hint if none.
* closeButton String|Widget|Function with parameter: value returning String|Widget displayed at the bottom of the search dialog box.
* displayClearIcon whether or not to display an icon to clear the selected value.
* clearIcon Icon to be used for clearing the selected value.
* iconEnabledColor Color to be used for enabled icons.
* iconDisabledColor Color to be used for disabled icons.
* iconSize for the icons next to the selected value (icon and clearIcon).
* isExpanded can be necessary to avoid pixel overflows (zebra symptom).
* isCaseSensitiveSearch only used when searchFn is not specified.
* searchFn Function with parameters: keyword, items returning List<int> as the list of indexes for the items to be displayed.
* onClear Function with no parameter not returning executed when the clear icon is tapped.
* selectedValueWidgetFn Function with parameter: item returning Widget to be used to display the selected value.
* keyboardType used for the search.
* validator Function with parameter: value returning String displayed below selected value when not valid and null when valid.
* displayItem Function with parameters: item, selected returning Widget to be displayed in the search list.
* dialogBox whether the search should be displayed as a dialog box or as a menu below the selected value if any.
* menuConstraints BoxConstraints used to define the zone where to display the search menu. Example: BoxConstraints.tight(Size.fromHeight(250)) . Not to be used for dialogBox = true.
* readOnly bool whether to let the user choose the value to select or just present the selected value if any.
* menuBackgroundColor Color background color of the menu whether in dialog box or menu mode.
* rightToLeft bool mirrors the widgets display for right to left languages defaulted to app.
* autofocus bool automatically focuses on the search field bringing up the keyboard defaulted to true.
* selectedAggregateWidgetFn Function with parameter: list of widgets presenting selected values, returning Widget to be displayed to present the selected items.
* padding double or EdgeInsets sets the padding around the DropdownButton, defaulted to 10.0.
* setOpenDialog Function sets the function to call to set the function to call in order to open the dialog with the search terms string as a parameter, defaulted to null.
* buildDropDownDialog Function controls the layout of the dropdown dialog.
* dropDownDialogPadding EdgeInsets sets the padding between the screen and the dialog.
* searchInputDecoration InputDecoration sets the search bar decoration.
* itemsPerPage int if set, organizes the search list per page with the given number of items displayed per page.
* currentPage PointerThisPlease of an int if itemsPerPage is set, holds the page number for the search items to be displayed.
* customPaginationDisplay Widget Function(Widget listWidget, int totalFilteredItemsNb, Function updateSearchPage) if itemsPerPage is set, customizes the display and the handling of the pagination on the search list.
* futureSearchFn Function used to search items from the network. Must return items (up to itemsPerPage if set). Must return an int with the total number of results (allows the handling of pagination).
* futureSearchOrderOptions Map when futureSearchFn is set, can be used to display search order options specified in the form {"order1Name":{"icon":order1IconWidget,"asc":true},}. Please refer to the documentation example: https://github.com/lcuis/search_choices/blob/master/example/lib/main.dart.
* futureSearchFilterOptions Map when futureSearchFn is set, can be used to display search filters specified in the form {"filter1Name":{"icon":filter1IconWidget,"values":["value1",{"value2":filter1Value2Widget}}}. Please refer to the documentation example: https://github.com/lcuis/search_choices/blob/master/example/lib/main.dart.
* emptyListWidget String|Widget|Function with parameter: keyword returning String|Widget displayed instead of the list of items in case it is empty.
* onTap Function called when the user clicks on the Widget before it opens the dialog or the menu. Note that this is not called in case the Widget is disabled.
* futureSearchRetryButton Function called to customize the Error - retry button displayed when there is an issue with the future search.
* searchDelay int in milliseconds applied before the search is initiated. This applies to future and non-future searches.
* fieldPresentationFn Function returning a Widget to customize the display of the field.
* fieldDecoration Decoration is the decoration of the SearchChoices Widget while displaying the hints or the selected values. Should differ when selection is not valid.
* clearSearchIcon Widget sets the icon to be used to clear the search.
* showDialogFn Function allows the control of the dialog display.
* onSaved as in FormField.
* autovalidateMode as in FormField.
* restorationId as in FormField.
* giveMeThePop Function to pass the pop function so that the menu or dialog can be closed from outside the widget.
* buildFutureFilterOrOrderButton Function to customize the order and filter button in case of future search. Where:
** filter is true if building filter button and false while building order button.
** nbFilters is set to the number of filters applied if any.
** orderAsc true when the applied order is ascending.
** orderBy is the string by which the search is sorted.
* searchResultDisplayFn to customize the display of the search result items within the dialog or menu.


#### Multiple choice constructor

Search choices Widget with a multiple choice that opens a dialog or a menu to let the user do the selection conveniently with a search.

```dart
  factory SearchChoices.multiple({
    Key? key,
    required List<DropdownMenuItem<T>> items,
    Function? onChanged,
    List<int> selectedItems = const [],
    TextStyle? style,
    dynamic searchHint,
    dynamic hint,
    dynamic disabledHint,
    dynamic icon = const Icon(Icons.arrow_drop_down),
    dynamic underline,
    dynamic doneButton = "Done",
    dynamic label,
    dynamic closeButton = "Close",
    bool displayClearIcon = true,
    Icon clearIcon = const Icon(Icons.clear),
    Color? iconEnabledColor,
    Color? iconDisabledColor,
    double iconSize = 24.0,
    bool isExpanded = false,
    bool isCaseSensitiveSearch = false,
    Function? searchFn,
    Function? onClear,
    Function? selectedValueWidgetFn,
    TextInputType keyboardType = TextInputType.text,
    Function? validator,
    Function? displayItem,
    bool dialogBox = true,
    BoxConstraints? menuConstraints,
    bool readOnly = false,
    Color? menuBackgroundColor,
    bool? rightToLeft,
    bool autofocus = true,
    Function? selectedAggregateWidgetFn,
    dynamic padding = 10.0,
    Function? setOpenDialog,
    Widget Function  (Widget titleBar,Widget searchBar, Widget list, Widget closeButton, BuildContext dropDownContext,)? buildDropDownDialog,
    EdgeInsets? dropDownDialogPadding,
    InputDecoration searchInputDecoration = const InputDecoration(
      prefixIcon: Icon(
        Icons.search,
        size: 24,
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 12),
    ),
    int? itemsPerPage,
    PointerThisPlease<int>? currentPage,
    Widget Function(Widget listWidget, int totalFilteredItemsNb,
            Function updateSearchPage)?
        customPaginationDisplay,
    Future<Tuple2<List<DropdownMenuItem>, int>> Function(
            String? keyword,
            String? orderBy,
            bool? orderAsc,
            List<Tuple2<String, String>>? filters,
            int? pageNb)?
        futureSearchFn,
    Map<String, Map<String, dynamic>>? futureSearchOrderOptions,
    Map<String, Map<String, Object>>? futureSearchFilterOptions,
    List<T>? futureSelectedValues,
    dynamic emptyListWidget,
    Function? onTap,
    Function? futureSearchRetryButton,
    int? searchDelay,
    Widget Function(Widget fieldWidget,{bool selectionIsValid})? fieldPresentationFn,
    Decoration? fieldDecoration,
    Widget? clearSearchIcon,
    Future<void> Function(
      BuildContext context,
      Widget Function({
        String searchTerms,
      })
          menuWidget,
      String searchTerms,
    )?
        showDialogFn,
    FormFieldSetter<T>? onSaved,
    String? Function(List<dynamic>)? listValidator,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
    String? restorationId,
    Function(Function pop)? giveMeThePop,
    Widget Function({
      required bool filter,
      required BuildContext context,
      required Function onPressed,
      int? nbFilters,
      bool? orderAsc,
      String? orderBy,
    })?
        buildFutureFilterOrOrderButton,
    Widget Function({
        required List<Tuple3<int, DropdownMenuItem, bool>> itemsToDisplay,
        required ScrollController scrollController,
        required bool thumbVisibility,
        required Widget emptyListWidget,
        required void Function(int index, T value, bool itemSelected) itemTapped,
        required Widget Function(DropdownMenuItem item, bool isItemSelected)
        displayItem,
    })?
      searchResultDisplayFn,
  })
```

* items with child: Widget displayed ; value: any object with .toString() used to match search keyword.
* onChanged Function with parameter: selectedItems not returning executed after the selection is done.
* selectedItems indexes of items to be preselected.
* style used for the hint if it is given is String.
* searchHint String|Widget|Function with no parameter returning String|Widget displayed at the top of the search dialog box.
* hint String|Widget|Function with no parameter returning String|Widget displayed before any value is selected or after the selection is cleared.
* disabledHint String|Widget|Function with no parameter returning String|Widget displayed instead of hint when the widget is displayed.
* icon String|Widget|Function with parameter: selectedItems returning String|Widget displayed next to the selected items or the hint if none.
* underline String|Widget|Function with parameter: selectedItems returning String|Widget displayed below the selected items or the hint if none.
* doneButton String|Widget|Function with parameter: selectedItems returning String|Widget displayed at the top of the search dialog box. Cannot be null in multiple selection mode.
* label String|Widget|Function with parameter: selectedItems returning String|Widget displayed above the selected items or the hint if none.
* closeButton String|Widget|Function with parameter: selectedItems returning String|Widget displayed at the bottom of the search dialog box.
* displayClearIcon whether or not to display an icon to clear the selected values.
* clearIcon Icon to be used for clearing the selected values.
* iconEnabledColor Color to be used for enabled icons.
* iconDisabledColor Color to be used for disabled icons.
* iconSize for the icons next to the selected values (icon and clearIcon).
* isExpanded can be necessary to avoid pixel overflows (zebra symptom).
* isCaseSensitiveSearch only used when searchFn is not specified.
* searchFn Function with parameters: keyword, items returning List<int> as the list of indexes for the items to be displayed.
* onClear Function with no parameter not returning executed when the clear icon is tapped.
* selectedValueWidgetFn Function with parameter: item returning Widget to be used to display the selected values.
* keyboardType used for the search.
* validator Function with parameter: selectedItems returning String displayed below selected values when not valid and null when valid.
* displayItem Function with parameters: item, selected returning Widget to be displayed in the search list.
* dialogBox whether the search should be displayed as a dialog box or as a menu below the selected values if any.
* menuConstraints BoxConstraints used to define the zone where to display the search menu. Example: BoxConstraints.tight(Size.fromHeight(250)) . Not to be used for dialogBox = true.
* readOnly bool whether to let the user choose the value to select or just present the selected value if any.
* menuBackgroundColor Color background color of the menu whether in dialog box or menu mode.
* rightToLeft bool mirrors the widgets display for right to left languages defaulted to app.
* autofocus bool automatically focuses on the search field bringing up the keyboard defaulted to true.
* selectedAggregateWidgetFn Function with parameter: list of widgets presenting selected values, returning Widget to be displayed to present the selected items.
* padding double or EdgeInsets sets the padding around the DropdownButton, defaulted to 10.0.
* setOpenDialog Function sets the function to call to set the function to call in order to open the dialog with the search terms string as a parameter, defaulted to null.
* buildDropDownDialog Function controls the layout of the dropdown dialog.
* dropDownDialogPadding EdgeInsets sets the padding between the screen and the dialog.
* searchInputDecoration InputDecoration sets the search bar decoration.
* itemsPerPage int if set, organizes the search list per page with the given number of items displayed per page.
* currentPage PointerThisPlease<int> if itemsPerPage is set, holds the page number for the search items to be displayed.
* customPaginationDisplay Widget Function(Widget listWidget, int totalFilteredItemsNb, Function updateSearchPage) if itemsPerPage is set, customizes the display and the handling of the pagination on the search list.
* futureSearchFn Future<int> Function(String keyword, List<DropdownMenuItem> itemsListToClearAndFill, int pageNb) used to search items from the network. Must return items (up to itemsPerPage if set). Must return an int with the total number of results (allows the handling of pagination).
* futureSearchOrderOptions Map<String, Map<String,dynamic>> when futureSearchFn is set, can be used to display search order options specified in the form {"order1Name":{"icon":order1IconWidget,"asc":true},}. Please refer to the documentation example: https://github.com/lcuis/search_choices/blob/master/example/lib/main.dart.
* futureSearchFilterOptions Map<String, Map<String, Object>> when futureSearchFn is set, can be used to display search filters specified in the form {"filter1Name":{"icon":filter1IconWidget,"values":["value1",{"value2":filter1Value2Widget}}}. Please refer to the documentation example: https://github.com/lcuis/search_choices/blob/master/example/lib/main.dart.
* futureSelectedValues List contains the list of selected values in case of future search in multiple selection mode.
* emptyListWidget String|Widget|Function with parameter: keyword returning String|Widget displayed instead of the list of items in case it is empty.
* onTap Function called when the user clicks on the Widget before it opens the dialog or the menu. Note that this is not called in case the Widget is disabled.
* futureSearchRetryButton Function called to customize the Error - retry button displayed when there is an issue with the future search.
* searchDelay int in milliseconds applied before the search is initiated. This applies to future and non-future searches.
* fieldPresentationFn Function returning a Widget to customize the display of the field.
* fieldDecoration Decoration is the decoration of the SearchChoices Widget while displaying the hints or the selected values. Should differ when selection is not valid.
* clearSearchIcon Widget sets the icon to be used to clear the search.
* showDialogFn Function allows the control of the dialog display.
* onSaved as in FormField.
* listValidator Function with parameter: List returning String displayed below selected value when not valid and null when valid.
* autovalidateMode as in FormField.
* restorationId as in FormField.
* giveMeThePop Function to pass the pop function so that the menu or dialog can be closed from outside the widget.
* buildFutureFilterOrOrderButton Function to customize the order and filter button in case of future search. Where:
** filter is true if building filter button and false while building order button.
** nbFilters is set to the number of filters applied if any.
** orderAsc true when the applied order is ascending.
** orderBy is the string by which the search is sorted.
* searchResultDisplayFn to customize the display of the search result items within the dialog or menu.

#### Example app usage

Clone repository:
```
git clone https://github.com/lcuis/search_choices.git
```

Go to plugin folder:
```
cd search_choices
```

Optionally enable web:
```
flutter config --enable-web
```

Create project:
```
flutter create .
```

To run automated tests:
```
flutter test
```

Optionally generate documentation:
```
pub global activate dartdoc
dartdoc
```

Go to example app folder:
```
cd example
```

To run web:
```
run -d chrome
```

To build web to folder `build/web`:
```
flutter build web
```

To run on a connected device:
```
flutter run
```

To build Android app to `build/app/outputs/apk/release/app-release.apk`:
```
flutter build apk
```

To build iOS app on Mac:
```
flutter build ios
```

#### Single dialog
```dart
SearchChoices.single(
        items: items,
        value: selectedValueSingleDialog,
        hint: "Select one",
        searchHint: "Select one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialog = value;
          });
        },
        isExpanded: true,
      )
```
#### Multi dialog
```dart
SearchChoices.multiple(
        items: items,
        selectedItems: selectedItemsMultiDialog,
        hint: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text("Select any"),
        ),
        searchHint: "Select any",
        onChanged: (value) {
          setState(() {
            selectedItemsMultiDialog = value;
          });
        },
        closeButton: (selectedItems) {
          return (selectedItems.isNotEmpty
              ? "Save ${selectedItems.length == 1 ? '"' + items[selectedItems.first].value.toString() + '"' : '(' + selectedItems.length.toString() + ')'}"
              : "Save without selection");
        },
        isExpanded: true,
      )
```

#### Single done button dialog
```dart
SearchChoices.single(
        items: items,
        value: selectedValueSingleDoneButtonDialog,
        hint: "Select one",
        searchHint: "Select one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDoneButtonDialog = value;
          });
        },
        doneButton: "Done",
        displayItem: (item, selected) {
          return (Row(children: [
            selected
                ? Icon(
                    Icons.radio_button_checked,
                    color: Colors.grey,
                  )
                : Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey,
                  ),
            SizedBox(width: 7),
            Expanded(
              child: item,
            ),
          ]));
        },
        isExpanded: true,
      )
```
#### Multi custom display dialog
```dart
SearchChoices.multiple(
        items: items,
        selectedItems: selectedItemsMultiCustomDisplayDialog,
        hint: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text("Select any"),
        ),
        searchHint: "Select any",
        onChanged: (value) {
          setState(() {
            selectedItemsMultiCustomDisplayDialog = value;
          });
        },
        displayItem: (item, selected) {
          return (Row(children: [
            selected
                ? Icon(
                    Icons.check,
                    color: Colors.green,
                  )
                : Icon(
                    Icons.check_box_outline_blank,
                    color: Colors.grey,
                  ),
            SizedBox(width: 7),
            Expanded(
              child: item,
            ),
          ]));
        },
        selectedValueWidgetFn: (item) {
          return (Center(
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Colors.brown,
                      width: 0.5,
                    ),
                  ),
                  margin: EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(item.toString()),
                  ))));
        },
        doneButton: (selectedItemsDone, doneContext) {
          return (ElevatedButton(
              onPressed: () {
                Navigator.pop(doneContext);
                setState(() {});
              },
              child: Text("Save")));
        },
        closeButton: null,
        style: TextStyle(fontStyle: FontStyle.italic),
        searchFn: (String keyword, items) {
          List<int> ret = [];
          if (items != null && keyword.isNotEmpty) {
            keyword.split(" ").forEach((k) {
              int i = 0;
              items.forEach((item) {
                if (k.isNotEmpty &&
                    (item.value
                        .toString()
                        .toLowerCase()
                        .contains(k.toLowerCase()))) {
                  ret.add(i);
                }
                i++;
              });
            });
          }
          if (keyword.isEmpty) {
            ret = Iterable<int>.generate(items.length).toList();
          }
          return (ret);
        },
        clearIcon: Icon(Icons.clear_all),
        icon: Icon(Icons.arrow_drop_down_circle),
        label: "Label for multi",
        underline: Container(
          height: 1.0,
          decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.teal, width: 3.0))),
        ),
        iconDisabledColor: Colors.brown,
        iconEnabledColor: Colors.indigo,
        dropDownDialogPadding: EdgeInsets.symmetric(
          vertical: 80,
          horizontal: 80,
        ),
        isExpanded: true,
      )
```

#### Multi select 3 dialog
```dart
SearchChoices.multiple(
        items: items,
        selectedItems: selectedItemsMultiSelect3Dialog,
        hint: "Select 3 items",
        searchHint: "Select 3",
        validator: (selectedItemsForValidator) {
          if (selectedItemsForValidator.length != 3) {
            return ("Must select 3");
          }
          return (null);
        },
        onChanged: (value) {
          setState(() {
            selectedItemsMultiSelect3Dialog = value;
          });
        },
        doneButton: (selectedItemsDone, doneContext) {
          return (ElevatedButton(
              onPressed: selectedItemsDone.length != 3
                  ? null
                  : () {
                      Navigator.pop(doneContext);
                      setState(() {});
                    },
              child: Text("Save")));
        },
        closeButton: (selectedItemsClose) {
          return (selectedItemsClose.length == 3 ? "Ok" : null);
        },
        isExpanded: true,
      )
```

#### Single menu
```dart
SearchChoices.single(
        items: items,
        value: selectedValueSingleMenu,
        hint: "Select one",
        searchHint: null,
        onChanged: (value) {
          setState(() {
            selectedValueSingleMenu = value;
          });
        },
        dialogBox: false,
        isExpanded: true,
        menuConstraints: BoxConstraints.tight(Size.fromHeight(350)),
      )
```

#### Multi menu
```dart
SearchChoices.multiple(
        items: items,
        selectedItems: selectedItemsMultiMenu,
        hint: "Select any",
        searchHint: "",
        doneButton: "Close",
        closeButton: SizedBox.shrink(),
        onChanged: (value) {
          setState(() {
            selectedItemsMultiMenu = value;
          });
        },
        dialogBox: false,
        isExpanded: true,
        menuConstraints: BoxConstraints.tight(Size.fromHeight(350)),
      )
```

#### Multi menu select all/none
```dart
SearchChoices.multiple(
        items: items,
        selectedItems: selectedItemsMultiMenuSelectAllNone,
        hint: "Select any",
        searchHint: "Select any",
        onChanged: (value) {
          setState(() {
            selectedItemsMultiMenuSelectAllNone = value;
          });
        },
        dialogBox: false,
        closeButton: (selectedItemsClose, closeContext, Function updateParent) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedItemsClose.clear();
                      selectedItemsClose.addAll(
                          Iterable<int>.generate(items.length).toList());
                    });
                    updateParent(selectedItemsClose);
                  },
                  child: Text("Select all")),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedItemsClose.clear();
                    });
                    updateParent(selectedItemsClose);
                  },
                  child: Text("Select none")),
            ],
          );
        },
        isExpanded: true,
        menuConstraints: BoxConstraints.tight(Size.fromHeight(350)),
      )
```

#### Multi dialog select all/none without clear
```dart
SearchChoices.multiple(
        items: items,
        selectedItems: selectedItemsMultiDialogSelectAllNoneWoClear,
        hint: "Select any",
        searchHint: "Select any",
        displayClearIcon: false,
        onChanged: (value) {
          setState(() {
            selectedItemsMultiDialogSelectAllNoneWoClear = value;
          });
        },
        dialogBox: true,
        closeButton: (selectedItemsClose, closeContext, Function updateParent) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedItemsClose.clear();
                      selectedItemsClose.addAll(
                          Iterable<int>.generate(items.length).toList());
                    });
                    updateParent(selectedItemsClose);
                  },
                  child: Text("Select all")),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedItemsClose.clear();
                    });
                    updateParent(selectedItemsClose);
                  },
                  child: Text("Select none")),
            ],
          );
        },
        isExpanded: true,
      )
```

#### Single dialog custom keyboard
```dart
SearchChoices.single(
        items: Iterable<int>.generate(20).toList().map((i) {
          return (DropdownMenuItem(
            child: Text(i.toString()),
            value: i.toString(),
          ));
        }).toList(),
        value: selectedValueSingleDialogCustomKeyboard,
        hint: "Select one number",
        searchHint: "Select one number",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialogCustomKeyboard = value;
          });
        },
        dialogBox: true,
        keyboardType: TextInputType.number,
        isExpanded: true,
      )
```

#### Single dialog object
```dart
SearchChoices.single(
        items: numberItems,
        value: selectedNumber,
        hint: "Select one number",
        searchHint: "Select one number",
        onChanged: (value) {
          setState(() {
            selectedNumber = value;
          });
        },
        dialogBox: true,
        isExpanded: true,
      )
```
#### Single dialog overflow
```dart
SearchChoices.single(
        items: [
          DropdownMenuItem(
            child: Text(
                "way too long text for a smartphone at least one that goes in a normal sized pair of trousers but maybe not for a gigantic screen like there is one at my cousin's home in a very remote country where I wouldn't want to go right now"),
            value:
                "way too long text for a smartphone at least one that goes in a normal sized pair of trousers but maybe not for a gigantic screen like there is one at my cousin's home in a very remote country where I wouldn't want to go right now",
          )
        ],
        value: selectedValueSingleDialogOverflow,
        hint: "Select one",
        searchHint: "Select one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialogOverflow = value;
          });
        },
        dialogBox: true,
        isExpanded: true,
      )
```
#### Single dialog readOnly
```dart
SearchChoices.single(
        items: [
          DropdownMenuItem(
            child: Text("one item"),
            value: "one item",
          )
        ],
        value: "one item",
        hint: "Select one",
        searchHint: "Select one",
        disabledHint: "Disabled",
        onChanged: (value) {
          setState(() {});
        },
        dialogBox: true,
        isExpanded: true,
        readOnly: true,
      )
```
#### Single dialog disabled
```dart
SearchChoices.single(
        items: [
          DropdownMenuItem(
            child: Text("one item"),
            value: "one item",
          )
        ],
        value: "one item",
        hint: "Select one",
        searchHint: "Select one",
        disabledHint: "Disabled",
        onChanged: null,
        dialogBox: true,
        isExpanded: true,
      )
```
#### Single dialog editable items
This example lets the user add and remove items to and from the list of choices within a dialog. One can limit the number of items that can be added (100 here).
```dart
    input = TextFormField(
      validator: (value) {
        return ((value?.length ?? 0) < 6
            ? "must be at least 6 characters long"
            : null);
      },
      initialValue: inputString,
      onChanged: (value) {
        inputString = value;
      },
      autofocus: true,
    );
...
  addItemDialog() async {
    return await showDialog(
      context: MyApp.navKey.currentState?.overlay?.context ?? context,
      builder: (BuildContext alertContext) {
        return (AlertDialog(
          title: Text("Add an item"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                input ?? SizedBox.shrink(),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {
                        editableItems.add(DropdownMenuItem(
                          child: Text(inputString),
                          value: inputString,
                        ));
                      });
                      Navigator.pop(alertContext, inputString);
                    }
                  },
                  child: Text("Ok"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(alertContext, null);
                  },
                  child: Text("Cancel"),
                ),
              ],
            ),
          ),
        ));
      },
    );
  }
...
SearchChoices.single(
        items: editableItems,
        value: selectedValueSingleDialogEditableItems,
        hint: "Select one",
        searchHint: "Select one",
        disabledHint: (Function updateParent) {
          return (TextButton(
            onPressed: () {
              addItemDialog().then((value) async {
                updateParent(value);
              });
            },
            child: Text("No choice, click to add one"),
          ));
        },
        closeButton:
            (String? value, BuildContext closeContext, Function updateParent) {
          return (editableItems.length >= 100
              ? "Close"
              : TextButton(
                  onPressed: () {
                    addItemDialog().then((value) async {
                      if (value != null &&
                          editableItems.indexWhere(
                                  (element) => element.value == value) !=
                              -1) {
                        Navigator.pop(
                            MyApp.navKey.currentState?.overlay?.context ??
                                context);
                        updateParent(value);
                      }
                    });
                  },
                  child: Text("Add and select item"),
                ));
        },
        onChanged: (String? value) {
          setState(() {
            if (!(value is NotGiven)) {
              selectedValueSingleDialogEditableItems = value;
            }
          });
        },
        displayItem: (item, selected, Function updateParent) {
          return (Row(children: [
            selected
                ? Icon(
                    Icons.check,
                    color: Colors.green,
                  )
                : Icon(
                    Icons.check_box_outline_blank,
                    color: Colors.transparent,
                  ),
            SizedBox(width: 7),
            Expanded(
              child: item,
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                editableItems.removeWhere((element) => item == element);
                updateParent(null);
                setState(() {});
              },
            ),
          ]));
        },
        dialogBox: true,
        isExpanded: true,
        doneButton: "Done",
      )
```
#### Single menu editable items
This example lets the user add and remove items to and from the list of choices within a menu. One can limit the number of items that can be added (100 here).
```dart
SearchChoices.single(
        items: editableItems,
        value: selectedValueSingleMenuEditableItems,
        hint: "Select one",
        searchHint: "Select one",
        disabledHint: (Function updateParent) {
          return (TextButton(
            onPressed: () {
              addItemDialog().then((value) async {
                updateParent(value);
              });
            },
            child: Text("No choice, click to add one"),
          ));
        },
        closeButton:
            (String? value, BuildContext closeContext, Function updateParent) {
          return (editableItems.length >= 100
              ? "Close"
              : TextButton(
                  onPressed: () {
                    addItemDialog().then((value) async {
                      if (value != null &&
                          editableItems.indexWhere(
                                  (element) => element.value == value) !=
                              -1) {
                        updateParent(value, true);
                      }
                    });
                  },
                  child: Text("Add and select item"),
                ));
        },
        onChanged: (String? value, Function? pop) {
          setState(() {
            if (!(value is NotGiven)) {
              selectedValueSingleMenuEditableItems = value;
            }
          });
          if (pop != null && !(value is NotGiven) && value != null) {
            pop();
          }
        },
        displayItem: (DropdownMenuItem item, selected, Function updateParent) {
          bool deleteRequested = false;
          return ListTile(
            leading: selected
                ? Icon(
                    Icons.check,
                    color: Colors.green,
                  )
                : Icon(
                    Icons.check_box_outline_blank,
                    color: Colors.transparent,
                  ),
            title: item,
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                deleteRequested = true;
                editableItems.removeWhere((element) => item == element);
                updateParent(selected ? null : NotGiven(), false);
                setState(() {});
              },
            ),
            onTap: () {
              if (!deleteRequested) {
                updateParent(item.value, true);
              }
            },
            horizontalTitleGap: 0,
          );
        },
        dialogBox: false,
        isExpanded: true,
        doneButton: "Done",
        menuConstraints: BoxConstraints.tight(Size.fromHeight(350)),
      )
```
#### Multi dialog editable items
Same example as previously but with multiple selection.
```dart
    input = TextFormField(
      validator: (value) {
        return ((value?.length ?? 0) < 6
            ? "must be at least 6 characters long"
            : null);
      },
      initialValue: inputString,
      onChanged: (value) {
        inputString = value;
      },
      autofocus: true,
    );
    super.initState();
  }
...
  addItemDialog() async {
    return await showDialog(
      context: MyApp.navKey.currentState?.overlay?.context ?? context,
      builder: (BuildContext alertContext) {
        return (AlertDialog(
          title: Text("Add an item"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                input ?? SizedBox.shrink(),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {
                        editableItems.add(DropdownMenuItem(
                          child: Text(inputString),
                          value: inputString,
                        ));
                      });
                      Navigator.pop(alertContext, inputString);
                    }
                  },
                  child: Text("Ok"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(alertContext, null);
                  },
                  child: Text("Cancel"),
                ),
              ],
            ),
          ),
        ));
      },
    );
  }
...
SearchChoices.multiple(
        items: editableItems,
        selectedItems: editableSelectedItems,
        hint: "Select any",
        searchHint: "Select any",
        disabledHint: (Function updateParent) {
          return (TextButton(
            onPressed: () {
              addItemDialog().then((value) async {
                if (value != null) {
                  editableSelectedItems = [0];
                  updateParent(editableSelectedItems);
                }
              });
            },
            child: Text("No choice, click to add one"),
          ));
        },
        closeButton: (List<int> values, BuildContext closeContext,
            Function updateParent) {
          return (editableItems.length >= 100
              ? "Close"
              : TextButton(
                  onPressed: () {
                    addItemDialog().then((value) async {
                      if (value != null) {
                        int itemIndex = editableItems
                            .indexWhere((element) => element.value == value);
                        if (itemIndex != -1) {
                          editableSelectedItems.add(itemIndex);
                          Navigator.pop(
                              MyApp.navKey.currentState?.overlay?.context ??
                                  context);
                          updateParent(editableSelectedItems);
                        }
                      }
                    });
                  },
                  child: Text("Add and select item"),
                ));
        },
        onChanged: (values) {
          setState(() {
            if (!(values is NotGiven)) {
              editableSelectedItems = values;
            }
          });
        },
        displayItem: (item, selected, Function updateParent) {
          return (Row(children: [
            selected
                ? Icon(
                    Icons.check_box,
                    color: Colors.black,
                  )
                : Icon(
                    Icons.check_box_outline_blank,
                    color: Colors.black,
                  ),
            SizedBox(width: 7),
            Expanded(
              child: item,
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                int indexOfItem = editableItems.indexOf(item);
                editableItems.removeWhere((element) => item == element);
                editableSelectedItems
                    .removeWhere((element) => element == indexOfItem);
                for (int i = 0; i < editableSelectedItems.length; i++) {
                  if (editableSelectedItems[i] > indexOfItem) {
                    editableSelectedItems[i]--;
                  }
                }
                updateParent(editableSelectedItems);
                setState(() {});
              },
            ),
          ]));
        },
        dialogBox: true,
        isExpanded: true,
        doneButton: "Done",
      )
```
### Single dialog dark mode
```dart
Card(
        color: Colors.black,
        child: SearchChoices.single(
          items: items.map((item) {
            return (DropdownMenuItem(
              child: Text(
                item.value,
                style: TextStyle(color: Colors.white),
              ),
              value: item.value,
            ));
          }).toList(),
          value: selectedValueSingleDialogDarkMode,
          hint: Text(
            "Select one",
            style: TextStyle(color: Colors.white),
          ),
          searchHint: Text(
            "Select one",
            style: TextStyle(color: Colors.white),
          ),
          style: TextStyle(color: Colors.white, backgroundColor: Colors.black),
          closeButton: TextButton(
            onPressed: () {
              Navigator.pop(
                  MyApp.navKey.currentState?.overlay?.context ?? context);
            },
            child: Text(
              "Close",
              style: TextStyle(color: Colors.white),
            ),
          ),
          menuBackgroundColor: Colors.black,
          iconEnabledColor: Colors.white,
          iconDisabledColor: Colors.grey,
          onChanged: (value) {
            setState(() {
              selectedValueSingleDialogDarkMode = value;
            });
          },
          isExpanded: true,
        ),
      )
```
### Single dialog ellipsis
```dart
SearchChoices.single(
        items: [
          DropdownMenuItem(
            child: Text(
              "way too long text for a smartphone at least one that goes in a normal sized pair of trousers but maybe not for a gigantic screen like there is one at my cousin's home in a very remote country where I wouldn't want to go right now",
              overflow: TextOverflow.ellipsis,
            ),
            value:
                "way too long text for a smartphone at least one that goes in a normal sized pair of trousers but maybe not for a gigantic screen like there is one at my cousin's home in a very remote country where I wouldn't want to go right now",
          )
        ],
        value: selectedValueSingleDialogEllipsis,
        hint: "Select one",
        searchHint: "Select one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialogEllipsis = value;
          });
        },
        selectedValueWidgetFn: (item) {
          return DropdownMenuItem(
            child: (Text(
              item,
              overflow: TextOverflow.ellipsis,
            )),
          );
        },
        dialogBox: true,
        isExpanded: true,
      )
```
### Single dialog right to left
In support for Arabic, Hebrew and other RTL languages.
```dart
SearchChoices.single(
        items: [
          "طنجة",
          "فاس‎",
          "أكادير‎",
          "تزنيت‎",
          "آكــلــو",
          "سيدي بيبي",
        ].map<DropdownMenuItem<String>>((string) {
          return (DropdownMenuItem<String>(
            child: Text(
              string,
              textDirection: TextDirection.rtl,
            ),
            value: string,
          ));
        }).toList(),
        value: selectedValueSingleDialogRightToLeft,
        hint: Row(
          textDirection: TextDirection.rtl,
          children: [
            Text(
              "ختار",
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        searchHint: Text(
          "ختار",
          textDirection: TextDirection.rtl,
        ),
        closeButton: TextButton(
          onPressed: () {
            Navigator.pop(
                MyApp.navKey.currentState?.overlay?.context ?? context);
          },
          child: SizedBox(
            width: 50,
            child: Text(
              "سدّ",
              maxLines: 1,
              softWrap: false,
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialogRightToLeft = value;
          });
        },
        isExpanded: true,
        rightToLeft: true,
        displayItem: (item, selected) {
          return (Row(textDirection: TextDirection.rtl, children: [
            selected
                ? Icon(
                    Icons.radio_button_checked,
                    color: Colors.grey,
                  )
                : Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey,
                  ),
            SizedBox(width: 7),
            item,
            Expanded(
              child: SizedBox.shrink(),
            ),
          ]));
        },
        selectedValueWidgetFn: (item) {
          return DropdownMenuItem(
            child: Row(
              textDirection: TextDirection.rtl,
              children: <Widget>[
                (Text(
                  item,
                  textDirection: TextDirection.rtl,
                )),
              ],
            ),
          );
        },
      )
```
### Update value from outside the plugin
A button external to the plugin can be used to set the selected value.
```dart
Column(
        children: [
          SearchChoices.single(
            items: items,
            value: selectedValueUpdateFromOutsideThePlugin,
            hint: Text('Select One'),
            searchHint: new Text(
              'Select One',
              style: new TextStyle(fontSize: 20),
            ),
            onChanged: (value) {
              setState(() {
                selectedValueUpdateFromOutsideThePlugin = value;
              });
            },
            isExpanded: true,
          ),
          TextButton(
            child: Text("Select dolor sit"),
            onPressed: () {
              setState(() {
                selectedValueUpdateFromOutsideThePlugin = "dolor sit";
              });
            },
          ),
        ],
      )
```
### Multi select 3 menu no-autofocus
Doesn't bring up the keyboard automatically.
```dart
SearchChoices.multiple(
        items: items,
        selectedItems: selectedItemsMultiSelect3Menu,
        hint: "Select 3 items",
        searchHint: "Select 3",
        validator: (selectedItemsForValidatorWithMenu) {
          if (selectedItemsForValidatorWithMenu.length != 3) {
            return ("Must select 3");
          }
          return (null);
        },
        onChanged: (value) {
          setState(() {
            selectedItemsMultiSelect3Menu = value;
          });
        },
        isExpanded: true,
        dialogBox: false,
        menuConstraints: BoxConstraints.tight(Size.fromHeight(350)),
        autofocus: false,
      )
```
### Multi dialog with count and wrap
Customization of the way the selection is displayed.
```dart
SearchChoices.multiple(
        items: items,
        selectedItems: selectedItemsMultiDialogWithCountAndWrap,
        hint: "Select items",
        searchHint: "Select items",
        onChanged: (value) {
          setState(() {
            selectedItemsMultiDialogWithCountAndWrap = value;
          });
        },
        isExpanded: true,
        selectedValueWidgetFn: (item) {
          return (Container(
            margin: const EdgeInsets.all(15.0),
            padding: const EdgeInsets.all(3.0),
            decoration:
                BoxDecoration(border: Border.all(color: Colors.blueAccent)),
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
            ),
          ));
        },
        selectedAggregateWidgetFn: (List<Widget> list) {
          return (Column(children: [
            Text("${list.length} items selected"),
            Wrap(children: list),
          ]));
        },
      )
```
### Single dialog open and set search terms
A button external to the plugin can be used to open the dialog and set the search terms.
```dart
SearchChoices.single(
        label: Column(
          children: items.map((item) {
            return (ElevatedButton(
              child: item.child,
              onPressed: () {
                openDialog!(item.value.toString());
              },
            ));
          }).toList(),
        ),
        items: items,
        value: selectedValueSingleDialog,
        hint: "Select one",
        searchHint: "Select one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialog = value;
          });
        },
        isExpanded: true,
        setOpenDialog: (externalOpenDialog) {
          openDialog = externalOpenDialog;
        },
      )
```
### Single dialog custom dialog
Customize the way the dialog is displayed to define how to show the title bar, the search bar, the list and the close button.
```dart
SearchChoices.single(
        items: items,
        value: selectedValueSingleDialog,
        hint: "Select one",
        searchHint: "Select one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialog = value;
          });
        },
        isExpanded: true,
        buildDropDownDialog: (
          Widget titleBar,
          Widget searchBar,
          Widget list,
          Widget closeButton,
          BuildContext dropDownContext,
        ) {
          return (AnimatedContainer(
            padding: MediaQuery.of(dropDownContext).viewInsets,
            duration: const Duration(milliseconds: 300),
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 30, horizontal: 40),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 35, horizontal: 45),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    titleBar,
                    searchBar,
                    list,
                    closeButton,
                  ],
                ),
              ),
            ),
          ));
        },
      )
```
### Single dialog custom decorations
Can customize the way the search bar and field are displayed.
```dart
        items: items,
        value: selectedValueSingleDialog,
        hint: Padding(
            padding: EdgeInsets.all(3),
            child: DropdownMenuItem(
              child: Text("Select one"),
            )),
        searchHint: "Select one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialog = value;
          });
        },
        isExpanded: true,
        searchInputDecoration: InputDecoration(
          icon: Icon(Icons.airline_seat_flat),
          border: OutlineInputBorder(),
        ),
        fieldDecoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Colors.blueGrey,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        selectedValueWidgetFn: (selectedValue) {
          return (Padding(
            padding: EdgeInsets.all(3),
            child: DropdownMenuItem(child: Text(selectedValue)),
          ));
        },
      )
```
### Single dialog paged
Useful when displaying a huge amount of items.
```dart
SearchChoices.single(
        items: items,
        value: selectedValueSingleDialogPaged,
        hint: "Select one",
        searchHint: "Search one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialogPaged = value;
          });
        },
        isExpanded: true,
        itemsPerPage: 5,
        currentPage: currentPage,
      )
```
### Multi dialog paged rtl
Pagination also works on multiple selection and with right to left languages such as Arabic and Hebrew. Useful when displaying a huge amount of items.
```dart
SearchChoices.multiple(
        items: [
          "طنجة",
          "فاس‎",
          "أكادير‎",
          "تزنيت‎",
          "آكــلــو",
          "سيدي بيبي",
        ].map<DropdownMenuItem<String>>((string) {
          return (DropdownMenuItem<String>(
            child: Text(
              string,
              textDirection: TextDirection.rtl,
            ),
            value: string,
          ));
        }).toList(),
        selectedItems: selectedItemsMultiDialogPaged,
        hint: Row(
          textDirection: TextDirection.rtl,
          children: [
            Text(
              "ختار",
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        searchHint: Text(
          "ختار",
          textDirection: TextDirection.rtl,
        ),
        closeButton: TextButton(
          onPressed: () {
            Navigator.pop(
                MyApp.navKey.currentState?.overlay?.context ?? context);
          },
          child: SizedBox(
            width: 50,
            child: Text(
              "سدّ",
              maxLines: 1,
              softWrap: false,
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {
            selectedItemsMultiDialogPaged = value;
          });
        },
        isExpanded: true,
        rightToLeft: true,
        displayItem: (item, selected) {
          return (Row(textDirection: TextDirection.rtl, children: [
            SizedBox(width: 7),
            selected
                ? Icon(
                    Icons.radio_button_checked,
                    color: Colors.grey,
                  )
                : Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey,
                  ),
            SizedBox(width: 7),
            item,
            Expanded(
              child: SizedBox.shrink(),
            ),
          ]));
        },
        selectedValueWidgetFn: (item) {
          return DropdownMenuItem(
            child: Row(
              textDirection: TextDirection.rtl,
              children: <Widget>[
                (Text(
                  item,
                  textDirection: TextDirection.rtl,
                )),
              ],
            ),
          );
        },
        itemsPerPage: 5,
        currentPage: currentPage,
        doneButton: "قريب",
      )
```
### Single dialog paged custom pagination
Custom pagination can let the user choose which page to display instead of having next and previous buttons. Useful when displaying a huge amount of items.
```dart
SearchChoices.single(
        items: items,
        value: selectedValueSingleDialogPaged,
        hint: "Select one",
        searchHint: "Search one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialogPaged = value;
          });
        },
        isExpanded: true,
        itemsPerPage: 5,
        currentPage: currentPage,
        customPaginationDisplay: (Widget listWidget, int totalFilteredItemsNb,
            Function updateSearchPage) {
          return (Expanded(
              child: Column(children: [
            listWidget,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Text("Page:"),
                SizedBox(
                  width: 10,
                ),
                Wrap(
                  spacing: 10,
                  children:
                      Iterable<int>.generate((totalFilteredItemsNb / 5).ceil())
                          .toList()
                          .map((i) {
                    return (SizedBox(
                      width: (31 + 9 * (i + 1).toString().length) + 0.0,
                      height: 30.0,
                      child: ElevatedButton(
                        child: Text("${i + 1}"),
                        onPressed: (i + 1) == currentPage.value
                            ? null
                            : () {
                                currentPage.value = i + 1;
                                updateSearchPage();
                              },
                      ),
                    ));
                  }).toList(),
                ),
              ]),
            ),
          ])));
        },
      )
```
### Single menu paged
Showing pagination in a single selection menu. Useful when displaying a huge amount of items.
```dart
SearchChoices.single(
        items: items,
        value: selectedValueSingleDialogPaged,
        hint: "Select one",
        searchHint: null,
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialogPaged = value;
          });
        },
        dialogBox: false,
        isExpanded: true,
        menuConstraints: BoxConstraints.tight(Size.fromHeight(350)),
        itemsPerPage: 5,
        currentPage: currentPage,
      )
```
### Single dialog paged future
Future/network/internet/web/API/webservice call displayed paged in a dialog. This example doesn't work on web because of the `get` function call, though, the plugin features should work on web. This example shows that this would work with PHP-CRUD-API.
```dart
SearchChoices.single(
        value: selectedValueSingleDialogPagedFuture,
        hint: kIsWeb ? "Example not for web" : "Select one capital",
        searchHint: "Search capitals",
        onChanged: kIsWeb
            ? null
            : (value) {
                setState(() {
                  selectedValueSingleDialogPagedFuture = value;
                });
              },
        isExpanded: true,
        itemsPerPage: 10,
        currentPage: currentPage,
        selectedValueWidgetFn: (item) {
          return (Center(
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.all(1),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(item["capital"]),
                  ))));
        },
        futureSearchFn: (String? keyword, String? orderBy, bool? orderAsc,
            List<Tuple2<String, String>>? filters, int? pageNb) async {
          String filtersString = "";
          int i = 1;
          filters?.forEach((element) {
            filtersString += "&filter" +
                i.toString() +
                "=" +
                element.item1 +
                "," +
                element.item2;
            i++;
          });
          Response response = await get(Uri.parse(
                  "https://searchchoices.jod.li/exampleList.php?page=${pageNb ?? 1},10${orderBy == null ? "" : "&order=" + orderBy + "," + (orderAsc ?? true ? "asc" : "desc")}${(keyword == null || keyword.isEmpty) ? "" : "&filter=capital,cs," + keyword}$filtersString"))
              .timeout(Duration(
            seconds: 10,
          ));
          if (response.statusCode != 200) {
            throw Exception("failed to get data from internet");
          }
          dynamic data = jsonDecode(response.body);
          int nbResults = data["results"];
          List<DropdownMenuItem> results = (data["records"] as List<dynamic>)
              .map<DropdownMenuItem>((item) => DropdownMenuItem(
                    value: item,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: Colors.blue,
                          width: 1,
                        ),
                      ),
                      margin: EdgeInsets.all(1),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                            "${item["capital"]} - ${item["country"]} - ${item["continent"]} - pop.: ${item["population"]}"),
                      ),
                    ),
                  ))
              .toList();
          return (Tuple2<List<DropdownMenuItem>, int>(results, nbResults));
        },
        futureSearchOrderOptions: {
          "country": {
            "icon": Wrap(children: [
              Icon(Icons.flag),
              Text(
                "Country",
              )
            ]),
            "asc": true
          },
          "capital": {
            "icon":
                Wrap(children: [Icon(Icons.location_city), Text("Capital")]),
            "asc": true
          },
          "continent": {"icon": "Continent", "asc": true},
          "population": {
            "icon": Wrap(children: [Icon(Icons.people), Text("Population")]),
            "asc": false
          },
        },
        futureSearchFilterOptions: {
          "continent": {
            "icon": Text("Continent"),
            "exclusive": true,
            "values": [
              {"eq,Africa": "Africa"},
              {"eq,Americas": "Americas"},
              {"eq,Asia": "Asia"},
              {"eq,Australia": "Australia"},
              {"eq,Europe": "Europe"},
              {"eq,Oceania": "Oceania"}
            ]
          },
          "population": {
            "icon": Wrap(children: [Icon(Icons.people), Text("Population")]),
            "exclusive": true,
            "values": [
              {
                "lt,1000": Wrap(children: [Icon(Icons.person), Text("<1,000")])
              },
              {
                "lt,100000":
                    Wrap(children: [Icon(Icons.person_add), Text("<100,000")])
              },
              {
                "lt,1000000": Wrap(
                    children: [Icon(Icons.nature_people), Text("<1,000,000")])
              },
              {
                "gt,1000000":
                    Wrap(children: [Icon(Icons.people), Text(">1,000,000")])
              },
              {
                "gt,10000000": Wrap(
                    children: [Icon(Icons.location_city), Text(">10,000,000")])
              },
            ]
          },
        },
        closeButton: (selectedItemsDone, doneContext) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 25,
                width: 48,
                child: (ElevatedButton(
                    onPressed: () {
                      Navigator.pop(doneContext);
                      setState(() {});
                    },
                    child: Icon(
                      Icons.close,
                      size: 17,
                    ))),
              ),
            ],
          );
        },
      )
```
### Multi menu paged future
Future/network/internet/web/API/webservice call displayed paged in a menu. This example doesn't work on web because of the `get` function call, though, the plugin features should work on web. This example shows that this would work with PHP-CRUD-API.
```dart
SearchChoices.multiple(
        futureSelectedValues: selectedItemsMultiMenuPagedFuture,
        hint: kIsWeb ? "Example not for web" : "Select capitals",
        searchHint: "",
        dialogBox: false,
        onChanged: kIsWeb
            ? null
            : (value) {
                setState(() {
                  selectedItemsMultiMenuPagedFuture = value;
                });
              },
        isExpanded: true,
        itemsPerPage: 10,
        currentPage: currentPage,
        selectedValueWidgetFn: (item) {
          return (Center(
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.all(1),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(item["capital"]),
                  ))));
        },
        futureSearchFn: (String? keyword, String? orderBy, bool? orderAsc,
            List<Tuple2<String, String>>? filters, int? pageNb) async {
          String filtersString = "";
          int i = 1;
          filters?.forEach((element) {
            filtersString += "&filter" +
                i.toString() +
                "=" +
                element.item1 +
                "," +
                element.item2;
            i++;
          });
          Response response = await get(Uri.parse(
                  "https://searchchoices.jod.li/exampleList.php?page=${pageNb ?? 1},10${orderBy == null ? "" : "&order=" + orderBy + "," + (orderAsc ?? true ? "asc" : "desc")}${(keyword == null || keyword.isEmpty) ? "" : "&filter=capital,cs," + keyword}$filtersString"))
              .timeout(Duration(
            seconds: 10,
          ));
          if (response.statusCode != 200) {
            throw Exception("failed to get data from internet");
          }
          dynamic data = jsonDecode(response.body);
          int nbResults = data["results"];
          List<DropdownMenuItem> results = (data["records"] as List<dynamic>)
              .map<DropdownMenuItem>((item) => DropdownMenuItem(
                    value: item,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: Colors.blue,
                          width: 1,
                        ),
                      ),
                      margin: EdgeInsets.all(1),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                            "${item["capital"]} - ${item["country"]} - ${item["continent"]} - pop.: ${item["population"]}"),
                      ),
                    ),
                  ))
              .toList();
          return (Tuple2<List<DropdownMenuItem>, int>(results, nbResults));
        },
        futureSearchOrderOptions: {
          "country": {
            "icon": Wrap(children: [
              Icon(Icons.flag),
              Text(
                "Country",
              )
            ]),
            "asc": true
          },
          "capital": {
            "icon":
                Wrap(children: [Icon(Icons.location_city), Text("Capital")]),
            "asc": true
          },
          "continent": {"icon": "Continent", "asc": true},
          "population": {
            "icon": Wrap(children: [Icon(Icons.people), Text("Population")]),
            "asc": false
          },
        },
        futureSearchFilterOptions: {
          "continent": {
            "icon": Text("Continent"),
            "exclusive": true,
            "values": [
              {"eq,Africa": "Africa"},
              {"eq,Americas": "Americas"},
              {"eq,Asia": "Asia"},
              {"eq,Australia": "Australia"},
              {"eq,Europe": "Europe"},
              {"eq,Oceania": "Oceania"}
            ]
          },
          "population": {
            "icon": Wrap(children: [Icon(Icons.people), Text("Population")]),
            "exclusive": true,
            "values": [
              {
                "lt,1000": Wrap(children: [Icon(Icons.person), Text("<1,000")])
              },
              {
                "lt,100000":
                    Wrap(children: [Icon(Icons.person_add), Text("<100,000")])
              },
              {
                "lt,1000000": Wrap(
                    children: [Icon(Icons.nature_people), Text("<1,000,000")])
              },
              {
                "gt,1000000":
                    Wrap(children: [Icon(Icons.people), Text(">1,000,000")])
              },
              {
                "gt,10000000": Wrap(
                    children: [Icon(Icons.location_city), Text(">10,000,000")])
              },
            ]
          },
        },
        menuConstraints: BoxConstraints.tight(Size.fromHeight(350)),
      )
```
### Single dialog custom empty list
When the list gets empty after the keyword is typed, the dialog displays the given text with the keyword as a parameter.
```dart
SearchChoices.single(
        items: items,
        value: selectedValueSingleDialog,
        hint: "Select one",
        searchHint: "Select one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialog = value;
          });
        },
        isExpanded: true,
        emptyListWidget: (String keyword) =>
            "No result with the \"$keyword\" keyword",
      )
```
### Single dialog future custom empty list
When the future/network search keyword filters out all the results, the given emptyListWidget is displayed.
```dart
SearchChoices.single(
        value: selectedValueSingleDialogFuture,
        hint: kIsWeb ? "Example not for web" : "Select one capital",
        searchHint: "Search capitals",
        onChanged: kIsWeb
            ? null
            : (value) {
                setState(() {
                  selectedValueSingleDialogFuture = value;
                });
              },
        isExpanded: true,
        selectedValueWidgetFn: (item) {
          return (Center(
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.all(1),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(item["capital"]),
                  ))));
        },
        futureSearchFn: (String? keyword, String? orderBy, bool? orderAsc,
            List<Tuple2<String, String>>? filters, int? pageNb) async {
          String filtersString = "";
          int i = 1;
          filters?.forEach((element) {
            // This example doesn't have any futureSearchFilterOptions parameter, thus, this loop will never run anything.
            filtersString += "&filter" +
                i.toString() +
                "=" +
                element.item1 +
                "," +
                element.item2;
            i++;
          });
          Response response = await get(Uri.parse(
                  "https://searchchoices.jod.li/exampleList.php?page=${pageNb ?? 1},10${orderBy == null ? "" : "&order=" + orderBy + "," + (orderAsc ?? true ? "asc" : "desc")}${(keyword == null || keyword.isEmpty) ? "" : "&filter=capital,cs," + keyword}$filtersString"))
              .timeout(Duration(
            seconds: 10,
          ));
          if (response.statusCode != 200) {
            throw Exception("failed to get data from internet");
          }
          dynamic data = jsonDecode(response.body);
          int nbResults = data["results"];
          List<DropdownMenuItem> results = (data["records"] as List<dynamic>)
              .map<DropdownMenuItem>((item) => DropdownMenuItem(
                    value: item,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: Colors.blue,
                          width: 1,
                        ),
                      ),
                      margin: EdgeInsets.all(1),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                            "${item["capital"]} - ${item["country"]} - ${item["continent"]} - pop.: ${item["population"]}"),
                      ),
                    ),
                  ))
              .toList();
          return (Tuple2<List<DropdownMenuItem>, int>(results, nbResults));
        },
        emptyListWidget: () => Text(
          "No result",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      )
```
### Single dialog onTap
onTap parameter can be used to clear the selected value or to unfocus as shown in https://github.com/lcuis/search_choices/issues/26
```dart
SearchChoices.single(
        items: items,
        value: selectedValueSingleDialog,
        hint: "Select one",
        searchHint: "Select one",
        onChanged: (value) {
          setState(() {
            selectedValueSingleDialog = value;
          });
        },
        isExpanded: true,
        onTap: () {
          setState(() {
            selectedValueSingleDialog = null;
          });
        },
      )
```
### Multi dialog paged future
Multiple choice dialog box search with pagination, with future items coming from the API and with filter and sort options.
```dart
SearchChoices.multiple(
        futureSelectedValues: selectedItemsMultiDialogPagedFuture,
        hint: kIsWeb ? "Example not for web" : "Select capitals",
        searchHint: "",
        dialogBox: true,
        onChanged: kIsWeb
            ? null
            : (value) {
          setState(() {
            selectedItemsMultiDialogPagedFuture = value;
          });
        },
        isExpanded: true,
        itemsPerPage: 10,
        currentPage: currentPage,
        selectedValueWidgetFn: (item) {
          return (Center(
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.all(1),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(item["capital"]),
                  ))));
        },
        futureSearchFn: (String? keyword, String? orderBy, bool? orderAsc,
            List<Tuple2<String, String>>? filters, int? pageNb) async {
          String filtersString = "";
          int i = 1;
          filters?.forEach((element) {
            filtersString += "&filter" +
                i.toString() +
                "=" +
                element.item1 +
                "," +
                element.item2;
            i++;
          });
          Response response = await get(Uri.parse(
              "https://searchchoices.jod.li/exampleList.php?page=${pageNb ??
                  1},10${orderBy == null ? "" : "&order=" + orderBy + "," +
                  (orderAsc ?? true ? "asc" : "desc")}${(keyword == null ||
                  keyword.isEmpty) ? "" : "&filter=capital,cs," +
                  keyword}$filtersString"))
              .timeout(Duration(
            seconds: 10,
          ));
          if (response.statusCode != 200) {
            throw Exception("failed to get data from internet");
          }
          dynamic data = jsonDecode(response.body);
          int nbResults = data["results"];
          List<DropdownMenuItem> results = (data["records"] as List<dynamic>)
              .map<DropdownMenuItem>((item) =>
              DropdownMenuItem(
                value: item,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: Colors.blue,
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                        "${item["capital"]} - ${item["country"]} - ${item["continent"]} - pop.: ${item["population"]}"),
                  ),
                ),
              ))
              .toList();
          return (Tuple2<List<DropdownMenuItem>, int>(results, nbResults));
        },
        futureSearchOrderOptions: {
          "country": {
            "icon": Wrap(children: [
              Icon(Icons.flag),
              Text(
                "Country",
              )
            ]),
            "asc": true
          },
          "capital": {
            "icon":
            Wrap(children: [Icon(Icons.location_city), Text("Capital")]),
            "asc": true
          },
          "continent": {"icon": "Continent", "asc": true},
          "population": {
            "icon": Wrap(children: [Icon(Icons.people), Text("Population")]),
            "asc": false
          },
        },
        futureSearchFilterOptions: {
          "continent": {
            "icon": Text("Continent"),
            "exclusive": true,
            "values": [
              {"eq,Africa": "Africa"},
              {"eq,Americas": "Americas"},
              {"eq,Asia": "Asia"},
              {"eq,Australia": "Australia"},
              {"eq,Europe": "Europe"},
              {"eq,Oceania": "Oceania"}
            ]
          },
          "population": {
            "icon": Wrap(children: [Icon(Icons.people), Text("Population")]),
            "exclusive": true,
            "values": [
              {
                "lt,1000": Wrap(children: [Icon(Icons.person), Text("<1,000")])
              },
              {
                "lt,100000":
                Wrap(children: [Icon(Icons.person_add), Text("<100,000")])
              },
              {
                "lt,1000000": Wrap(
                    children: [Icon(Icons.nature_people), Text("<1,000,000")])
              },
              {
                "gt,1000000":
                Wrap(children: [Icon(Icons.people), Text(">1,000,000")])
              },
              {
                "gt,10000000": Wrap(
                    children: [Icon(Icons.location_city), Text(">10,000,000")])
              },
            ]
          },
        },
      )
```
### Single dialog future custom error button
Single choice dialog box search with intentional future search error to show an example of futureSearchRetryButton usa.
```dart
SearchChoices.single(
        value: selectedValueSingleDialogFuture,
        hint: kIsWeb ? "Example not for web" : "Select one capital",
        searchHint: "Search capitals",
        onChanged: kIsWeb
            ? null
            : (value) {
          setState(() {
            selectedValueSingleDialogFuture = value;
          });
        },
        isExpanded: true,
        selectedValueWidgetFn: (item) {
          return (Center(
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.all(1),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(item["capital"]),
                  ))));
        },
        futureSearchFn: (String? keyword, String? orderBy, bool? orderAsc,
            List<Tuple2<String, String>>? filters, int? pageNb) async {
          String filtersString = "";
          int i = 1;
          filters?.forEach((element) {
            // This example doesn't have any futureSearchFilterOptions parameter, thus, this loop will never run anything.
            filtersString += "&filter" +
                i.toString() +
                "=" +
                element.item1 +
                "," +
                element.item2;
            i++;
          });
          Response response = await get(Uri.parse(
              "https://FAULTYsearchchoices.jod.li/exampleList.php?page=${pageNb ?? 1},10${orderBy == null ? "" : "&order=" + orderBy + "," + (orderAsc ?? true ? "asc" : "desc")}${(keyword == null || keyword.isEmpty) ? "" : "&filter=capital,cs," + keyword}$filtersString"))
              .timeout(Duration(
            seconds: 10,
          ));
          if (response.statusCode != 200) {
            throw Exception("failed to get data from internet");
          }
          dynamic data = jsonDecode(response.body);
          int nbResults = data["results"];
          List<DropdownMenuItem> results = (data["records"] as List<dynamic>)
              .map<DropdownMenuItem>((item) => DropdownMenuItem(
            value: item,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: Colors.blue,
                  width: 1,
                ),
              ),
              margin: EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                    "${item["capital"]} - ${item["country"]} - ${item["continent"]} - pop.: ${item["population"]}"),
              ),
            ),
          ))
              .toList();
          return (Tuple2<List<DropdownMenuItem>, int>(results, nbResults));
        },
        futureSearchRetryButton: (Function onPressed) => Column(children: [
          SizedBox(height: 15),
          Center(
            child: ElevatedButton.icon(
                onPressed: (){onPressed();},
                icon: Icon(Icons.repeat),
                label: Text("Intentional error - retry")),
          )
        ]),
      )
```
### Single dialog paged delayed
Delayed search lets the user some time before calling the search function and work for Future and non-Future cases.
```dart
SearchChoices.single(
            items: items,
            value: selectedValueSingleDialogPaged,
            hint: "Select one",
            searchHint: "Search one",
            onChanged: (value) {
              setState(() {
                selectedValueSingleDialogPaged = value;
              });
            },
            isExpanded: true,
            itemsPerPage: 5,
            currentPage: currentPage,
            searchDelay: 500,
          )
```
### Single dialog paged future delayed
Delayed search lets the user some time before calling the search function and work for Future and non-Future cases.
```dart
SearchChoices.single(
            value: selectedValueSingleDialogPagedFuture,
            hint: kIsWeb ? "Example not for web" : "Select one capital",
            searchHint: "Search capitals",
            onChanged: kIsWeb
                ? null
                : (value) {
                    setState(() {
                      selectedValueSingleDialogPagedFuture = value;
                    });
                  },
            isExpanded: true,
            itemsPerPage: 10,
            currentPage: currentPage,
            selectedValueWidgetFn: (item) {
              return (Center(
                  child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      margin: EdgeInsets.all(1),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(item["capital"]),
                      ))));
            },
            futureSearchFn: (String? keyword, String? orderBy, bool? orderAsc,
                List<Tuple2<String, String>>? filters, int? pageNb) async {
              print("searching for ${keyword ?? ""}");
              String filtersString = "";
              int i = 1;
              filters?.forEach((element) {
                filtersString += "&filter" +
                    i.toString() +
                    "=" +
                    element.item1 +
                    "," +
                    element.item2;
                i++;
              });
              Response response = await get(Uri.parse(
                      "https://searchchoices.jod.li/exampleList.php?page=${pageNb ?? 1},10${orderBy == null ? "" : "&order=" + orderBy + "," + (orderAsc ?? true ? "asc" : "desc")}${(keyword == null || keyword.isEmpty) ? "" : "&filter=capital,cs," + keyword}$filtersString"))
                  .timeout(Duration(
                seconds: 10,
              ));
              if (response.statusCode != 200) {
                throw Exception("failed to get data from internet");
              }
              dynamic data = jsonDecode(response.body);
              int nbResults = data["results"];
              List<DropdownMenuItem> results = (data["records"] as List<dynamic>)
                  .map<DropdownMenuItem>((item) => DropdownMenuItem(
                        value: item,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(
                              color: Colors.blue,
                              width: 1,
                            ),
                          ),
                          margin: EdgeInsets.all(10),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                                "${item["capital"]} - ${item["country"]} - ${item["continent"]} - pop.: ${item["population"]}"),
                          ),
                        ),
                      ))
                  .toList();
              return (Tuple2<List<DropdownMenuItem>, int>(results, nbResults));
            },
            futureSearchOrderOptions: {
              "country": {
                "icon": Wrap(children: [
                  Icon(Icons.flag),
                  Text(
                    "Country",
                  )
                ]),
                "asc": true
              },
              "capital": {
                "icon":
                    Wrap(children: [Icon(Icons.location_city), Text("Capital")]),
                "asc": true
              },
              "continent": {"icon": "Continent", "asc": true},
              "population": {
                "icon": Wrap(children: [Icon(Icons.people), Text("Population")]),
                "asc": false
              },
            },
            futureSearchFilterOptions: {
              "continent": {
                "icon": Text("Continent"),
                "exclusive": true,
                "values": [
                  {"eq,Africa": "Africa"},
                  {"eq,Americas": "Americas"},
                  {"eq,Asia": "Asia"},
                  {"eq,Australia": "Australia"},
                  {"eq,Europe": "Europe"},
                  {"eq,Oceania": "Oceania"}
                ]
              },
              "population": {
                "icon": Wrap(children: [Icon(Icons.people), Text("Population")]),
                "exclusive": true,
                "values": [
                  {
                    "lt,1000": Wrap(children: [Icon(Icons.person), Text("<1,000")])
                  },
                  {
                    "lt,100000":
                        Wrap(children: [Icon(Icons.person_add), Text("<100,000")])
                  },
                  {
                    "lt,1000000": Wrap(
                        children: [Icon(Icons.nature_people), Text("<1,000,000")])
                  },
                  {
                    "gt,1000000":
                        Wrap(children: [Icon(Icons.people), Text(">1,000,000")])
                  },
                  {
                    "gt,10000000": Wrap(
                        children: [Icon(Icons.location_city), Text(">10,000,000")])
                  },
                ],
              },
            },
            closeButton: (selectedItemsDone, doneContext) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 25,
                    width: 48,
                    child: (ElevatedButton(
                        onPressed: () {
                          Navigator.pop(doneContext);
                          setState(() {});
                        },
                        child: Icon(
                          Icons.close,
                          size: 17,
                        ))),
                  ),
                ],
              );
            },
            searchDelay: 500,
            // Here, buildFutureFilterOrOrderButton doesn't change anything.
            // This is a way to make sure this parameter still works with automated
            // integration testing.
            buildFutureFilterOrOrderButton: ({
              required BuildContext context,
              required bool filter,
              required Function onPressed,
              int? nbFilters,
              bool? orderAsc,
              String? orderBy,
            }) {
              if (filter) {
                return (SizedBox(
                  height: 25,
                  width: 48,
                  child: (ElevatedButton(
                    child: Icon(
                      nbFilters == null || nbFilters == 0
                          ? Icons.filter
                          : nbFilters == 1
                              ? Icons.filter_1
                              : nbFilters == 2
                                  ? Icons.filter_2
                                  : nbFilters == 3
                                      ? Icons.filter_3
                                      : nbFilters == 4
                                          ? Icons.filter_4
                                          : nbFilters == 5
                                              ? Icons.filter_5
                                              : nbFilters == 6
                                                  ? Icons.filter_6
                                                  : nbFilters == 7
                                                      ? Icons.filter_7
                                                      : nbFilters == 8
                                                          ? Icons.filter_8
                                                          : nbFilters == 9
                                                              ? Icons.filter_9
                                                              : Icons
                                                                  .filter_9_plus_sharp,
                      size: 17,
                    ),
                    onPressed: () {
                      onPressed();
                    },
                  )),
                ));
              }

              Widget icon = Icon(
                Icons.sort,
                size: 17,
              );

              return SizedBox(
                height: 25,
                width: orderBy == null ? 48 : 70,
                child: (orderBy == null
                    ? ElevatedButton(
                        child: icon,
                        onPressed: () {
                          onPressed();
                        },
                      )
                    : ElevatedButton.icon(
                        label: Icon(
                          orderAsc ?? true
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 17,
                        ),
                        icon: icon,
                        onPressed: () {
                          onPressed();
                        },
                      )),
              );
            },
            // Here, searchResultDisplayFn doesn't change anything.
            // This is a way to make sure this parameter still works with automated
            // integration testing.
            searchResultDisplayFn: ({
                required List<Tuple3<int, DropdownMenuItem, bool>> itemsToDisplay,
                required ScrollController scrollController,
                required bool thumbVisibility,
                required Widget emptyListWidget,
                required void Function(int index, dynamic value, bool itemSelected)
                  itemTapped,
                required Widget Function(DropdownMenuItem item, bool isItemSelected)
                  displayItem,
            }) {
                return Expanded(
                    child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: thumbVisibility,
                        child: itemsToDisplay.length == 0
                        ? emptyListWidget
                            : ListView.builder(
                            controller: scrollController,
                            itemBuilder: (context, index) {
                                int itemIndex = itemsToDisplay[index].item1;
                                DropdownMenuItem item = itemsToDisplay[index].item2;
                                bool isItemSelected = itemsToDisplay[index].item3;
                                return InkWell(
                                    onTap: () {
                                        itemTapped(
                                            itemIndex,
                                            item.value,
                                            isItemSelected,
                                        );
                                    },
                                    child: displayItem(
                                        item,
                                        isItemSelected,
                                    ),
                                );
                            },
                            itemCount: itemsToDisplay.length,
                        ),
                    ),
                );
            },
          )
```
### Single dialog custom field presentation
Making use of `fieldPresentationFn` to display the result of the selection in a custom way.
```dart
SearchChoices.single(
            items: items,
            value: selectedValueSingleDialog,
            hint: "Select one",
            searchHint: "Select one",
            onChanged: (value) {
              setState(() {
                selectedValueSingleDialog = value;
              });
            },
            isExpanded: true,
            fieldPresentationFn: (Widget fieldWidget, {bool? selectionIsValid}) {
              return Container(
                padding: const EdgeInsets.all(12.0),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Label',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.green.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  child: fieldWidget,
                ),
              );
            },
          )
```
### Single custom showDialogFn
Customizing the call to showDialog.
```dart
SearchChoices.single(
            items: items,
            value: selectedValueSingleDialog,
            onChanged: (value) {
              setState(() {
                selectedValueSingleDialog = value;
              });
            },
            hint: "Select one",
            isExpanded: true,
            showDialogFn: (
              BuildContext context,
              Widget Function({String searchTerms}) menuWidget,
              String searchTerms,
            ) async {
              await showDialog(
                  barrierColor: Colors.pinkAccent,
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return (menuWidget(searchTerms: searchTerms));
                  });
            },
          )
```
### Validator in form
The form field validator is called by the parent form validator.
```dart
      Form(
        key: _formKeyForValidator,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              validator: (String? value) {
                if (value == "ok") {
                  return (null);
                }
                return ("Not the expected value");
              },
            ),
            SearchChoices.single(
              items: items,
              value: selectedValueSingleDialog,
              onChanged: (value) {
                setState(() {
                  selectedValueSingleDialog = value;
                });
              },
              isExpanded: true,
              validator: (dynamic value) {
                if (value == null) {
                  return ("Must select a value");
                }
                if (!(value is String)) {
                  return ("Selected value must be a String");
                }
                if (value.startsWith("l")) {
                  return (null);
                }
                return ("Must start with 'l'");
              },
            ),
            SearchChoices.multiple(
              items: items,
              selectedItems: selectedItemsMultiDialog,
              onChanged: (value) {
                setState(() {
                  selectedItemsMultiDialog = value;
                });
              },
              isExpanded: true,
              validator: (dynamic value) {
                if (value == null) {
                  return ("Must select some values");
                }
                if (!(value is List<int>)) {
                  return ("Selection is of unexpected type");
                }
                if (value.length < 3) {
                  return ("Must select at least 3");
                }
                return (null);
              },
            ),
            TextButton(
              onPressed: () {
                if (_formKeyForValidator.currentState?.validate() ?? false) {
                  setState(() {
                    formResult = "All good";
                  });
                } else {
                  setState(() {
                    formResult = "Form is not valid!";
                  });
                }
              },
              child: const Text("Ok"),
            ),
            formResult == null
                ? SizedBox.shrink()
                : Text(formResult ?? "",
                    style: TextStyle(
                      color:
                          formResult == "All good" ? Colors.black : Colors.red,
                    )),
          ],
        ),
      )
```
## Feature requests/comments/questions/bugs

Feel free to log your feature requests/comments/questions/bugs here:
https://github.com/lcuis/search_choices/issues

## Contributions

This solution is based on improvements done on a pull request that was probably already changing too many things to the [great original repository](https://github.com/icemanbsi/searchable_dropdown):
https://github.com/icemanbsi/searchable_dropdown/pull/11

I would be happy to merge pull request proposals provided that:
* they don't break the compilation
* they pass the automated testing
* they provide the relevant adaptations to documentation and automated testing
* they bring value
* they don't completely transform the code
* they are readable (though, I enjoy https://www.ioccc.org/ as a contest full of curiosities)

Contributions and forks are very welcome!

In your pull request, feel free to add your line in the contributors section below:

### Contributors
* (great initial project) https://github.com/icemanbsi/searchable_dropdown/pull/11
* https://github.com/lcuis
* https://github.com/avalentic
* https://github.com/luis-cruzt
* https://github.com/develogo
* https://github.com/Macacoazul01

## CI/CD

Continuous integration/deployment status: ![CI-CD](https://github.com/lcuis/search_choices/workflows/CI-CD/badge.svg)

Automated integration testing was done using [Flutster](https://flutster.com). Here is the latest recorded video of this automated integration testing: [https://searchchoices.jod.li/integration_test.mkv](https://searchchoices.jod.li/integration_test.mkv)
