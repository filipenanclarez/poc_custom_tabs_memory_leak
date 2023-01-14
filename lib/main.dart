import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> data = [
    {"titulo": "Page 0"}
  ];
  int initPosition = 0;

  static final customTabState = new GlobalKey<_CustomTabsState>();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      customTabState.currentState!.controller!.addListener(() {
        // debugPrint('addListener');
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    customTabState.currentState!.controller!.removeListener(() {
      // debugPrint('removeListener');
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomTabView(
          key: customTabState,
          initPosition: initPosition,
          itemCount: data.length,
          tabBuilder: (context, index) => Tab(text: data[index]['titulo']),
          pageBuilder: (context, index) => TabContent(
            key: UniqueKey(),
            titulo: index.toString(),
            cover: data[index]['cover'],
          ),
          onPositionChange: (index) {
            // debugPrint('current position: $index');
            initPosition = index;
          },
          // onScroll: (position) => debugPrint('$position'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          ByteData assetImageByteData =
              await rootBundle.load('assets/image.jpg');

          Uint8List assetImageUint8List =
              assetImageByteData.buffer.asUint8List();

          // data.add('Page ${data.length}');
          // data.add(
          //     {'titulo': 'Page ${data.length}', 'cover': assetImageUint8List});
          // setState(() {});
          // return;

          for (var i = 0; i < 13; i++) {
            for (var j = 0; j < 100; j++) {
              setState(() {
                // data.add('Page ${data.length}');
                data.add({
                  'titulo': 'Page ${data.length}',
                  'cover': assetImageUint8List
                });
              });

              setState(() {});

              await customTabState.currentState!.createTabComplete();

              customTabState.currentState!.controller!.animateTo(
                  data.length - 1,
                  duration: Duration(milliseconds: 100));

              await Future.delayed(Duration(milliseconds: 500));
            }

            await Future.delayed(Duration(seconds: 1));

            for (var j = 0; j < 100; j++) {
              setState(() {
                data.removeAt(data.length - 1);
              });
              await Future.delayed(Duration(milliseconds: 100));
            }

            await Future.delayed(Duration(seconds: 1));
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

/// Implementation

class CustomTabView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder tabBuilder;
  final IndexedWidgetBuilder pageBuilder;
  final Widget? stub;
  final ValueChanged<int>? onPositionChange;
  final ValueChanged<double>? onScroll;
  final int? initPosition;

  const CustomTabView({
    Key? key,
    required this.itemCount,
    required this.tabBuilder,
    required this.pageBuilder,
    this.stub,
    this.onPositionChange,
    this.onScroll,
    this.initPosition,
  }) : super(key: key);

  @override
  _CustomTabsState createState() => _CustomTabsState();
}

class _CustomTabsState extends State<CustomTabView>
    with TickerProviderStateMixin {
  TabController? controller;
  int? _currentCount;
  int? _currentPosition;

  dynamic createTabCompleter;

  Future<void> createTabComplete() async {
    createTabCompleter = Completer();
    return createTabCompleter.future;
  }

  @override
  void initState() {
    _currentPosition = widget.initPosition ?? 0;
    controller = TabController(
      length: widget.itemCount,
      vsync: this,
      initialIndex: _currentPosition!,
    );
    controller!.addListener(onPositionChange);
    controller!.animation!.addListener(onScroll);
    _currentCount = widget.itemCount;
    super.initState();
  }

  @override
  void didUpdateWidget(CustomTabView oldWidget) {
    if (_currentCount != widget.itemCount) {
      controller!.animation!.removeListener(onScroll);
      controller!.removeListener(onPositionChange);
      controller!.dispose();

      if (widget.initPosition != null) {
        _currentPosition = widget.initPosition;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (createTabCompleter != null && !createTabCompleter.isCompleted)
            createTabCompleter.complete();
        });
      }

      if (_currentPosition! > widget.itemCount - 1) {
        _currentPosition = widget.itemCount - 1;
        _currentPosition = _currentPosition! < 0 ? 0 : _currentPosition;
        if (widget.onPositionChange is ValueChanged<int>) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onPositionChange!(_currentPosition!);
            }
          });
        }
      }

      _currentCount = widget.itemCount;
      setState(() {
        controller = TabController(
          length: widget.itemCount,
          vsync: this,
          initialIndex: _currentPosition!,
        );
        controller!.addListener(onPositionChange);
        controller!.animation!.addListener(onScroll);
      });
    } else if (widget.initPosition != null) {
      controller!.animateTo(widget.initPosition!);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller!.animation!.removeListener(onScroll);
    controller!.removeListener(onPositionChange);
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount < 1) return widget.stub ?? Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          alignment: Alignment.center,
          child: TabBar(
            isScrollable: true,
            controller: controller,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).hintColor,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
            tabs: List.generate(
              widget.itemCount,
              (index) => widget.tabBuilder(context, index),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: List.generate(
              widget.itemCount,
              (index) => widget.pageBuilder(context, index),
            ),
          ),
        ),
      ],
    );
  }

  onPositionChange() {
    if (!controller!.indexIsChanging) {
      _currentPosition = controller!.index;
      if (widget.onPositionChange is ValueChanged<int>) {
        widget.onPositionChange!(_currentPosition!);
      }
    }
  }

  onScroll() {
    if (widget.onScroll is ValueChanged<double>) {
      widget.onScroll!(controller!.animation!.value);
    }
  }
}

class TabContent extends StatefulWidget {
  final String titulo;
  Uint8List? cover;
  TabContent({super.key, required this.titulo, this.cover});

  @override
  State<TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<TabContent> {
  @override
  void initState() {
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   // debugPrint('terminei de carregar a tab');
    // });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: widget.cover != null
                ? Image.memory(
                    widget.cover!,
                    fit: BoxFit.fill,
                    // width: 100,
                    // height: 100,
                  )
                : Container(),
          )
        ],
      ),
    );
  }
}
