import 'package:flutter/material.dart';

class NodesLocalizations {
  final Locale locale;

  NodesLocalizations(this.locale);

  static NodesLocalizations of(BuildContext context) {
    return Localizations.of<NodesLocalizations>(context, NodesLocalizations) ?? 
        NodesLocalizations(Locale('en'));
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'notebooks': 'Notebooks',
      'nodes': 'Nodes',
      'addNotebook': 'Add Notebook',
      'editNotebook': 'Edit Notebook',
      'deleteNotebook': 'Delete Notebook',
      'notebookTitle': 'Notebook Title',
      'addNode': 'Add Node',
      'editNode': 'Edit Node',
      'deleteNode': 'Delete Node',
      'nodeTitle': 'Node Title',
      'tags': 'Tags',
      'status': 'Status',
      'startDate': 'Start Date',
      'endDate': 'End Date',
      'customFields': 'Custom Fields',
      'notes': 'Notes',
      'save': 'Save',
      'cancel': 'Cancel',
      'addChildNode': 'Add Child Node',
      'addSiblingNode': 'Add Sibling Node',
      'todo': 'To Do',
      'doing': 'Doing',
      'done': 'Done',
      'key': 'Key',
      'value': 'Value',
      'addCustomField': 'Add Custom Field',
    },
    'zh': {
      'notebooks': '笔记本',
      'nodes': '节点',
      'addNotebook': '添加笔记本',
      'editNotebook': '编辑笔记本',
      'deleteNotebook': '删除笔记本',
      'notebookTitle': '笔记本标题',
      'addNode': '添加节点',
      'editNode': '编辑节点',
      'deleteNode': '删除节点',
      'nodeTitle': '节点标题',
      'tags': '标签',
      'status': '状态',
      'startDate': '开始日期',
      'endDate': '截止日期',
      'customFields': '自定义属性',
      'notes': '备注',
      'save': '保存',
      'cancel': '取消',
      'addChildNode': '添加子节点',
      'addSiblingNode': '添加同级节点',
      'todo': '待办',
      'doing': '进行中',
      'done': '已完成',
      'key': '键',
      'value': '值',
      'addCustomField': '添加自定义属性',
    },
  };

  String get notebooks => _localizedValues[locale.languageCode]?['notebooks'] ?? 'Notebooks';
  String get nodes => _localizedValues[locale.languageCode]?['nodes'] ?? 'Nodes';
  String get addNotebook => _localizedValues[locale.languageCode]?['addNotebook'] ?? 'Add Notebook';
  String get editNotebook => _localizedValues[locale.languageCode]?['editNotebook'] ?? 'Edit Notebook';
  String get deleteNotebook => _localizedValues[locale.languageCode]?['deleteNotebook'] ?? 'Delete Notebook';
  String get notebookTitle => _localizedValues[locale.languageCode]?['notebookTitle'] ?? 'Notebook Title';
  String get addNode => _localizedValues[locale.languageCode]?['addNode'] ?? 'Add Node';
  String get editNode => _localizedValues[locale.languageCode]?['editNode'] ?? 'Edit Node';
  String get deleteNode => _localizedValues[locale.languageCode]?['deleteNode'] ?? 'Delete Node';
  String get nodeTitle => _localizedValues[locale.languageCode]?['nodeTitle'] ?? 'Node Title';
  String get tags => _localizedValues[locale.languageCode]?['tags'] ?? 'Tags';
  String get status => _localizedValues[locale.languageCode]?['status'] ?? 'Status';
  String get startDate => _localizedValues[locale.languageCode]?['startDate'] ?? 'Start Date';
  String get endDate => _localizedValues[locale.languageCode]?['endDate'] ?? 'End Date';
  String get customFields => _localizedValues[locale.languageCode]?['customFields'] ?? 'Custom Fields';
  String get notes => _localizedValues[locale.languageCode]?['notes'] ?? 'Notes';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get addChildNode => _localizedValues[locale.languageCode]?['addChildNode'] ?? 'Add Child Node';
  String get addSiblingNode => _localizedValues[locale.languageCode]?['addSiblingNode'] ?? 'Add Sibling Node';
  String get todo => _localizedValues[locale.languageCode]?['todo'] ?? 'To Do';
  String get doing => _localizedValues[locale.languageCode]?['doing'] ?? 'Doing';
  String get done => _localizedValues[locale.languageCode]?['done'] ?? 'Done';
  String get key => _localizedValues[locale.languageCode]?['key'] ?? 'Key';
  String get value => _localizedValues[locale.languageCode]?['value'] ?? 'Value';
  String get addCustomField => _localizedValues[locale.languageCode]?['addCustomField'] ?? 'Add Custom Field';
}