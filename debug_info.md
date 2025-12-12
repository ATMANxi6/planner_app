# Planning Canvas Debug Information

## Navigation Structure

Your app has 5 tabs in this order:
1. **Tasks** (index 0) - Opens by default
2. **Canvas** (index 1) - Planning Canvas (NEW)
3. **Schedule** (index 2) - Time blocking
4. **Dashboard** (index 3) - Stats widgets
5. **Settings** (index 4) - Preferences

## When You Open the App:

**Default View**: Tasks tab (the existing task management screen)

**To Access Planning Canvas**:
- Tap the "Canvas" button (second icon from left) in bottom navigation
- It shows a tree icon (🌳)

## Expected Behavior:

### If Canvas is Empty (First Time):
You should see:
- Large hub icon at center
- "Start Planning" heading
- Description text
- Blue "Create First Node" button
- "Quick Start Guide" button below

### If Canvas Has Data:
You should see:
- Hierarchical tree view
- Cards for each planning node
- Floating "+ Add Node" button (bottom right)

## Troubleshooting Steps:

1. **Check which tab you're on**:
   - Look at bottom navigation bar
   - Which icon is highlighted/selected?

2. **If Tasks tab is blank**:
   - This is a DIFFERENT issue (not related to Planning Canvas)
   - The Tasks screen was working before we added Canvas

3. **If Canvas tab is blank**:
   - No error message appears?
   - No empty state message appears?
   - Just white/blank screen?

4. **If entire app is blank**:
   - No navigation bar at bottom?
   - No app bar at top?
   - Just completely blank?

## Quick Test:

Try this sequence:
1. Open app
2. Look at bottom navigation - which tab is selected?
3. Tap each tab one by one
4. Note which tabs work and which are blank

Then report back which specific screen(s) are blank.
