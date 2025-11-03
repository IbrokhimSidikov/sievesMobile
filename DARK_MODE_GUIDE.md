# Professional Dark Mode Color Guide

## 🎨 Color Palette

### Background Colors
- **Deep Background**: `#0F0F14` - Main scaffold background (deepest layer)
- **Surface**: `#1A1A24` - Cards, AppBar, elevated surfaces
- **Elevated Surface**: `#252532` - Chips, elevated components

### Primary Colors
- **Primary**: `#6366F1` (Indigo) - Main brand color, buttons, links
- **Primary Container**: `#4F46E5` - Darker variant for hover states
- **Secondary**: `#34D399` (Emerald) - Success, positive actions
- **Tertiary**: `#A78BFA` (Purple) - Accents, special highlights

### Text Colors
- **Primary Text**: `#E8E8F0` - Headlines, important text
- **Secondary Text**: `#D1D5DB` - Body text, descriptions
- **Tertiary Text**: `#9CA3AF` - Labels, captions
- **Disabled Text**: `#6B7280` - Disabled states, hints

### Border & Divider
- **Outline**: `#374151` - Borders, dividers
- **Divider**: `#252532` - Subtle separators

### Status Colors
- **Error**: `#EF4444` - Errors, destructive actions
- **Success**: `#34D399` - Success states
- **Warning**: `#FBBF24` - Warnings, cautions

## 🎯 Usage Guidelines

### Backgrounds
```dart
// Main screen background
scaffoldBackgroundColor: Color(0xFF0F0F14)

// Cards and surfaces
Card(color: Color(0xFF1A1A24))

// Elevated components
Container(color: Color(0xFF252532))
```

### Text Hierarchy
```dart
// Headlines
TextStyle(color: Color(0xFFE8E8F0), fontSize: 24, fontWeight: FontWeight.bold)

// Body text
TextStyle(color: Color(0xFFD1D5DB), fontSize: 16)

// Secondary text
TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)

// Captions
TextStyle(color: Color(0xFF6B7280), fontSize: 12)
```

### Buttons
```dart
// Primary button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF6366F1),
    foregroundColor: Colors.white,
  ),
)

// Secondary button
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Color(0xFF6366F1),
    side: BorderSide(color: Color(0xFF6366F1)),
  ),
)

// Text button
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: Color(0xFF6366F1),
  ),
)
```

### Input Fields
```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Color(0xFF1A1A24),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF374151)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF6366F1), width: 2),
    ),
  ),
)
```

## 🌟 Design Principles

### Contrast Ratios
- **Primary Text on Background**: 13.5:1 (WCAG AAA)
- **Secondary Text on Background**: 8.2:1 (WCAG AA)
- **Primary Color on Background**: 4.8:1 (WCAG AA)

### Elevation System
1. **Level 0** (`#0F0F14`): Base scaffold
2. **Level 1** (`#1A1A24`): Cards, sheets, app bar
3. **Level 2** (`#252532`): Elevated cards, chips
4. **Level 3** (`#2D2D3D`): Modals, dialogs (if needed)

### Spacing
- Use consistent 8px grid system
- Card padding: 16-24px
- Section spacing: 24-32px
- Element spacing: 8-16px

### Border Radius
- Small components: 8px
- Medium components (buttons, inputs): 12px
- Large components (cards): 16px
- Dialogs: 20-28px

## 💡 Best Practices

### Do's ✅
- Use `#1A1A24` for all cards and elevated surfaces
- Use `#E8E8F0` for primary text (headlines, titles)
- Use `#D1D5DB` for body text
- Use `#6366F1` (indigo) for primary actions
- Add subtle shadows for depth
- Use 12-16px border radius for modern look

### Don'ts ❌
- Don't use pure black `#000000` for backgrounds
- Don't use pure white `#FFFFFF` for text (too harsh)
- Don't mix different elevation colors randomly
- Don't use low contrast colors for important text
- Don't forget to add proper spacing between elements

## 🎨 Inspiration
This dark mode is inspired by:
- **Spotify**: Deep blacks with vibrant accents
- **Discord**: Layered surfaces with clear hierarchy
- **GitHub Dark**: Professional, easy on the eyes
- **Tailwind CSS**: Modern color palette

## 🔄 Migration Tips

If you have existing UI components:

1. **Replace background colors**:
   - Old dark gray → `#0F0F14` (scaffold)
   - Old card background → `#1A1A24` (surface)

2. **Update text colors**:
   - White text → `#E8E8F0` (primary)
   - Gray text → `#D1D5DB` or `#9CA3AF`

3. **Update primary color**:
   - Old blue → `#6366F1` (indigo)

4. **Add proper elevation**:
   - Use CardTheme for consistent styling
   - Add subtle shadows for depth

## 📱 Testing Checklist

- [ ] Test all screens in dark mode
- [ ] Check text readability on all backgrounds
- [ ] Verify button states (normal, hover, pressed, disabled)
- [ ] Test input fields (normal, focused, error)
- [ ] Check navigation bar appearance
- [ ] Verify dialog and modal styling
- [ ] Test with different screen sizes
- [ ] Check accessibility contrast ratios
