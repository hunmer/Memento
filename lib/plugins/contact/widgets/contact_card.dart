import 'package:flutter/material.dart';
import 'dart:io';
import '../models/contact_model.dart';
import '../../../utils/image_utils.dart';

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white;
    final primaryTextColor = theme.brightness == Brightness.dark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E);
    final secondaryTextColor = theme.brightness == Brightness.dark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8E);
    final chipColor = theme.brightness == Brightness.dark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEFF4);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopSection(context, primaryTextColor, secondaryTextColor),
              if (contact.notes != null && contact.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  contact.notes!,
                  style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              _buildTags(context, chipColor, secondaryTextColor),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildBottomSection(primaryTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, Color primaryTextColor, Color secondaryTextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(size: 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.name,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: primaryTextColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                contact.phone,
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
              if (contact.gender != null) ...[
                const SizedBox(height: 4),
                _buildGenderInfo(context),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 30),
          color: Theme.of(context).primaryColor,
          onPressed: () {
            // TODO: Implement action
          },
        ),
      ],
    );
  }

  Widget _buildGenderInfo(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    switch (contact.gender) {
      case ContactGender.female:
        icon = Icons.female;
        color = Colors.pink.shade400;
        text = "Female";
        break;
      case ContactGender.male:
        icon = Icons.male;
        color = Colors.blue.shade400;
        text = "Male";
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildAvatar({required double size}) {
    if (contact.avatar != null && contact.avatar!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: FutureBuilder<String>(
          future: contact.avatar!.startsWith('http')
              ? Future.value(contact.avatar!)
              : ImageUtils.getAbsolutePath(contact.avatar),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ClipOval(
                child: contact.avatar!.startsWith('http')
                    ? Image.network(
                        snapshot.data!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildIconAvatar(size),
                      )
                    : Image.file(
                        File(snapshot.data!),
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildIconAvatar(size),
                      ),
              );
            } else if (snapshot.hasError) {
              return _buildIconAvatar(size);
            } else {
              return SizedBox(
                width: size,
                height: size,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
          },
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
        color: contact.iconColor.withOpacity(0.2),
      ),
      child: Icon(contact.icon, color: contact.iconColor, size: size * 0.6),
    );
  }

  Widget _buildTags(BuildContext context, Color chipColor, Color textColor) {
    if (contact.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: contact.tags.map((tag) {
        return Chip(
          backgroundColor: chipColor,
          label: Text(tag, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Widget _buildBottomSection(Color textColor) {
    // Placeholder for event/meeting info
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green, // Example color
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "Meeting on Monday", // Example text
          style: TextStyle(fontSize: 14, color: textColor),
        ),
      ],
    );
  }
}