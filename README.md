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

##  Screenshots
<img width="959" height="207" alt="Screenshot_206" src="https://github.com/user-attachments/assets/fe5559c8-d318-4ded-83d6-cc93bbe3c974" />
<img width="952" height="221" alt="Screenshot_207" src="https://github.com/user-attachments/assets/af0a3141-2ee3-4a07-869b-076fa5d9b4c6" />
<img width="955" height="347" alt="Screenshot_208" src="https://github.com/user-attachments/assets/1c1a2b3d-0ac1-442c-8a0a-0e7f3f2932d3" />
<img width="947" height="218" alt="Screenshot_209" src="https://github.com/user-attachments/assets/eb4b92ea-1fc7-4406-80fb-1d9d60783633" />
<img width="319" height="295" alt="Screenshot_210" src="https://github.com/user-attachments/assets/8e027b4e-39cb-4806-aa66-02fcb547c399" />


