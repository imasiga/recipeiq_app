import 'package:flutter/material.dart';

class ChefOption {
  final String id;           // must match backend values e.g. "chef_japanese_female"
  final String name;         // what user sees
  final String cuisine;      // for display/grouping
  final String description;  // short pitch
  final IconData icon;       // simple placeholder icon for now

  const ChefOption({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.description,
    required this.icon,
  });
}

class ChefCatalog {
  static const List<ChefOption> all = [
    ChefOption(
      id: 'chef_italian_male',
      name: 'Chef Marco',
      cuisine: 'Italian',
      description: 'Classic trattoria style: hearty, simple, flavorful.',
      icon: Icons.local_pizza,
    ),
    ChefOption(
      id: 'chef_italian_female',
      name: 'Chef Sofia',
      cuisine: 'Italian',
      description: 'Warm home-style Italian comfort food.',
      icon: Icons.local_pizza,
    ),
    ChefOption(
      id: 'chef_japanese_male',
      name: 'Chef Kenji',
      cuisine: 'Japanese',
      description: 'Clean, balanced flavors with beautiful simplicity.',
      icon: Icons.ramen_dining,
    ),
    ChefOption(
      id: 'chef_japanese_female',
      name: 'Chef Aiko',
      cuisine: 'Japanese',
      description: 'Comforting Japanese home cooking.',
      icon: Icons.ramen_dining,
    ),
    ChefOption(
      id: 'chef_indian_male',
      name: 'Chef Arjun',
      cuisine: 'Indian',
      description: 'Bold spices, layered flavor, authentic profiles.',
      icon: Icons.restaurant,
    ),
    ChefOption(
      id: 'chef_indian_female',
      name: 'Chef Priya',
      cuisine: 'Indian',
      description: 'Balanced, comforting Indian meals.',
      icon: Icons.restaurant,
    ),
    ChefOption(
      id: 'chef_mexican_male',
      name: 'Chef Diego',
      cuisine: 'Mexican',
      description: 'Bright, bold, fresh salsas and vibrant flavors.',
      icon: Icons.local_dining,
    ),
    ChefOption(
      id: 'chef_mexican_female',
      name: 'Chef Luna',
      cuisine: 'Mexican',
      description: 'Cozy Mexican comfort food.',
      icon: Icons.local_dining,
    ),
    ChefOption(
      id: 'chef_mediterranean_female',
      name: 'Chef Maya',
      cuisine: 'Mediterranean',
      description: 'Olive oil, herbs, fresh vegetables, lighter meals.',
      icon: Icons.emoji_food_beverage,
    ),
    ChefOption(
      id: 'chef_french_male',
      name: 'Chef Pierre',
      cuisine: 'French',
      description: 'Classic techniques, sauces, and structured cooking.',
      icon: Icons.wine_bar,
    ),
    ChefOption(
      id: 'chef_chinese_female',
      name: 'Chef Lin',
      cuisine: 'Chinese',
      description: 'Umami-forward, balanced sauces, wok-friendly.',
      icon: Icons.set_meal,
    ),
  ];

  static ChefOption? byId(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}// dev branch checkpoint
