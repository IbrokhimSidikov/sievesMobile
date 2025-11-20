# Localization Usage Guide

## Overview
The app now has a fully functional localization system that supports **English (en)**, **Uzbek (uz)**, and **Russian (ru)** languages.

## Architecture

### 1. Core Components

#### `AppLocalizations` (`lib/core/l10n/app_localizations.dart`)
- Contains all translation strings
- Provides `translate(key)` method and convenience getters
- Stores translations in a Map structure

#### `AppLocalizationsDelegate` (`lib/core/l10n/app_localizations_delegate.dart`)
- Handles loading of localizations
- Defines supported locales

#### `LocaleProvider` (`lib/core/providers/locale_provider.dart`)
- Manages current locale state
- Persists language selection using SharedPreferences
- Notifies listeners when locale changes

### 2. Integration in `main.dart`

The localization is integrated with:
- **MultiProvider** wrapping the app with LocaleProvider
- **Consumer<LocaleProvider>** to rebuild when locale changes
- **localizationsDelegates** for Material, Widgets, and Cupertino localizations
- **supportedLocales** defining available languages
- **locale** property bound to LocaleProvider's current locale

## How to Use Localization

### Method 1: Using AppLocalizations (Recommended)

```dart
import 'package:sieves_mob/core/l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Text(l10n.welcome); // Uses convenience getter
    // or
    return Text(l10n.translate('welcome')); // Uses translate method
  }
}
```

### Method 2: Changing Language

```dart
import 'package:provider/provider.dart';
import 'package:sieves_mob/core/providers/locale_provider.dart';

// In your widget
final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

// Change to Uzbek
await localeProvider.setLocale(const Locale('uz'));

// Change to Russian
await localeProvider.setLocale(const Locale('ru'));

// Change to English
await localeProvider.setLocale(const Locale('en'));
```

### Method 3: Using the LanguageSwitcher Widget

The app includes a pre-built `LanguageSwitcher` widget that you can use anywhere:

```dart
import 'package:sieves_mob/core/widgets/language_switcher.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Your other widgets
        const LanguageSwitcher(),
      ],
    );
  }
}
```

**The LanguageSwitcher is already added to the Profile page!**

## Adding New Translations

### Step 1: Add translation keys to `AppLocalizations`

```dart
static final Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'title': 'Sieves',
    'welcome': 'Welcome',
    'new_key': 'New Translation', // Add here
  },
  'uz': {
    'title': 'Sieves',
    'welcome': 'Xush kelibsiz',
    'new_key': 'Yangi Tarjima', // Add here
  },
  'ru': {
    'title': 'Sieves',
    'welcome': 'Добро пожаловать',
    'new_key': 'Новый Перевод', // Add here
  },
};
```

### Step 2: Add convenience getter (optional but recommended)

```dart
String get newKey => translate('new_key');
```

### Step 3: Use in your widget

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.newKey)
```

## Available Translation Keys

Current available translations:

| Key | English | Uzbek | Russian |
|-----|---------|-------|---------|
| `title` | Sieves | Sieves | Sieves |
| `welcome` | Welcome | Xush kelibsiz | Добро пожаловать |
| `login` | Login | Kirish | Войти |
| `logout` | Logout | Chiqish | Выйти |
| `profile` | Profile | Profil | Профиль |
| `settings` | Settings | Sozlamalar | Настройки |
| `language` | Language | Til | Язык |
| `theme` | Theme | Mavzu | Тема |
| `dark_mode` | Dark Mode | Qorong'i rejim | Темный режим |
| `light_mode` | Light Mode | Yorug' rejim | Светлый режим |

## Testing

1. **Run the app**: `flutter run`
2. **Navigate to Profile page**
3. **Scroll down to find the Language Switcher**
4. **Tap on different language options** (English, O'zbek, Русский)
5. **The app will immediately switch languages**
6. **The selection is persisted** - close and reopen the app to verify

## Features

✅ **Persistent Language Selection** - Language choice is saved using SharedPreferences
✅ **Instant Updates** - UI updates immediately when language changes
✅ **Beautiful UI** - Elegant language switcher with flags and gradients
✅ **Type-Safe** - Convenience getters provide autocomplete and type safety
✅ **Extensible** - Easy to add new languages and translations
✅ **Material Localizations** - Includes Material, Widgets, and Cupertino localizations

## Next Steps

To fully localize your app:

1. **Identify all hardcoded strings** in your widgets
2. **Add them to `_localizedValues` map** in all three languages
3. **Create convenience getters** for frequently used strings
4. **Replace hardcoded strings** with `AppLocalizations.of(context).yourKey`
5. **Test each screen** in all three languages

## Example: Localizing a Complete Widget

Before:
```dart
Text('Welcome to Sieves')
```

After:
```dart
final l10n = AppLocalizations.of(context);
Text(l10n.welcome)
```

## Tips

- Use descriptive key names (e.g., `profile_title`, `error_network`)
- Group related translations (e.g., `error_*`, `button_*`)
- Keep translations concise for UI elements
- Test with longer translations (Russian/German) to ensure UI doesn't break
- Use `translate('key')` for dynamic keys, getters for static ones
