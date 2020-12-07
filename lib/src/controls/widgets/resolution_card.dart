import 'package:better_player/src/core/constants.dart';
import 'package:flutter/material.dart';

class Resolution {
  final String name;
  final String url;

  Resolution({this.name, this.url});
}

class ResolutionCard extends StatelessWidget {
  final bool isSelected;
  final Resolution track;
  final ValueChanged<Resolution> onTap;
  const ResolutionCard({
    Key key,
    this.isSelected,
    this.onTap,
    this.track,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(track),
      child: Container(
        width: 84,
        height: 41,
        decoration: !isSelected
            ? BoxDecoration()
            : BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppTheme.cardBottomColor),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Spacer(),
              SizedBox(
                width: 14,
              ),
              Text('${track.name}p',
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyText1.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSelected ? 11 : 13,
                      color: Colors.white)),
              Spacer(),
              (isSelected)
                  ? Icon(
                      Icons.check,
                      size: 20,
                      color: AppTheme.activeButtonColor,
                    )
                  : SizedBox(
                      width: 3,
                    ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
