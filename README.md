# NG PROS - Esports Tournament Management Dashboard

A comprehensive, scalable Flutter Web application designed for real-time esports tournament tracking, player analytics, and performance synergy calculation.

## Tech Stack
* **Frontend:** Flutter (Web), Dart
* **Backend / Database:** Firebase Cloud Firestore
* **Architecture:** Modular Component-Based Architecture

##  Key Features
* **Dynamic Data Aggregation:** Automated merging of multi-stage tournament statistics (Group Stages, Finals, Knockouts) using Custom Regex filtering.
* **Squad Synergy Engine:** Custom mathematical algorithm to calculate team synergy based on kill distribution and standard deviation.
* **Modular Dashboard:** Centralized view for official BR/CS tournaments and 3rd-party matches.
* **Player Analytics:** Deep-dive comparison tools, K/D ratio tracking, and performance streak calculations.
* **Admin Control Panel:** Secured portal for match data entry, tournament creation, and base-stat overrides.

## Architecture Refactoring
This project was transitioned from a monolithic structure (single `main.dart` of 4000+ lines) into a highly maintainable modular architecture:
* `/core` - Theme and centralized configurations
* `/widgets` - Reusable UI components
* `/screens` - Feature-specific decoupled screens
* `/utils` - Common helper functions and string parsers

## 📸 Screenshots
*(Add 2-3 links of your dashboard screenshots here)*