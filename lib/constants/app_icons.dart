import 'package:flutter/material.dart';

/// 应用程序中使用的所有图标常量
class AppIcons {
  // 私有构造函数，防止实例化
  AppIcons._();

  // 通用图标
  static const IconData defaultIcon = Icons.extension;
  static const IconData settings = Icons.settings;
  static const IconData folder = Icons.folder;
  static const IconData note = Icons.note;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData add = Icons.add;
  static const IconData search = Icons.search;
  static const IconData close = Icons.close;
  static const IconData check = Icons.check;
  static const IconData more = Icons.more_vert;
  static const IconData calendar = Icons.calendar_today;

  // 功能特定图标
  static const IconData chat = Icons.chat;
  static const IconData message = Icons.message;
  static const IconData person = Icons.person;
  static const IconData group = Icons.group;
  static const IconData star = Icons.star;
  static const IconData favorite = Icons.favorite;
  static const IconData home = Icons.home;
  static const IconData work = Icons.work;
  static const IconData school = Icons.school;
  static const IconData event = Icons.event;
  static const IconData notifications = Icons.notifications;
  static const IconData people = Icons.people;
  static const IconData sports = Icons.sports;
  static const IconData musicNote = Icons.music_note;
  static const IconData movie = Icons.movie;
  static const IconData book = Icons.book;
  static const IconData shoppingCart = Icons.shopping_cart;
  static const IconData email = Icons.email;
  static const IconData phone = Icons.phone;
  static const IconData camera = Icons.camera;
  static const IconData photo = Icons.photo;
  static const IconData videoCamera = Icons.video_camera_back;
  static const IconData restaurant = Icons.restaurant;
  static const IconData cafe = Icons.local_cafe;
  static const IconData bar = Icons.local_bar;
  static const IconData hotel = Icons.local_hotel;
  static const IconData flight = Icons.flight;
  static const IconData car = Icons.directions_car;
  static const IconData bike = Icons.directions_bike;
  static const IconData pets = Icons.pets;
  static const IconData nature = Icons.nature;
  static const IconData park = Icons.park;
  static const IconData beach = Icons.beach_access;
  static const IconData snow = Icons.ac_unit;
  static const IconData fire = Icons.whatshot;
  static const IconData games = Icons.sports_esports;
  static const IconData basketball = Icons.sports_basketball;
  static const IconData football = Icons.sports_football;
  static const IconData celebration = Icons.celebration;
  static const IconData cake = Icons.cake;

  // 获取预定义图标映射
  static Map<String, IconData> get predefinedIcons => {
    'default': defaultIcon,
    'settings': settings,
    'folder': folder,
    'note': note,
    'edit': edit,
    'delete': delete,
    'add': add,
    'search': search,
    'close': close,
    'check': check,
    'more': more,
    'calendar': calendar,
    'chat': chat,
    'message': message,
    'person': person,
    'group': group,
    'star': star,
    'favorite': favorite,
    'home': home,
    'work': work,
    'school': school,
    'event': event,
    'notifications': notifications,
    'people': people,
    'sports': sports,
    'music_note': musicNote,
    'movie': movie,
    'book': book,
    'shopping_cart': shoppingCart,
    'email': email,
    'phone': phone,
    'camera': camera,
    'photo': photo,
    'video_camera': videoCamera,
    'restaurant': restaurant,
    'cafe': cafe,
    'bar': bar,
    'hotel': hotel,
    'flight': flight,
    'car': car,
    'bike': bike,
    'pets': pets,
    'nature': nature,
    'park': park,
    'beach': beach,
    'snow': snow,
    'fire': fire,
    'games': games,
    'basketball': basketball,
    'football': football,
    'celebration': celebration,
    'cake': cake,
  };

  /// 根据名称获取图标，如果不存在返回默认图标
  static IconData getIconByName(String name) {
    return predefinedIcons[name] ?? defaultIcon;
  }
}