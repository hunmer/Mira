import 'package:flutter/material.dart';
import '../models/library.dart';

class LibraryTabManager {
  final PageController pageController;
  final List<Library> libraries;
  final List<Library> initialLibraries;
  final ValueNotifier<int> currentIndex;

  LibraryTabManager({required this.libraries, required this.initialLibraries})
    : pageController = PageController(initialPage: 0),
      currentIndex = ValueNotifier(0) {
    pageController.addListener(_handlePageChange);
  }

  void _handlePageChange() {
    currentIndex.value = pageController.page?.round() ?? 0;
  }

  void addTab(Library library) {
    libraries.add(library);
    currentIndex.value = libraries.length - 1;
    if (pageController.hasClients) {
      pageController.jumpToPage(currentIndex.value);
    }
  }

  void closeTab(int index) {
    libraries.removeAt(index);
    if (currentIndex.value >= libraries.length) {
      currentIndex.value = libraries.length - 1;
    }
    pageController.jumpToPage(currentIndex.value);
  }

  void closeAllTabs() {
    libraries.clear();
    currentIndex.value = 0;
    pageController.jumpToPage(currentIndex.value);
  }

  void dispose() {
    pageController.removeListener(_handlePageChange);
    pageController.dispose();
    currentIndex.dispose();
  }
}
