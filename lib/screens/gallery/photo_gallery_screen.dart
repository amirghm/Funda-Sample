import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fund_sample/data/models/media.dart';
import 'package:fund_sample/resources/resources.dart';
import 'package:fund_sample/utils/widgets/hidable_app_bar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share/share.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen(
      {Key? key, required this.images, required this.index, required this.tag})
      : super(key: key);

  final List<Media> images;
  final int index;
  final String tag;

  static Future<dynamic> open(
      BuildContext context, List<Media> images, int index, String tag) {
    return Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              PhotoGalleryScreen(images: images, index: index, tag: tag)),
    );
  }

  @override
  _PhotoGalleryState createState() =>
      _PhotoGalleryState(images: images, initialIndex: index, tag: tag);
}

class _PhotoGalleryState extends State<PhotoGalleryScreen>
    with SingleTickerProviderStateMixin {

  late List<Media> images;
  late int initialIndex;
  late int index;
  late String tag;
  String titleIndicator = '';

  bool _showAppBar = true;
  bool _isImageZoomed = false;
  late AnimationController _controller;
  late PageController _pageController;

  _PhotoGalleryState({required this.images, required this.initialIndex, required this.tag});

  @override
  initState() {
    super.initState();
    index = initialIndex;

    initPageController();
    initTitleIndicator();
    initAnimationController();
  }

  initAnimationController() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
  }

  initTitleIndicator() {
    if (images.length == 1)
      titleIndicator = '';
    else
      titleIndicator = Resources.getStringWithPlaceholder(
          'photo_gallery__count_indicator',
          [(index + 1).toString(), images.length.toString()]);
  }

  initPageController() {
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      direction:
          _isImageZoomed ? DismissDirection.none : DismissDirection.vertical,
      key: const Key('key'),
      onDismiss: () {
        SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: _appBarWidget(),
        body: _bodyWidget(),
      ),
    );
  }

  _appBarWidget() {
    return SlidingAppBar(
        controller: _controller,
        visible: _showAppBar,
        child: AppBar(
          backgroundColor: Colors.transparent,
          brightness: Brightness.dark,
          centerTitle: true,
          leading: InkWell(
              customBorder: CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.keyboard_backspace,
                size: 24,
                color: Colors.white,
              )),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: new LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent]),
            ),
          ),
          elevation: 0,
          title: Text(
            titleIndicator,
            style: Resources.getToolbarTitleStyle(),
          ),
        ));
  }

  _bodyWidget() {
    return GestureDetector(
        onTap: () => setState(() => _showAppBar = !_showAppBar),
        child: Stack(
          children: [
            Container(
                child: PhotoViewGallery(
              scaleStateChangedCallback: (scale) => setState(() {
                print(scale);
                _isImageZoomed = scale == PhotoViewScaleState.zoomedIn;
              }),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _isImageZoomed = false;
                  this.index = index;
                  titleIndicator = Resources.getStringWithPlaceholder(
                      'photo_gallery__count_indicator',
                      [(index + 1).toString(), images.length.toString()]);
                });
              },
              pageOptions: List.generate(images.length, (index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider:
                      CachedNetworkImageProvider(images[index].imageUrl ?? ''),
                  heroAttributes: PhotoViewHeroAttributes(
                      tag: "${tag}-${images[index].id}"),
                );
              }),
            )),
            AnimatedOpacity(
              opacity: _showAppBar ? 1.0 : 0.0,
              duration: Duration(milliseconds: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 64,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: new LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black]),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () =>
                                handleOnShareClicked(images[index].imageUrl),
                            child: Icon(
                              Icons.share,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  handleOnShareClicked(String? image) async {
    if (image == null) return;
    try {
      var file = await DefaultCacheManager().getSingleFile(image);
      await Share.shareFiles([file.path]);
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
  }
}
