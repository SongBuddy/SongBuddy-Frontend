import 'package:flutter/material.dart';



class SearchFeedScreen extends StatefulWidget {
  const SearchFeedScreen({super.key});

  @override
  State<SearchFeedScreen> createState() => _SearchFeedScreenState();
}

class _SearchFeedScreenState extends State<SearchFeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
       child: Center(child: Text("SearchFeedScreen")),
    );
  }
}