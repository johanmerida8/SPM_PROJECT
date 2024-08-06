import 'package:chat_app/services/emoji_services/emoji_service.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';

class EmojisWidget extends StatefulWidget {
  final Function addEmojiToTextController;

  const EmojisWidget({super.key, required this.addEmojiToTextController});

  @override
  State<EmojisWidget> createState() => _EmojisWidgetState();
}

class _EmojisWidgetState extends State<EmojisWidget>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  EmojisService emojisService = EmojisService();
  List<Emoji> smileyEmojis = [];
  List<Emoji> petEmojis = [];
  List<Emoji> foodEmojis = [];
  List<Emoji> sportsEmojis = [];
  List<Emoji> vehiclesEmojis = [];
  List<Emoji> toolsEmojis = [];
  List<Emoji> objectsEmojis = [];
  List<Emoji> flagsEmojis = [];

  @override
  void initState() {
    _tabController = TabController(length: 8, vsync: this);
    for (var emojiSet in defaultEmojiSet) {
      emojisService.getCategoryEmojis(category: emojiSet).then(
            (e) async => await emojisService.filterUnsupported(data: [e]).then(
              (filtered) {
                for (var element in filtered) {
                  switch (emojiSet.category) {
                    case Category.SMILEYS:
                      setState(() {
                        smileyEmojis = element.emoji;
                      });
                      break;
                    case Category.SMILEYS:
                      setState(() {
                        smileyEmojis = element.emoji;
                      });
                      break;
                    case Category.ANIMALS:
                      setState(() {
                        petEmojis = element.emoji;
                      });
                      break;
                    case Category.FOODS:
                      setState(() {
                        foodEmojis = element.emoji;
                      });
                      break;
                    case Category.ACTIVITIES:
                      setState(() {
                        sportsEmojis = element.emoji;
                      });
                      break;
                    case Category.TRAVEL:
                      setState(() {
                        vehiclesEmojis = element.emoji;
                      });
                      break;
                    case Category.SYMBOLS:
                      setState(() {
                        toolsEmojis = element.emoji;
                      });
                      break;
                    case Category.OBJECTS:
                      setState(() {
                        objectsEmojis = element.emoji;
                      });
                      break;
                    case Category.FLAGS:
                      setState(() {
                        flagsEmojis = element.emoji;
                      });
                      break;
                    default:
                  }
                }
              },
            ),
          );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.black,
              indicator: MaterialIndicator(
                color: Colors.black,
                height: 3,
                topLeftRadius: 5,
                topRightRadius: 5,
                bottomLeftRadius: 5,
                bottomRightRadius: 5,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.all(5),
              unselectedLabelColor: Colors.grey.withOpacity(0.4),
              tabs: const [
                Icon(Icons.emoji_emotions),
                Icon(Ionicons.paw),
                Icon(Ionicons.fast_food),
                Icon(Ionicons.football),
                Icon(Ionicons.boat),
                Icon(Ionicons.bulb),
                Icon(Ionicons.trophy),
                Icon(Ionicons.flag),
              ]),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildEmojis(emojis: smileyEmojis),
                buildEmojis(emojis: petEmojis),
                buildEmojis(emojis: foodEmojis),
                buildEmojis(emojis: sportsEmojis),
                buildEmojis(emojis: vehiclesEmojis),
                buildEmojis(emojis: toolsEmojis),
                buildEmojis(emojis: objectsEmojis),
                buildEmojis(emojis: flagsEmojis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmojis({required List<Emoji> emojis}) {
    return emojis.isEmpty
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : GridView.builder(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: emojis.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8),
            itemBuilder: (context, index) {
              Emoji emoji = emojis[index];
              return Center(
                child: GestureDetector(
                  onTap: () {
                    widget.addEmojiToTextController(emoji.emoji);
                  },
                  child: Text(
                    emoji.emoji,
                    style: TextStyle(color: Colors.black, fontSize: 32),
                  ),
                ),
              );
            },
          );
  }
}
