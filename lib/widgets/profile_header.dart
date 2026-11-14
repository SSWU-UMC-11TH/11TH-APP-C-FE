import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String bio;

  const ProfileHeader({super.key, required this.name, required this.bio});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 48,
          child: Icon(Icons.person, size: 48),
        ),
        const SizedBox(height: 12),
        Text(name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          bio,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          child: const Text('프로필 수정'),
        ),
      ],
    );
  }
}