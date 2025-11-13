import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../l10n/contact_localizations.dart';
import 'dart:io';
import '../models/contact_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../utils/image_utils.dart';

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final bool isListView;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onTap,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: InkWell(
          onTap: onTap,
          child: isListView ? _buildListView(context) : _buildCardView(context),
        ),
      ),
    );
  }

  Widget _buildCardView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(size: 48),
          const SizedBox(height: 4),
          Text(
            contact.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            contact.phone,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildTags(),
          const SizedBox(height: 8),
          _buildLastContactInfo(context),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          _buildAvatar(size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(contact.phone, style: const TextStyle(color: Colors.grey)),
                if (contact.address != null && contact.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      contact.address!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required double size}) {
    if (contact.avatar != null && contact.avatar!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: contact.iconColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: FutureBuilder<String>(
            future:
                contact.avatar!.startsWith('http')
                    ? Future.value(contact.avatar!)
                    : ImageUtils.getAbsolutePath(contact.avatar),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ClipOval(
                  child:
                      contact.avatar!.startsWith('http')
                          ? Image.network(
                            snapshot.data!,
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    _buildIconAvatar(size),
                          )
                          : Image.file(
                            File(snapshot.data!),
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    _buildIconAvatar(size),
                          ),
                );
              } else if (snapshot.hasError) {
                return _buildIconAvatar(size);
              } else {
                return SizedBox(
                  width: size,
                  height: size,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
            },
          ),
        ),
      );
    }
    return _buildIconAvatar(size);
  }

  Widget _buildIconAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: contact.iconColor,
      ),
      child: Icon(contact.icon, color: Colors.white, size: size * 0.5),
    );
  }

  Widget _buildTags() {
    if (contact.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children:
          contact.tags.map((tag) {
            return Chip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(tag, style: const TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            );
          }).toList(),
    );
  }

  Widget _buildLastContactInfo(BuildContext context, {bool compact = false}) {
    final lastContactText = timeago.format(
      contact.lastContactTime,
      locale: 'zh',
    );

    return Text(
      compact
          ? lastContactText
          : '${ContactLocalizations.of(context).lastContactTime}: $lastContactText',
      style: TextStyle(fontSize: compact ? 12 : 14, color: Colors.grey),
    );
  }
}
