# Cupertino Sidebar

**cupertino_sidebar** brings iOS-style sidebars and floating tab bars to Flutter, providing a sleek, native feel for iPadOS-style navigation in your app.

## Features

### Cupertino Sidebar

![Cupertino Sidebar](https://github.com/RoundedInfinity/cupertino_sidebar/blob/main/art/sidebar_demo.gif?raw=true)

A iOS-style sidebar that can be used to navigate through your app.

### Cupertino Floating Tab Bar

![Cupertino Floating Tab Bar](https://github.com/RoundedInfinity/cupertino_sidebar/blob/main/art/tabbar.gif?raw=true)

A iPadOS-style floating tab bar that can also be used to navigate through your app.

## 📖 Usage

### Sidebar

The `CupertinoSidebar` works very similar to Flutter's [NavigationDrawer](https://api.flutter.dev/flutter/material/NavigationDrawer-class.html). It accepts a list of destinations, a selected index, and a callback function triggered when a destination is tapped.

```dart
CupertinoSidebar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (value) {
    setState(() {
      // Update the selected index when a destination is selected.
      _selectedIndex = value;
    });
  },
  children: [
    // index 0
    SidebarDestination(
      icon: Icon(CupertinoIcons.home),
      label: Text('Home'),
    ),
    // index 1
    SidebarDestination(
      icon: Icon(CupertinoIcons.person),
      label: Text('Items'),
    ),
    // index 2
    SidebarDestination(
      icon: Icon(CupertinoIcons.search),
      label: Text('Search'),
    ),
  ],
);
```

CupertinoSidebar also supports expandable sections, allowing you to group destinations.

```dart
...
children: [
    ...
   SidebarSection(
      label: Text('My section'),
      children: [
        SidebarDestination(
          icon: Icon(CupertinoIcons.settings),
          label: Text('Settings'),
        ),
        ...
      ],
    ),
]
```

For a full example, see the [Sidebar example](https://github.com/RoundedInfinity/cupertino_sidebar/blob/main/example/lib/main.dart).

### Floating Tab Bar

The `CupertinoFloatingTabBar` is managed by a TabController, with options to add tabs and specify a callback function.

```dart
CupertinoFloatingTabBar(
  onDestinationSelected: (value) {},
  controller: _myTabController,
  tabs: const [
    CupertinoFloatingTab(
      child: Text('Today'),
    ),
    CupertinoFloatingTab(
      child: Text('Library'),
    ),
    CupertinoFloatingTab.icon(
      icon: Icon(CupertinoIcons.search),
    ),
  ],
)
```

For a full example, see the [Tab Bar example](https://github.com/RoundedInfinity/cupertino_sidebar/blob/main/example/lib/tab_bar_example.dart).

### Additional examples

- [Creating a collapsible sidebar](https://github.com/RoundedInfinity/cupertino_sidebar/blob/main/example/lib/collapsible_side_bar.dart)

## 📅 Roadmap

This package is actively being developed. Planned features include:

- Tab bar to sidebar transition
- **Adaptive scaffold** that switches between a sidebar and a floating tab bar and a bottom tab bar depending on the screen size.

## 🤝 Contributing

Contributions are welcome! Feel free to submit issues, ideas, or pull requests. Together, we can make cupertino_sidebar even better!