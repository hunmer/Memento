import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/contact/controllers/contact_controller.dart';
import 'package:Memento/plugins/contact/models/contact_model.dart';
import 'package:Memento/plugins/contact/screens/contact_records_screen.dart';
import 'package:Memento/plugins/contact/widgets/contact_form.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/widgets/common/contact_card.dart';

/// 联系人卡片组件（使用公共小组件）
///
/// 基于声明式构建，使用 ContactCardWidget 作为渲染层
class ContactCard extends StatefulWidget {
  final Contact contact;
  final ContactController controller;
  final VoidCallback onTap;
  final VoidCallback? onContactUpdated;

  const ContactCard({
    super.key,
    required this.contact,
    required this.controller,
    required this.onTap,
    this.onContactUpdated,
  });

  @override
  State<ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<ContactCard> {
  int _interactionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInteractionCount();
  }

  Future<void> _loadInteractionCount() async {
    final count = await widget.controller.getContactInteractionsCount(widget.contact.id);
    if (mounted) {
      setState(() {
        _interactionCount = count;
      });
    }
  }

  /// 将 Contact 转换为 ContactCardData
  ContactCardData _toContactCardData() {
    ContactCardGender? gender;
    switch (widget.contact.gender) {
      case ContactGender.male:
        gender = ContactCardGender.male;
        break;
      case ContactGender.female:
        gender = ContactCardGender.female;
        break;
      default:
        gender = null;
    }

    return ContactCardData(
      id: widget.contact.id,
      name: widget.contact.name,
      avatar: widget.contact.avatar,
      iconCodePoint: widget.contact.icon.codePoint,
      iconColorValue: widget.contact.iconColor.value,
      phone: widget.contact.phone,
      organization: widget.contact.organization,
      email: widget.contact.email,
      website: widget.contact.website,
      address: widget.contact.address,
      notes: widget.contact.notes,
      gender: gender,
      tags: widget.contact.tags,
      interactionCount: _interactionCount,
    );
  }

  void _showBottomSheet(BuildContext context) {
    SmoothBottomSheet.show(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '删除联系人',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('确认删除'),
          content: Text('确定要删除联系人 "${widget.contact.name}" 吗？\n此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await widget.controller.deleteContact(widget.contact.id);
                widget.onContactUpdated?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToRecords(BuildContext context) {
    NavigationHelper.push(
      context,
      ContactRecordsScreen(contact: widget.contact, controller: widget.controller),
    );
  }

  void _navigateToForm(BuildContext context) {
    NavigationHelper.openContainerWithHero(
      context,
      (context) => ContactForm(
        contact: widget.contact,
        onSave: (savedContact) async {
          await widget.controller.updateContact(savedContact);
          widget.onContactUpdated?.call();
          // 重新加载交互计数
          _loadInteractionCount();
        },
        onDelete: () async {
          await widget.controller.deleteContact(widget.contact.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ContactCardWidget(
      data: _toContactCardData(),
      onTap: () => _navigateToForm(context),
      onLongPress: () => _showBottomSheet(context),
      onHistoryTap: () => _navigateToRecords(context),
    );
  }
}
