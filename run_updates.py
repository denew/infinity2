import os
import re

base_dir = '/Users/denew/Documents/dev/projects/infinity'

# 1. Rename files and directory references
def replace_in_file(fp, old, new, is_regex=False):
    if not os.path.exists(fp): return
    with open(fp, 'r') as f:
        content = f.read()
    if is_regex:
        content = re.sub(old, new, content)
    else:
        content = content.replace(old, new)
    with open(fp, 'w') as f:
        f.write(content)

ios_plist = os.path.join(base_dir, 'ios/Runner/Info.plist')
replace_in_file(ios_plist, '<string>infinity</string>', '<string>indefinitely</string>')
replace_in_file(ios_plist, '<string>Infinity II</string>', '<string>Indefinitely</string>')

android_manifest1 = os.path.join(base_dir, 'android/app/src/main/AndroidManifest.xml')
android_manifest2 = os.path.join(base_dir, 'android/app/src/debug/AndroidManifest.xml')
android_manifest3 = os.path.join(base_dir, 'android/app/src/profile/AndroidManifest.xml')
for f in [android_manifest1, android_manifest2, android_manifest3]:
    replace_in_file(f, 'android:label="infinity"', 'android:label="indefinitely"')
    replace_in_file(f, 'android:label="Infinity II"', 'android:label="Indefinitely"')
    replace_in_file(f, 'android:label="Infinity"', 'android:label="Indefinitely"')
    replace_in_file(f, 'infinity2', 'indefinitely')
    replace_in_file(f, 'infinity', 'indefinitely')

# Rename in pubspec.yaml
pubspec = os.path.join(base_dir, 'pubspec.yaml')
replace_in_file(pubspec, 'name: infinity', 'name: indefinitely')

# Replace in main.dart
main_dart = os.path.join(base_dir, 'lib/main.dart')
replace_in_file(main_dart, "'Infinity II'", "'Indefinitely'")
replace_in_file(main_dart, "InfinityPuzzleApp", "IndefinitelyApp")

lobby = os.path.join(base_dir, 'lib/screens/lobby_screen.dart')
replace_in_file(lobby, "'Infinity II - Lobby'", "'Indefinitely - Lobby'")

puzzle_screen = os.path.join(base_dir, 'lib/screens/puzzle_screen.dart')
replace_in_file(puzzle_screen, "'Infinity II'", "'Indefinitely'")

# i18n for COLOUR, PATTERNS, NUMBERS
replace_in_file(puzzle_screen, "value.toString().split('.').last.toUpperCase()", "AppStrings.getDisplayMode(value)")

# Hint counter inside puzzle_screen
# Track hintCount in GameEngine -> GameEngine doesn't have it, let's just inject hintCount to PuzzleScreen state for now.
# Replace padding Moves
replace_in_file(puzzle_screen, 
    "engine.moveCount}", 
    "engine.moveCount}, Hints: ${_isHexMode ? (hexEngine?.hintCount ?? 0) : engine.hintCount}")
replace_in_file(puzzle_screen, 
    "hexEngine?.moveCount ?? 0)", 
    "(hexEngine?.moveCount ?? 0)}, Hints: ${_isHexMode ? (hexEngine?.hintCount ?? 0) : engine.hintCount}")
    
# Padlock icon
replace_in_file(puzzle_screen, "Icons.lock", "_isUnlocked ? Icons.save : Icons.lock")

# Update strings
strings_dart = os.path.join(base_dir, 'lib/strings.dart')
with open(strings_dart, 'a') as f:
    f.write("\n  static String getDisplayMode(DisplayMode mode) { switch (mode) { case DisplayMode.colours: return 'COLOR'; case DisplayMode.patterns: return 'PATTERNS'; case DisplayMode.numbers: return 'NUMBERS'; } }\n")

print("Done")
